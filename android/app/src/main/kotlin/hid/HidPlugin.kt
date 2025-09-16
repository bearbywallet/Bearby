package hid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.*
import kotlin.collections.HashMap
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class HidPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private lateinit var usbManager: UsbManager

    private val hidDevices = HashMap<String, HidDevice>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        private const val TAG = "HidPlugin"
        private const val CHANNEL_NAME = "ledger.com/hid"
        private const val EVENT_CHANNEL_NAME = "ledger.com/hid/events"
        private const val ACTION_USB_PERMISSION = "com.yourcompany.hid.USB_PERMISSION"
        private const val LEDGER_USB_VENDOR_ID = 0x2c97
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine")
        context = flutterPluginBinding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)

        registerDeviceConnectionReceiver()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine")
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "EventChannel: onListen")
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "EventChannel: onCancel")
        this.eventSink = null
    }

    private fun registerDeviceConnectionReceiver() {
        Log.d(TAG, "Registering device connection receiver")
        val filter = IntentFilter()
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val action = intent.action
                Log.d(TAG, "ConnectionReceiver: Received action: $action")
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE) ?: return
                if (device.vendorId != LEDGER_USB_VENDOR_ID) return

                val eventType = if (action == UsbManager.ACTION_USB_DEVICE_ATTACHED) "add" else "remove"
                Log.d(TAG, "ConnectionReceiver: Device event: $eventType for ${device.deviceName}")

                val deviceMap = buildMapFromDevice(device)
                val event = mapOf("type" to eventType, "descriptor" to deviceMap)
                eventSink?.success(event)
            }
        }
        context.registerReceiver(receiver, filter)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall: ${call.method}")
        scope.launch {
            try {
                when (call.method) {
                    "getDeviceList" -> {
                        val deviceList = getDeviceList()
                        withContext(Dispatchers.Main) { result.success(deviceList) }
                    }
                    "openDevice" -> {
                        val deviceMap = call.arguments as? Map<String, Any>
                        if (deviceMap != null) {
                            val hid = openDevice(deviceMap)
                            withContext(Dispatchers.Main) { result.success(hid) }
                        } else {
                            withContext(Dispatchers.Main) {
                                result.error("INVALID_ARGUMENT", "Device map is null", null)
                            }
                        }
                    }
                    "exchange" -> {
                        val deviceId = call.argument<String>("deviceId")
                        val apduHex = call.argument<String>("apduHex")
                        if (deviceId != null && apduHex != null) {
                            val response = exchange(deviceId, apduHex)
                            withContext(Dispatchers.Main) { result.success(response) }
                        } else {
                            withContext(Dispatchers.Main) {
                                result.error("INVALID_ARGUMENT", "deviceId or apduHex is null", null)
                            }
                        }
                    }
                    "closeDevice" -> {
                        val deviceId = call.argument<String>("deviceId")
                        if (deviceId != null) {
                            closeDevice(deviceId)
                            withContext(Dispatchers.Main) { result.success(null) }
                        } else {
                            withContext(Dispatchers.Main) {
                                result.error("INVALID_ARGUMENT", "deviceId is null", null)
                            }
                        }
                    }
                    else -> withContext(Dispatchers.Main) { result.notImplemented() }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    val errorCode = when (e) {
                        is TimeoutCancellationException -> "TIMEOUT_ERROR"
                        is DisconnectedDeviceException -> "DISCONNECTED"
                        else -> e.javaClass.simpleName
                    }
                    Log.e(TAG, "Error in onMethodCall for ${call.method}. Code: $errorCode", e)
                    result.error(errorCode, e.message, null)
                }
            }
        }
    }

    private fun getDeviceList(): List<Map<String, Any>> {
        Log.d(TAG, "Executing getDeviceList")
        val deviceList = usbManager.deviceList.values
            .filter { it.vendorId == LEDGER_USB_VENDOR_ID }
            .map { buildMapFromDevice(it) }
        Log.d(TAG, "Found ${deviceList.size} Ledger devices.")
        return deviceList
    }

    private suspend fun openDevice(deviceMap: Map<String, Any>): Map<String, Any> {
        Log.d(TAG, "Executing openDevice with timeout")
        return withTimeout(5000L) {
            val vendorId = deviceMap["vendorId"] as? Int ?: throw IllegalArgumentException("Missing vendorId")
            val productId = deviceMap["productId"] as? Int ?: throw IllegalArgumentException("Missing productId")
            Log.d(TAG, "Searching for device with vendorId=$vendorId, productId=$productId")

            val device = usbManager.deviceList.values.find { it.vendorId == vendorId && it.productId == productId }
                ?: throw DisconnectedDeviceException("Device not found")
            Log.d(TAG, "Device found: ${device.deviceName}")

            if (usbManager.hasPermission(device)) {
                Log.d(TAG, "Permission already granted for ${device.deviceName}")
                return@withTimeout createHIDDevice(device)
            }
            Log.d(TAG, "Permission not granted, requesting for ${device.deviceName}")

            suspendCancellableCoroutine { continuation ->
                val filter = IntentFilter(ACTION_USB_PERMISSION)

                val usbReceiver = object : BroadcastReceiver() {
                    override fun onReceive(context: Context, intent: Intent) {
                        Log.d(TAG, "PermissionReceiver: Received action: ${intent.action}")
                        context.unregisterReceiver(this)
                        if (ACTION_USB_PERMISSION == intent.action) {
                            synchronized(this) {
                                val permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                                if (permissionGranted) {
                                    Log.d(TAG, "PermissionReceiver: Permission GRANTED by user")
                                    try {
                                        val hid = createHIDDevice(device)
                                        if (continuation.isActive) continuation.resume(hid)
                                    } catch (e: Exception) {
                                        if (continuation.isActive) continuation.resumeWithException(e)
                                    }
                                } else {
                                    Log.w(TAG, "PermissionReceiver: Permission DENIED by user")
                                    if (continuation.isActive) continuation.resumeWithException(Exception("Permission denied by user for device"))
                                }
                            }
                        }
                    }
                }

                continuation.invokeOnCancellation {
                    Log.d(TAG, "openDevice coroutine was cancelled (e.g., timeout)")
                    try {
                        context.unregisterReceiver(usbReceiver)
                        Log.d(TAG, "PermissionReceiver unregistered due to cancellation.")
                    } catch (e: IllegalArgumentException) {
                        Log.w(TAG, "PermissionReceiver was already unregistered.")
                    }
                }

                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val permIntent = PendingIntent.getBroadcast(context, 0, Intent(ACTION_USB_PERMISSION), flags)

                ContextCompat.registerReceiver(context, usbReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
                Log.d(TAG, "Requesting permission from UsbManager and waiting for user action...")
                usbManager.requestPermission(device, permIntent)
            }
        }
    }

    private fun exchange(deviceId: String, apduHex: String): ByteArray {
        Log.d(TAG, "Executing exchange for deviceId: $deviceId")
        val hid = hidDevices[deviceId] ?: throw DisconnectedDeviceException("No device opened for the id '$deviceId'")
        val apdu = hexToBin(apduHex)
        Log.d(TAG, "=> APDU: $apduHex")
        val response = hid.exchange(apdu)
        val responseHex = binToHex(response)
        Log.d(TAG, "<= Response: $responseHex")
        return response
    }

    private fun closeDevice(deviceId: String) {
        Log.d(TAG, "Executing closeDevice for deviceId: $deviceId")
        val hid = hidDevices.remove(deviceId) ?: throw DisconnectedDeviceException("No device opened for the id '$deviceId'")
        hid.close()
        Log.d(TAG, "Device $deviceId closed and removed.")
    }

    private fun createHIDDevice(device: UsbDevice): Map<String, Any> {
        Log.d(TAG, "Creating HIDDevice instance for ${device.deviceName}")
        val hid = HidDevice(usbManager, device)
        val id = UUID.randomUUID().toString()
        hidDevices[id] = hid
        Log.d(TAG, "HIDDevice created with id: $id")
        return mapOf("id" to id)
    }

    private fun buildMapFromDevice(device: UsbDevice): Map<String, Any> {
        val deviceModel = Devices.identifyUSBProductId(device.productId)
        return mapOf(
            "name" to (device.productName ?: ""),
            "deviceId" to device.deviceId,
            "productId" to device.productId,
            "vendorId" to device.vendorId,
            "deviceName" to device.deviceName,
            "deviceModel" to (deviceModel?.let { mapOf("id" to it.id, "productName" to it.productName) } ?: emptyMap())
        )
    }

    private fun hexToBin(hex: String): ByteArray {
        return hex.chunked(2)
            .map { it.toInt(16).toByte() }
            .toByteArray()
    }

    private fun binToHex(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
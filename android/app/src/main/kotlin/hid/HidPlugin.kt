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
        private const val ACTION_USB_PERMISSION = "com.zilpaymobile.hid.USB_PERMISSION"
        private const val LEDGER_USB_VENDOR_ID = 0x2c97
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)

        registerDeviceConnectionReceiver()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    private fun registerDeviceConnectionReceiver() {
        val filter = IntentFilter()
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val action = intent.action
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE) ?: return
                if (device.vendorId != LEDGER_USB_VENDOR_ID) return

                val eventType = if (action == UsbManager.ACTION_USB_DEVICE_ATTACHED) "add" else "remove"
                val deviceMap = buildMapFromDevice(device)
                val event = mapOf("type" to eventType, "descriptor" to deviceMap)
                eventSink?.success(event)
            }
        }
        context.registerReceiver(receiver, filter)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
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
        return usbManager.deviceList.values
            .filter { it.vendorId == LEDGER_USB_VENDOR_ID }
            .map { buildMapFromDevice(it) }
    }

    private suspend fun openDevice(deviceMap: Map<String, Any>): Map<String, Any> {
        val vendorId = deviceMap["vendorId"] as? Int ?: throw IllegalArgumentException("Missing vendorId")
        val productId = deviceMap["productId"] as? Int ?: throw IllegalArgumentException("Missing productId")

        val device = usbManager.deviceList.values.find { it.vendorId == vendorId && it.productId == productId }
            ?: throw DisconnectedDeviceException("Device not found")

        if (usbManager.hasPermission(device)) {
            return createHIDDevice(device)
        }

        return suspendCancellableCoroutine { continuation ->
            val filter = IntentFilter(ACTION_USB_PERMISSION)
            val usbReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    context.unregisterReceiver(this)
                    if (ACTION_USB_PERMISSION == intent.action) {
                        synchronized(this) {
                            val permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                            if (permissionGranted) {
                                try {
                                    val hid = createHIDDevice(device)
                                    if (continuation.isActive) continuation.resume(hid)
                                } catch (e: Exception) {
                                    if (continuation.isActive) continuation.resumeWithException(e)
                                }
                            } else {
                                if (continuation.isActive) continuation.resumeWithException(Exception("Permission denied by user for device"))
                            }
                        }
                    }
                }
            }

            continuation.invokeOnCancellation {
                try {
                    context.unregisterReceiver(usbReceiver)
                } catch (e: IllegalArgumentException) {
                    // Receiver was already unregistered.
                }
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val permIntent = PendingIntent.getBroadcast(context, 0, Intent(ACTION_USB_PERMISSION), flags)

            ContextCompat.registerReceiver(context, usbReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
            usbManager.requestPermission(device, permIntent)
        }
    }

    private fun exchange(deviceId: String, apduHex: String): ByteArray {
        val hid = hidDevices[deviceId] ?: throw DisconnectedDeviceException("No device opened for the id '$deviceId'")
        val apdu = hexToBin(apduHex)
        return hid.exchange(apdu)
    }

    private fun closeDevice(deviceId: String) {
        val hid = hidDevices.remove(deviceId) ?: throw DisconnectedDeviceException("No device opened for the id '$deviceId'")
        hid.close()
    }

    private fun createHIDDevice(device: UsbDevice): Map<String, Any> {
        val hid = HidDevice(usbManager, device)
        val id = UUID.randomUUID().toString()
        hidDevices[id] = hid
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
}
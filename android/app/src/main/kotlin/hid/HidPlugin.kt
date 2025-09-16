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
import java.util.*
import kotlin.collections.HashMap

class HidPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private lateinit var usbManager: UsbManager

    private val hidDevices = HashMap<String, HidDevice>()
    private var permissionPromise: MethodChannel.Result? = null

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
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "onListen")
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "onCancel")
        this.eventSink = null
    }

    private fun registerDeviceConnectionReceiver() {
        Log.d(TAG, "registerDeviceConnectionReceiver")
        val filter = IntentFilter()
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val action = intent.action
                Log.d(TAG, "BroadcastReceiver onReceive: $action")
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE) ?: return
                if (device.vendorId != LEDGER_USB_VENDOR_ID) {
                    Log.d(TAG, "Ignoring non-Ledger device: vendorId=${device.vendorId}")
                    return
                }

                val eventType = if (action == UsbManager.ACTION_USB_DEVICE_ATTACHED) "add" else "remove"
                Log.d(TAG, "Device event: $eventType, device: ${device.deviceName}")

                val deviceMap = buildMapFromDevice(device)
                val event = mapOf("type" to eventType, "descriptor" to deviceMap)
                eventSink?.success(event)
            }
        }
        context.registerReceiver(receiver, filter)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall: ${call.method}")
        when (call.method) {
            "getDeviceList" -> getDeviceList(result)
            "openDevice" -> {
                val deviceMap = call.arguments as? Map<String, Any>
                if (deviceMap != null) {
                    openDevice(deviceMap, result)
                } else {
                    Log.e(TAG, "openDevice error: Invalid argument, device map is null")
                    result.error("INVALID_ARGUMENT", "Device map is null", null)
                }
            }
            "exchange" -> {
                val deviceId = call.argument<String>("deviceId")
                val apduHex = call.argument<String>("apduHex")
                if (deviceId != null && apduHex != null) {
                    exchange(deviceId, apduHex, result)
                } else {
                    Log.e(TAG, "exchange error: Invalid argument, deviceId or apduHex is null")
                    result.error("INVALID_ARGUMENT", "deviceId or apduHex is null", null)
                }
            }
            "closeDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                if (deviceId != null) {
                    closeDevice(deviceId, result)
                } else {
                    Log.e(TAG, "closeDevice error: Invalid argument, deviceId is null")
                    result.error("INVALID_ARGUMENT", "deviceId is null", null)
                }
            }
            else -> {
                Log.w(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun getDeviceList(result: MethodChannel.Result) {
        Log.d(TAG, "getDeviceList")
        val deviceList = usbManager.deviceList.values
            .filter { it.vendorId == LEDGER_USB_VENDOR_ID }
            .map { buildMapFromDevice(it) }
        Log.d(TAG, "Found ${deviceList.size} Ledger devices")
        result.success(deviceList)
    }

    private fun openDevice(deviceMap: Map<String, Any>, result: MethodChannel.Result) {
        val vendorId = deviceMap["vendorId"] as Int
        val productId = deviceMap["productId"] as Int
        Log.d(TAG, "openDevice: vendorId=$vendorId, productId=$productId")

        val device = usbManager.deviceList.values.find { it.vendorId == vendorId && it.productId == productId }

        if (device == null) {
            Log.e(TAG, "openDevice error: Device not found")
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        if (usbManager.hasPermission(device)) {
            Log.d(TAG, "Device already has permission")
            try {
                val hid = createHIDDevice(device)
                result.success(hid)
            } catch (e: Exception) {
                Log.e(TAG, "openDevice error: Failed to create HID device", e)
                result.error("CONNECTION_ERROR", e.message, null)
            }
        } else {
            Log.d(TAG, "Requesting USB permission for device")
            permissionPromise = result
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val permIntent = PendingIntent.getBroadcast(context, 0, Intent(ACTION_USB_PERMISSION), flags)

            val filter = IntentFilter(ACTION_USB_PERMISSION)
            ContextCompat.registerReceiver(
                context,
                usbReceiver,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED
            )

            this.usbManager.requestPermission(device, permIntent)
        }
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d(TAG, "usbReceiver onReceive: ${intent.action}")
            if (ACTION_USB_PERMISSION == intent.action) {
                synchronized(this) {
                    context.unregisterReceiver(this)
                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        Log.d(TAG, "USB permission granted for device")
                        if (device != null) {
                            try {
                                val hid = createHIDDevice(device)
                                permissionPromise?.success(hid)
                            } catch (e: Exception) {
                                Log.e(TAG, "usbReceiver error: Failed to create HID device after permission grant", e)
                                permissionPromise?.error("CONNECTION_ERROR", e.message, null)
                            }
                        } else {
                            Log.e(TAG, "usbReceiver error: Device is null after permission grant")
                            permissionPromise?.error("CONNECTION_ERROR", "Device is null after permission grant", null)
                        }
                    } else {
                        Log.w(TAG, "USB permission denied by user for device")
                        permissionPromise?.error("PERMISSION_DENIED", "Permission denied by user for device", null)
                    }
                    permissionPromise = null
                }
            }
        }
    }

    private fun exchange(deviceId: String, apduHex: String, result: MethodChannel.Result) {
        Log.d(TAG, "exchange: deviceId=$deviceId, apduHex=$apduHex")
        try {
            val hid = hidDevices[deviceId]
            if (hid == null) {
                Log.e(TAG, "exchange error: No device opened for id '$deviceId'")
                result.error("DEVICE_NOT_OPEN", "No device opened for the id '$deviceId'", null)
                return
            }
            val apdu = hexToBin(apduHex)
            val response = hid.exchange(apdu)
            val responseHex = binToHex(response)
            Log.d(TAG, "exchange successful, response: $responseHex")
            result.success(responseHex)
        } catch (e: DisconnectedDeviceException) {
            Log.e(TAG, "exchange error: DisconnectedDeviceException", e)
            result.error("DISCONNECTED", e.message, null)
        } catch (e: Exception) {
            Log.e(TAG, "exchange error: Exception", e)
            result.error("EXCHANGE_ERROR", e.message, null)
        }
    }

    private fun closeDevice(deviceId: String, result: MethodChannel.Result) {
        Log.d(TAG, "closeDevice: deviceId=$deviceId")
        try {
            val hid = hidDevices[deviceId]
            if (hid == null) {
                Log.e(TAG, "closeDevice error: No device opened for id '$deviceId'")
                result.error("DEVICE_NOT_OPEN", "No device opened for the id '$deviceId'", null)
                return
            }
            hid.close()
            hidDevices.remove(deviceId)
            Log.d(TAG, "Device closed and removed")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "closeDevice error: Exception", e)
            result.error("CLOSE_ERROR", e.message, null)
        }
    }

    private fun createHIDDevice(device: UsbDevice): Map<String, Any> {
        Log.d(TAG, "createHIDDevice for ${device.deviceName}")
        val hid = HidDevice(usbManager, device)
        val id = UUID.randomUUID().toString()
        hidDevices[id] = hid
        Log.d(TAG, "HID device created with id: $id")
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
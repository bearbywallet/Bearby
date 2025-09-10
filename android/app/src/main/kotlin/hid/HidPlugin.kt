package hid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
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
        private const val CHANNEL_NAME = "ledger.com/hid"
        private const val EVENT_CHANNEL_NAME = "ledger.com/hid/events"
        private const val ACTION_USB_PERMISSION = "com.yourcompany.hid.USB_PERMISSION"
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
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE) ?: return
                if (device.vendorId != LEDGER_USB_VENDOR_ID) return

                val eventType = if (intent.action == UsbManager.ACTION_USB_DEVICE_ATTACHED) "add" else "remove"

                val deviceMap = buildMapFromDevice(device)
                val event = mapOf("type" to eventType, "descriptor" to deviceMap)
                eventSink?.success(event)
            }
        }
        context.registerReceiver(receiver, filter)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceList" -> getDeviceList(result)
            "openDevice" -> {
                val deviceMap = call.arguments as? Map<String, Any>
                if (deviceMap != null) {
                    openDevice(deviceMap, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Device map is null", null)
                }
            }
            "exchange" -> {
                val deviceId = call.argument<String>("deviceId")
                val apduHex = call.argument<String>("apduHex")
                if (deviceId != null && apduHex != null) {
                    exchange(deviceId, apduHex, result)
                } else {
                    result.error("INVALID_ARGUMENT", "deviceId or apduHex is null", null)
                }
            }
            "closeDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                if (deviceId != null) {
                    closeDevice(deviceId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "deviceId is null", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getDeviceList(result: MethodChannel.Result) {
        val deviceList = usbManager.deviceList.values
            .filter { it.vendorId == LEDGER_USB_VENDOR_ID }
            .map { buildMapFromDevice(it) }
        result.success(deviceList)
    }

    private fun openDevice(deviceMap: Map<String, Any>, result: MethodChannel.Result) {
        val vendorId = deviceMap["vendorId"] as Int
        val productId = deviceMap["productId"] as Int
        val device = usbManager.deviceList.values.find { it.vendorId == vendorId && it.productId == productId }

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        if (usbManager.hasPermission(device)) {
            try {
                val hid = createHIDDevice(device)
                result.success(hid)
            } catch (e: Exception) {
                result.error("CONNECTION_ERROR", e.message, null)
            }
        } else {
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
            if (ACTION_USB_PERMISSION == intent.action) {
                synchronized(this) {
                    context.unregisterReceiver(this)
                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if (device != null) {
                            try {
                                val hid = createHIDDevice(device)
                                permissionPromise?.success(hid)
                            } catch (e: Exception) {
                                permissionPromise?.error("CONNECTION_ERROR", e.message, null)
                            }
                        }
                    } else {
                        permissionPromise?.error("PERMISSION_DENIED", "Permission denied by user for device", null)
                    }
                    permissionPromise = null
                }
            }
        }
    }

    private fun exchange(deviceId: String, apduHex: String, result: MethodChannel.Result) {
        try {
            val hid = hidDevices[deviceId]
            if (hid == null) {
                result.error("DEVICE_NOT_OPEN", "No device opened for the id '$deviceId'", null)
                return
            }
            val apdu = hexToBin(apduHex)
            val response = hid.exchange(apdu)
            result.success(binToHex(response))
        } catch (e: DisconnectedDeviceException) {
            result.error("DISCONNECTED", e.message, null)
        } catch (e: Exception) {
            result.error("EXCHANGE_ERROR", e.message, null)
        }
    }

    private fun closeDevice(deviceId: String, result: MethodChannel.Result) {
        try {
            val hid = hidDevices[deviceId]
            if (hid == null) {
                result.error("DEVICE_NOT_OPEN", "No device opened for the id '$deviceId'", null)
                return
            }
            hid.close()
            hidDevices.remove(deviceId)
            result.success(null)
        } catch (e: Exception) {
            result.error("CLOSE_ERROR", e.message, null)
        }
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

    private fun binToHex(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
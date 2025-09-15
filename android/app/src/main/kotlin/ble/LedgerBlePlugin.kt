package ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collect

class LedgerBlePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private lateinit var bleManager: BleManager
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var scanJob: Job? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        bleManager = BleManager(context)

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ledger.com/ble")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "ledger.com/ble/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                stopScan()
                eventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                val res = handleMethodCall(call)
                withContext(Dispatchers.Main) {
                    result.success(res)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error(e.javaClass.simpleName, e.message, null)
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private suspend fun handleMethodCall(call: MethodCall): Any? {
        return when (call.method) {
            "getConnectedDevices" -> {
                bleManager.getConnectedDevices().map { device ->
                    mapOf(
                        "id" to device.address,
                        "name" to (device.name ?: "Unknown"),
                        "serviceUUID" to ""
                    )
                }
            }
            "startScan" -> {
                startScan()
                null
            }
            "stopScan" -> {
                stopScan()
                null
            }
            "isSupported" -> bleManager.isSupported()
            "openDevice" -> {
                val deviceId = call.arguments as? String ?: throw IllegalArgumentException("Device ID must be a String")
                bleManager.open(deviceId)
                null
            }
            "exchange" -> {
                val args = call.arguments as? Map<String, Any> ?: throw IllegalArgumentException("Arguments must be a Map")
                val deviceId = args["deviceId"] as? String ?: throw IllegalArgumentException("Device ID must be a String")
                val apdu = args["apdu"] as? ByteArray ?: throw IllegalArgumentException("APDU must be a ByteArray")
                bleManager.exchange(deviceId, apdu)
            }
            "closeDevice" -> {
                val args = call.arguments as? Map<String, Any> ?: throw IllegalArgumentException("Arguments must be a Map")
                val deviceId = args["deviceId"] as? String ?: throw IllegalArgumentException("Device ID must be a String")
                bleManager.close(deviceId)
                null
            }
            else -> throw NotImplementedError()
        }
    }

    @SuppressLint("MissingPermission")
    private fun startScan() {
        scanJob?.cancel()
        scanJob = scope.launch {
            try {
                bleManager.listen().collect { scanResult ->
                    val serviceUuid = scanResult.scanRecord?.serviceUuids?.firstOrNull()?.uuid?.toString() ?: ""
                    val deviceName = scanResult.device.name ?: "Unknown"
                    val deviceInfo = mapOf(
                        "id" to scanResult.device.address,
                        "name" to deviceName,
                        "serviceUUID" to serviceUuid
                    )
                    val event = mapOf(
                        "type" to "add",
                        "descriptor" to deviceInfo
                    )
                    withContext(Dispatchers.Main) {
                        eventSink?.success(event)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    eventSink?.error(e.javaClass.simpleName, e.message, null)
                }
            }
        }
    }

    private fun stopScan() {
        scanJob?.cancel()
        scanJob = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
        bleManager.release()
    }
}


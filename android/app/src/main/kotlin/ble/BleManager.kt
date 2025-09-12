package ble

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import java.util.concurrent.ConcurrentHashMap

@SuppressLint("MissingPermission")
class BleManager(private val context: Context) {
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private val bleScanner by lazy { bluetoothAdapter?.bluetoothLeScanner }
    private val transports = ConcurrentHashMap<String, BleTransport>()

    private fun checkPermissions(): Boolean {
        val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            listOf(Manifest.permission.BLUETOOTH, Manifest.permission.ACCESS_FINE_LOCATION)
        }

        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun ensurePermissions() {
        if (!checkPermissions()) {
            throw PermissionException("Bluetooth permissions are not granted.")
        }
    }

    fun getConnectedDevices(): List<BluetoothDevice> {
        ensurePermissions()
        val connectedBleDevices = bluetoothManager.getConnectedDevices(BluetoothProfile.GATT)

        return connectedBleDevices
            .filter { device ->
                device.name?.contains("Ledger", ignoreCase = true) == true
            }
    }

    fun isSupported(): Boolean = bluetoothAdapter != null && context.packageManager
        .hasSystemFeature(android.content.pm.PackageManager.FEATURE_BLUETOOTH_LE)

    fun listen(): Flow<ScanResult> {
        ensurePermissions()
        return callbackFlow {
            val scanCallback = object : ScanCallback() {
                override fun onScanResult(callbackType: Int, result: ScanResult) {
                    super.onScanResult(callbackType, result)
                    trySend(result)
                }

                override fun onScanFailed(errorCode: Int) {
                    super.onScanFailed(errorCode)
                    close(BleScanException("Scan failed with error code $errorCode"))
                }
            }

            val filters = Devices.getBluetoothServiceUuids().map {
                ScanFilter.Builder().setServiceUuid(ParcelUuid(it)).build()
            }
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()

            bleScanner?.startScan(filters, settings, scanCallback)
            awaitClose { bleScanner?.stopScan(scanCallback) }
        }
    }

    fun stopScan() {
    }

    suspend fun open(deviceId: String) {
        ensurePermissions()
        if (transports.containsKey(deviceId)) {
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(deviceId) ?: throw DeviceNotFoundException()
        val transport = BleTransport(context, device)

        try {
            var needsReconnect = false
            val beforeMtuTime = System.currentTimeMillis()
            transport.connect()
            transport.inferMtu()
            val afterMtuTime = System.currentTimeMillis()

            val deviceModel = Devices.getInfosForServiceUuid(transport.serviceUuid.toString())?.deviceModel
            if (deviceModel?.id != "stax" && afterMtuTime - beforeMtuTime > 1000) {
                needsReconnect = true
            }

            if (needsReconnect) {
                transport.close()
                delay(4000)
                transport.connect()
                transport.inferMtu()
            }

            transports[deviceId] = transport
        } catch (e: Exception) {
            transport.close()
            throw e
        }
    }

    suspend fun exchange(deviceId: String, apdu: ByteArray): ByteArray {
        val transport = transports[deviceId] ?: throw DeviceNotConnectedException()
        return transport.exchange(apdu)
    }

    fun close(deviceId: String) {
        transports.remove(deviceId)?.close()
    }

    fun release() {
        transports.values.forEach { it.close() }
        transports.clear()
    }
}


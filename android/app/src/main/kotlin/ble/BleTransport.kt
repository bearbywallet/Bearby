package ble

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import android.os.Build
import android.util.Log
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

@SuppressLint("MissingPermission")
class BleTransport(private val context: Context, private val device: BluetoothDevice) {
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private var gatt: BluetoothGatt? = null
    private var writeCharacteristic: BluetoothGattCharacteristic? = null
    private var notifyCharacteristic: BluetoothGattCharacteristic? = null
    var serviceUuid: UUID? = null

    private val notificationFlow = MutableSharedFlow<ByteArray>(replay = 0, extraBufferCapacity = 10)
    private var mtuSize = 20

    private var connectContinuation: CancellableContinuation<Unit>? = null
    private var writeContinuation: CancellableContinuation<Unit>? = null

    private val connectionMutex = Mutex()
    private val writeMutex = Mutex()

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.e("BleTransport", "onConnectionStateChange error: $status")
                val cont = connectContinuation
                connectContinuation = null
                cont?.resumeWithException(DeviceNotConnectedException("GATT connection failed with status $status"))
                close()
                return
            }

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.d("BleTransport", "Device connected, discovering services...")
                gatt.discoverServices()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.d("BleTransport", "Device disconnected.")
                val cont = connectContinuation
                connectContinuation = null
                cont?.resumeWithException(DeviceNotConnectedException("Device disconnected"))
                writeContinuation?.resumeWithException(DeviceNotConnectedException("Device disconnected during write"))
                writeContinuation = null
                close()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.e("BleTransport", "onServicesDiscovered error: $status")
                val cont = connectContinuation
                connectContinuation = null
                cont?.resumeWithException(DeviceNotConnectedException("Service discovery failed with status $status"))
                return
            }

            Log.d("BleTransport", "Services discovered.")
            val infos = Devices.getInfosForServiceUuid(
                gatt.services.firstOrNull { Devices.isLedgerService(it.uuid) }?.uuid.toString()
            ) ?: run {
                Log.e("BleTransport", "Ledger service not found.")
                val cont = connectContinuation
                connectContinuation = null
                cont?.resumeWithException(DeviceNotConnectedException("Ledger service not found"))
                return
            }

            val service = gatt.getService(infos.serviceUuid)
            serviceUuid = service?.uuid
            writeCharacteristic = service?.getCharacteristic(infos.writeUuid)
            notifyCharacteristic = service?.getCharacteristic(infos.notifyUuid)

            if (writeCharacteristic == null || notifyCharacteristic == null) {
                Log.e("BleTransport", "Write or Notify characteristic not found.")
                val cont = connectContinuation
                connectContinuation = null
                cont?.resumeWithException(CharacteristicNotFoundException("Write or Notify"))
                return
            }

            setNotification(gatt, notifyCharacteristic, true)
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            if (descriptor.uuid.toString().equals("00002902-0000-1000-8000-00805f9b34fb", ignoreCase = true)) {
                val cont = connectContinuation
                connectContinuation = null
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    Log.d("BleTransport", "Notification enabled. Connection successful.")
                    cont?.resume(Unit)
                } else {
                    Log.e("BleTransport", "onDescriptorWrite error: $status")
                    cont?.resumeWithException(DeviceNotConnectedException("Failed to enable notifications, status: $status"))
                }
            }
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            val cont = writeContinuation
            writeContinuation = null
            if (status == BluetoothGatt.GATT_SUCCESS) {
                cont?.resume(Unit)
            } else {
                cont?.resumeWithException(WriteFailedException("GATT write failed with status $status"))
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
            notificationFlow.tryEmit(value)
        }

        @Deprecated("Used for Android < 13")
        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            notificationFlow.tryEmit(characteristic.value)
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d("BleTransport", "System MTU changed to: $mtu")
                mtuSize = mtu - 3
            }
        }
    }

    suspend fun connect() = connectionMutex.withLock {
        val connectionState = bluetoothManager.getConnectionState(device, BluetoothProfile.GATT)
        if (gatt != null && connectionState == BluetoothProfile.STATE_CONNECTED) {
            Log.d("BleTransport", "Device is already connected.")
            return
        }

        try {
            suspendCancellableCoroutine<Unit> { continuation ->
                connectContinuation = continuation
                Log.d("BleTransport", "Attempting to connect...")
                gatt = device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)

                continuation.invokeOnCancellation {
                    val cont = connectContinuation
                    connectContinuation = null
                    if (cont != null) {
                        Log.w("BleTransport", "Connect coroutine cancelled, closing connection.")
                        close()
                    }
                }
            }
        } catch (e: Exception) {
            if (e is CancellationException) {
                Log.w("BleTransport", "Connection explicitly cancelled.")
            } else {
                Log.e("BleTransport", "Connection failed in connect() function", e)
            }
            close()
            throw e
        }
    }

    private fun setNotification(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic?, enable: Boolean) {
        characteristic ?: return
        gatt.setCharacteristicNotification(characteristic, enable)
        val descriptor = characteristic.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")) ?: return

        val value = if (enable) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeDescriptor(descriptor, value)
        } else {
            @Suppress("DEPRECATION")
            descriptor.value = value
            @Suppress("DEPRECATION")
            gatt.writeDescriptor(descriptor)
        }
    }

    suspend fun inferMtu() {
        Log.d("BleTransport", "Starting MTU inference...")
        withTimeout(5000) {
            val inferMtuCommand = byteArrayOf(0x08, 0, 0, 0, 0)

            val response = coroutineScope {
                val responseDeferred = async(start = CoroutineStart.LAZY) {
                    notificationFlow.first { it.isNotEmpty() && it[0] == 0x08.toByte() }
                }

                responseDeferred.start()
                delay(50)

                Log.d("BleTransport", "Writing MTU command...")
                write(inferMtuCommand)

                responseDeferred.await()
            }

            val newMtu = response[5].toInt() and 0xFF
            Log.d("BleTransport", "Received MTU response. New app-level MTU: $newMtu")
            gatt?.requestMtu(newMtu + 3)
        }
    }

    suspend fun exchange(apdu: ByteArray): ByteArray = withTimeout(120000) {
        coroutineScope {
            val responseFlow = receiveApdu(notificationFlow)
            val responseJob = async { responseFlow.first() }
            val sendJob = launch { sendApdu(::write, apdu, mtuSize) }
            val response = responseJob.await()
            sendJob.cancelAndJoin()
            response
        }
    }

    private suspend fun write(data: ByteArray) = writeMutex.withLock {
        val gatt = this.gatt ?: throw DeviceNotConnectedException()
        val characteristic = writeCharacteristic ?: throw CharacteristicNotFoundException("Write")
        Log.d("BleTransport", "Writing data: ${data.joinToString("") { "%02x".format(it) }}")

        suspendCancellableCoroutine { continuation ->
            writeContinuation = continuation

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val result = gatt.writeCharacteristic(characteristic, data, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT)
                if (result != BluetoothGatt.GATT_SUCCESS) {
                    val cont = writeContinuation
                    writeContinuation = null
                    cont?.resumeWithException(WriteFailedException("writeCharacteristic returned status $result"))
                }
            } else {
                @Suppress("DEPRECATION")
                characteristic.value = data
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                @Suppress("DEPRECATION")
                if (!gatt.writeCharacteristic(characteristic)) {
                    val cont = writeContinuation
                    writeContinuation = null
                    cont?.resumeWithException(WriteFailedException("writeCharacteristic returned false"))
                }
            }

            continuation.invokeOnCancellation {
                writeContinuation = null
            }
        }
    }

    fun close() {
        val gattToClose = gatt
        gatt = null
        gattToClose?.disconnect()
        gattToClose?.close()
        Log.d("BleTransport", "Connection closed.")
    }
}
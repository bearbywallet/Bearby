package ble

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.util.*
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

@SuppressLint("MissingPermission")
class BleTransport(private val context: Context, private val device: BluetoothDevice) {
    private var gatt: BluetoothGatt? = null
    private var writeCharacteristic: BluetoothGattCharacteristic? = null
    private var notifyCharacteristic: BluetoothGattCharacteristic? = null
    var serviceUuid: UUID? = null

    private val notificationFlow = MutableSharedFlow<ByteArray>()
    private var mtuSize = 20

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> gatt.discoverServices()
                BluetoothProfile.STATE_DISCONNECTED -> close()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            val infos = Devices.getInfosForServiceUuid(
                gatt.services.firstOrNull { Devices.isLedgerService(it.uuid) }?.uuid.toString()
            ) ?: return

            val service = gatt.getService(infos.serviceUuid) ?: return
            serviceUuid = service.uuid
            writeCharacteristic = service.getCharacteristic(infos.writeUuid)
            notifyCharacteristic = service.getCharacteristic(infos.notifyUuid)

            setNotification(gatt, notifyCharacteristic, true)
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            (characteristic.value as? Continuation<Unit>)?.resume(Unit)
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            notificationFlow.tryEmit(characteristic.value)
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            mtuSize = mtu - 3
        }
    }

    suspend fun connect() = suspendCancellableCoroutine<Unit> { continuation ->
        gatt = device.connectGatt(context, false, gattCallback)
        continuation.invokeOnCancellation { gatt?.disconnect() }
    }

    private fun setNotification(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic?, enable: Boolean) {
        characteristic ?: return
        gatt.setCharacteristicNotification(characteristic, enable)
        val descriptor = characteristic.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"))
        descriptor.value = if (enable) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
        gatt.writeDescriptor(descriptor)
    }

    suspend fun inferMtu() {
        withTimeout(5000) {
            val inferMtuCommand = byteArrayOf(0x08, 0, 0, 0, 0)
            coroutineScope {
                val responseJob = launch {
                    val response = notificationFlow.first { it.isNotEmpty() && it[0] == 0x08.toByte() }
                    mtuSize = response[5].toInt() and 0xFF
                    gatt?.requestMtu(mtuSize + 3) // Add 3 for ATT header
                }
                launch { write(inferMtuCommand) }
                responseJob.join()
            }
        }
    }

    suspend fun exchange(apdu: ByteArray): ByteArray = withTimeout(30000) {
        coroutineScope {
            val responseFlow = receiveApdu(notificationFlow)
            val responseJob = async { responseFlow.first() }

            val sendJob = launch { sendApdu(::write, apdu, mtuSize) }

            val response = responseJob.await()
            sendJob.cancel()
            response
        }
    }

    private suspend fun write(data: ByteArray): Unit = suspendCoroutine { continuation ->
        val characteristic = writeCharacteristic ?: throw CharacteristicNotFoundException("Write")
        characteristic.value = data
        characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        if (gatt?.writeCharacteristic(characteristic) == false) {
            continuation.resumeWithException(WriteFailedException())
        }
    }

    fun close() {
        gatt?.disconnect()
        gatt?.close()
        gatt = null
    }
}
package hid

import android.hardware.usb.*
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.min

class HidDevice(manager: UsbManager, device: UsbDevice) {

    private val connection: UsbDeviceConnection
    private val dongleInterface: UsbInterface = device.getInterface(0)
    private val endpointIn: UsbEndpoint
    private val endpointOut: UsbEndpoint
    private val executor = Executors.newSingleThreadExecutor()

    companion object {
        private const val HID_BUFFER_SIZE = 64
        private const val LEDGER_DEFAULT_CHANNEL = 1
    }

    init {
        var inEp: UsbEndpoint? = null
        var outEp: UsbEndpoint? = null
        for (i in 0 until dongleInterface.endpointCount) {
            val endpoint = dongleInterface.getEndpoint(i)
            if (endpoint.direction == UsbConstants.USB_DIR_IN) {
                inEp = endpoint
            } else {
                outEp = endpoint
            }
        }
        endpointIn = inEp ?: throw Exception("Input endpoint not found")
        endpointOut = outEp ?: throw Exception("Output endpoint not found")
        connection = manager.openDevice(device) ?: throw Exception("Failed to open device")
        connection.claimInterface(dongleInterface, true)
    }

    fun exchange(command: ByteArray): ByteArray {
        val future = executor.submit<ByteArray> {
            val response = ByteArrayOutputStream()
            var responseData: ByteArray? = null
            var offset = 0
            val wrappedCommand = LedgerHelper.wrapCommandAPDU(LEDGER_DEFAULT_CHANNEL, command, HID_BUFFER_SIZE)

            while (offset != wrappedCommand.size) {
                val blockSize = min(wrappedCommand.size - offset, HID_BUFFER_SIZE)
                val buffer = ByteArray(blockSize)
                System.arraycopy(wrappedCommand, offset, buffer, 0, blockSize)
                val bytesSent = connection.bulkTransfer(endpointOut, buffer, blockSize, 5000)
                if (bytesSent < 0) {
                    throw DisconnectedDeviceException("I/O error on write")
                }
                offset += blockSize
            }

            val transferBuffer = ByteArray(HID_BUFFER_SIZE)
            while (true) {
                val bytesRead = connection.bulkTransfer(endpointIn, transferBuffer, HID_BUFFER_SIZE, 5000)
                if (bytesRead < 0) {
                    throw DisconnectedDeviceException("I/O error on read")
                }
                response.write(transferBuffer, 0, bytesRead)
                responseData = LedgerHelper.unwrapResponseAPDU(LEDGER_DEFAULT_CHANNEL, response.toByteArray(), HID_BUFFER_SIZE)
                if (responseData != null) {
                    break
                }
            }
            responseData
        }
        return future.get()
    }


    fun close() {
        executor.submit {
            connection.releaseInterface(dongleInterface)
            connection.close()
        }.get()
        executor.shutdown()
    }
}
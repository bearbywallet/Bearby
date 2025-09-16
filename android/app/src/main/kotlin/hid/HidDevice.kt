package hid

import android.hardware.usb.*
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
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

            val outRequest = UsbRequest()
            try {
                if (!outRequest.initialize(connection, endpointOut)) {
                    throw DisconnectedDeviceException("Failed to initialize OUT request")
                }
                while (offset != wrappedCommand.size) {
                    val blockSize = min(wrappedCommand.size - offset, HID_BUFFER_SIZE)
                    val buffer = ByteBuffer.wrap(wrappedCommand, offset, blockSize)

                    if (!outRequest.queue(buffer, blockSize)) {
                        throw DisconnectedDeviceException("Failed to queue OUT request")
                    }

                    if (connection.requestWait() == null) {
                        throw DisconnectedDeviceException("I/O error on write (requestWait failed)")
                    }
                    offset += blockSize
                }
            } finally {
                outRequest.close()
            }

            val inRequest = UsbRequest()
            try {
                if (!inRequest.initialize(connection, endpointIn)) {
                    throw DisconnectedDeviceException("Failed to initialize IN request")
                }
                val responseBuffer = ByteBuffer.allocate(HID_BUFFER_SIZE)

                while (true) {
                    responseBuffer.clear()
                    if (!inRequest.queue(responseBuffer, HID_BUFFER_SIZE)) {
                        throw DisconnectedDeviceException("Failed to queue IN request")
                    }

                    if (connection.requestWait() == null) {
                        throw DisconnectedDeviceException("I/O error on read (requestWait failed)")
                    }

                    val bytesRead = responseBuffer.position()
                    if (bytesRead > 0) {
                        val chunk = ByteArray(bytesRead)
                        responseBuffer.rewind()
                        responseBuffer.get(chunk, 0, bytesRead)
                        response.write(chunk)
                    }

                    responseData = LedgerHelper.unwrapResponseAPDU(LEDGER_DEFAULT_CHANNEL, response.toByteArray(), HID_BUFFER_SIZE)
                    if (responseData != null) {
                        break
                    }
                }
            } finally {
                inRequest.close()
            }

            responseData
        }
        // Вот изменение:
        return future.get(15, TimeUnit.SECONDS)
    }

    fun close() {
        executor.submit {
            connection.releaseInterface(dongleInterface)
            connection.close()
        }.get()
        executor.shutdown()
    }
}
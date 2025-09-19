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
        private const val TIMEOUT_MS = 5000L
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
            // Wrap command into HID packets
            val wrappedCommand = LedgerHelper.wrapCommandAPDU(LEDGER_DEFAULT_CHANNEL, command, HID_BUFFER_SIZE)

            // Send packets one by one
            val packets = mutableListOf<ByteArray>()
            var offset = 0
            while (offset < wrappedCommand.size) {
                val packet = ByteArray(HID_BUFFER_SIZE)
                val copySize = min(HID_BUFFER_SIZE, wrappedCommand.size - offset)
                System.arraycopy(wrappedCommand, offset, packet, 0, copySize)
                packets.add(packet)
                offset += HID_BUFFER_SIZE
            }

            // Send each packet
            for ((index, packet) in packets.withIndex()) {
                val bytesSent = connection.bulkTransfer(
                    endpointOut,
                    packet,
                    packet.size,
                    TIMEOUT_MS.toInt()
                )

                if (bytesSent != packet.size) {
                    throw DisconnectedDeviceException("Failed to send packet $index: expected ${packet.size}, sent $bytesSent")
                }

                // Small delay between packets for device processing
                if (index < packets.size - 1) {
                    Thread.sleep(10)
                }
            }

            // Read response
            val response = ByteArrayOutputStream()
            var responseData: ByteArray? = null
            val buffer = ByteArray(HID_BUFFER_SIZE)
            var attempts = 0
            val maxAttempts = 100 // Max 5 seconds with 50ms delays

            while (responseData == null && attempts < maxAttempts) {
                val bytesRead = connection.bulkTransfer(
                    endpointIn,
                    buffer,
                    buffer.size,
                    50 // Short timeout for each read
                )

                if (bytesRead > 0) {
                    response.write(buffer, 0, bytesRead)
                    responseData = LedgerHelper.unwrapResponseAPDU(
                        LEDGER_DEFAULT_CHANNEL,
                        response.toByteArray(),
                        HID_BUFFER_SIZE
                    )
                } else if (bytesRead < 0 && response.size() == 0) {
                    // Only throw if we haven't received any data yet
                    Thread.sleep(50)
                    attempts++
                } else {
                    // No more data but we already have some response
                    Thread.sleep(50)
                    attempts++
                }
            }

            if (responseData == null) {
                throw DisconnectedDeviceException("Failed to receive complete response after $attempts attempts")
            }

            responseData
        }

        return future.get(30, TimeUnit.SECONDS)
    }

    fun close() {
        executor.submit {
            connection.releaseInterface(dongleInterface)
            connection.close()
        }.get()
        executor.shutdown()
    }
}
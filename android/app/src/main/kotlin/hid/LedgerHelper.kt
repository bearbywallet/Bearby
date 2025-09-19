package hid

import java.io.ByteArrayOutputStream

object LedgerHelper {
    private const val TAG_APDU = 0x05

    fun wrapCommandAPDU(channel: Int, command: ByteArray, packetSize: Int): ByteArray {
        val output = ByteArrayOutputStream()
        if (packetSize < 3) {
            throw IllegalArgumentException("Packet size must be at least 3")
        }
        var sequenceIdx = 0
        var offset = 0

        // Debug: Log command info
        android.util.Log.d("LedgerHelper", "Wrapping command: size=${command.size}, packetSize=$packetSize")

        // First packet
        val firstPacket = ByteArrayOutputStream()
        firstPacket.write(channel shr 8)
        firstPacket.write(channel and 0xff)
        firstPacket.write(TAG_APDU)
        firstPacket.write(sequenceIdx shr 8)
        firstPacket.write(sequenceIdx and 0xff)
        sequenceIdx++
        firstPacket.write(command.size shr 8)
        firstPacket.write(command.size and 0xff)

        var blockSize = (command.size - offset).coerceAtMost(packetSize - 7)
        firstPacket.write(command, offset, blockSize)
        offset += blockSize

        // Pad first packet to packetSize
        while (firstPacket.size() < packetSize) {
            firstPacket.write(0x00)
        }
        val firstBytes = firstPacket.toByteArray()
        android.util.Log.d("LedgerHelper", "First packet: size=${firstBytes.size}, header=${firstBytes.take(7).joinToString(" ") { "%02x".format(it) }}")
        output.write(firstBytes)

        // Subsequent packets
        var packetCount = 1
        while (offset < command.size) {
            val packet = ByteArrayOutputStream()
            packet.write(channel shr 8)
            packet.write(channel and 0xff)
            packet.write(TAG_APDU)
            packet.write(sequenceIdx shr 8)
            packet.write(sequenceIdx and 0xff)
            sequenceIdx++

            blockSize = (command.size - offset).coerceAtMost(packetSize - 5)
            packet.write(command, offset, blockSize)
            offset += blockSize

            // Pad each packet to packetSize
            while (packet.size() < packetSize) {
                packet.write(0x00)
            }
            val packetBytes = packet.toByteArray()
            android.util.Log.d("LedgerHelper", "Packet $packetCount: size=${packetBytes.size}, seq=${sequenceIdx-1}")
            output.write(packetBytes)
            packetCount++
        }

        android.util.Log.d("LedgerHelper", "Total packets created: $packetCount")
        return output.toByteArray()
    }

    fun unwrapResponseAPDU(channel: Int, data: ByteArray, packetSize: Int): ByteArray? {
        if (data.size < 7) {
            return null
        }

        val response = ByteArrayOutputStream()
        var offset = 0
        var sequenceIdx = 0

        // Parse first packet
        if (data[offset++].toInt() and 0xff != (channel shr 8)) return null
        if (data[offset++].toInt() and 0xff != (channel and 0xff)) return null
        if (data[offset++].toInt() and 0xff != TAG_APDU) return null
        if (data[offset++].toInt() and 0xff != 0x00) return null
        if (data[offset++].toInt() and 0xff != 0x00) return null

        val responseLength = ((data[offset++].toInt() and 0xff) shl 8) or (data[offset++].toInt() and 0xff)

        if (responseLength == 0) {
            return ByteArray(0)
        }

        var blockSize = responseLength.coerceAtMost(packetSize - 7)
        if (offset + blockSize > data.size) {
            blockSize = data.size - offset
        }
        response.write(data, offset, blockSize)
        offset += blockSize

        // Skip padding in first packet
        val firstPacketEnd = ((offset - 1) / packetSize + 1) * packetSize
        offset = firstPacketEnd

        // Parse subsequent packets
        while (response.size() < responseLength) {
            if (offset >= data.size) {
                return null // Need more data
            }

            sequenceIdx++

            // Check packet header
            if (data[offset++].toInt() and 0xff != (channel shr 8)) return null
            if (data[offset++].toInt() and 0xff != (channel and 0xff)) return null
            if (data[offset++].toInt() and 0xff != TAG_APDU) return null
            if (data[offset++].toInt() and 0xff != (sequenceIdx shr 8)) return null
            if (data[offset++].toInt() and 0xff != (sequenceIdx and 0xff)) return null

            blockSize = (responseLength - response.size()).coerceAtMost(packetSize - 5)
            if (offset + blockSize > data.size) {
                blockSize = data.size - offset
            }
            response.write(data, offset, blockSize)
            offset += blockSize

            // Skip padding
            val packetEnd = ((offset - 1) / packetSize + 1) * packetSize
            offset = packetEnd
        }

        return if (response.size() == responseLength) {
            response.toByteArray()
        } else {
            null
        }
    }
}
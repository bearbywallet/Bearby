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

        output.write(channel shr 8)
        output.write(channel)
        output.write(TAG_APDU)
        output.write(sequenceIdx shr 8)
        output.write(sequenceIdx)
        sequenceIdx++
        output.write(command.size shr 8)
        output.write(command.size)
        var blockSize = (command.size - offset).coerceAtMost(packetSize - 7)
        output.write(command, offset, blockSize)
        offset += blockSize
        while (offset != command.size) {
            output.write(channel shr 8)
            output.write(channel)
            output.write(TAG_APDU)
            output.write(sequenceIdx shr 8)
            output.write(sequenceIdx)
            sequenceIdx++
            blockSize = (command.size - offset).coerceAtMost(packetSize - 5)
            output.write(command, offset, blockSize)
            offset += blockSize
        }
        val currentSize = output.size()
        if ((currentSize % packetSize) != 0) {
            val paddingSize = packetSize - (currentSize % packetSize)
            val padding = ByteArray(paddingSize)
            output.write(padding, 0, padding.size)
        }
        return output.toByteArray()
    }

    fun unwrapResponseAPDU(channel: Int, data: ByteArray, packetSize: Int): ByteArray? {
        val response = ByteArrayOutputStream()
        var offset = 0
        val responseLength: Int
        var sequenceIdx = 0
        if (data.size < 7 + 5) {
            return null
        }
        if (data[offset++].toInt() != (channel shr 8)) throw Exception("Invalid channel")
        if (data[offset++].toInt() != (channel and 0xff)) throw Exception("Invalid channel")
        if (data[offset++].toInt() != TAG_APDU) throw Exception("Invalid tag")
        if (data[offset++].toInt() != 0x00) throw Exception("Invalid sequence")
        if (data[offset++].toInt() != 0x00) throw Exception("Invalid sequence")

        responseLength = ((data[offset++].toInt() and 0xff) shl 8) or (data[offset++].toInt() and 0xff)
        if (data.size < 7 + responseLength) {
            return null
        }

        var blockSize = responseLength.coerceAtMost(packetSize - 7)
        response.write(data, offset, blockSize)
        offset += blockSize

        while (response.size() != responseLength) {
            sequenceIdx++
            if (offset == data.size) {
                return null
            }
            if (data[offset++].toInt() != (channel shr 8)) throw Exception("Invalid channel")
            if (data[offset++].toInt() != (channel and 0xff)) throw Exception("Invalid channel")
            if (data[offset++].toInt() != TAG_APDU) throw Exception("Invalid tag")
            if (data[offset++].toInt() != (sequenceIdx shr 8)) throw Exception("Invalid sequence")
            if (data[offset++].toInt() != (sequenceIdx and 0xff)) throw Exception("Invalid sequence")

            blockSize = (responseLength - response.size()).coerceAtMost(packetSize - 5)
            if (blockSize > data.size - offset) {
                return null
            }
            response.write(data, offset, blockSize)
            offset += blockSize
        }
        return response.toByteArray()
    }
}
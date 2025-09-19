package ble

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.transform
import java.nio.ByteBuffer

private const val TAG_ID: Byte = 0x05

suspend fun sendApdu(
    write: suspend (ByteArray) -> Unit,
    apdu: ByteArray,
    mtuSize: Int
) {
    val firstChunkPayloadSize = mtuSize - 5
    val subsequentChunkPayloadSize = mtuSize - 3

    if (firstChunkPayloadSize <= 0) {
        throw IllegalArgumentException("MTU size is too small")
    }

    val chunks = mutableListOf<ByteArray>()
    var offset = 0
    var sequence = 0

    while (offset < apdu.size) {
        val isFirstChunk = sequence == 0
        val payloadSize = if (isFirstChunk) firstChunkPayloadSize else subsequentChunkPayloadSize
        val chunkSize = minOf(apdu.size - offset, payloadSize)

        val chunkData = apdu.sliceArray(offset until offset + chunkSize)

        val headerSize = if (isFirstChunk) 5 else 3
        val buffer = ByteBuffer.allocate(headerSize + chunkData.size)
        buffer.put(TAG_ID)
        buffer.putShort(sequence.toShort())
        if (isFirstChunk) {
            buffer.putShort(apdu.size.toShort())
        }
        buffer.put(chunkData)
        chunks.add(buffer.array())

        offset += chunkSize
        sequence++
    }

    for (chunk in chunks) {
        write(chunk)
        delay(20)
    }
}

fun receiveApdu(rawFlow: Flow<ByteArray>): Flow<ByteArray> = flow {
    var notifiedIndex = 0
    var notifiedDataLength = 0
    var notifiedData = byteArrayOf()

    rawFlow
        .transform { value ->
            if (value.isEmpty() || value[0] != TAG_ID) return@transform

            val buffer = ByteBuffer.wrap(value)
            buffer.get()
            val chunkIndex = buffer.short.toInt()

            if (notifiedIndex != chunkIndex) {
                throw InvalidSequenceException("Expected $notifiedIndex, got $chunkIndex")
            }

            val chunkData = if (chunkIndex == 0) {
                notifiedDataLength = buffer.short.toInt() and 0xFFFF
                ByteArray(value.size - 5).also { buffer.get(it) }
            } else {
                ByteArray(value.size - 3).also { buffer.get(it) }
            }

            notifiedIndex++
            notifiedData += chunkData

            if (notifiedData.size > notifiedDataLength) {
                throw BleTooMuchDataException("Expected $notifiedDataLength, got ${notifiedData.size}")
            }

            if (notifiedData.size == notifiedDataLength) {
                emit(notifiedData)
            }
        }
        .collect { emit(it) }
}
package ble

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
    val chunks = apdu.asIterable().chunked(mtuSize - 3) { it.toByteArray() }
        .mapIndexed { i, chunk ->
            val headerSize = if (i == 0) 5 else 3
            val buffer = ByteBuffer.allocate(headerSize + chunk.size)
            buffer.put(TAG_ID)
            buffer.putShort(i.toShort())
            if (i == 0) {
                buffer.putShort(apdu.size.toShort())
            }
            buffer.put(chunk)
            buffer.array()
        }

    for (chunk in chunks) {
        write(chunk)
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
            buffer.get() // Skip tag
            val chunkIndex = buffer.short.toInt()

            if (notifiedIndex != chunkIndex) {
                throw InvalidSequenceException("Expected $notifiedIndex, got $chunkIndex")
            }

            val chunkData = if (chunkIndex == 0) {
                notifiedDataLength = buffer.short.toInt()
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
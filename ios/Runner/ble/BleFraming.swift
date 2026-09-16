import Foundation
import os.log

private let TAG_ID: UInt8 = 0x05
private let logger = Logger(subsystem: "com.zilpay.ble", category: "BleFraming")

/// Debug hex dump. Sensitive-data rule: raw APDU bytes (which contain signed
/// payloads) must NEVER reach the unified log - only sizes/counts are logged.
private func hexPreview(_ data: Data, limit: Int = 20) -> String {
    data.prefix(limit).map { String(format: "%02x", $0) }.joined()
}

func sendApdu(
    write: @escaping (Data) async throws -> Void,
    apdu: Data,
    mtuSize: Int
) async throws {
    logger.info("Starting APDU send: \(apdu.count) bytes, MTU \(mtuSize)")
    
    let firstChunkPayloadSize = mtuSize - 5
    let subsequentChunkPayloadSize = mtuSize - 3
    
    guard firstChunkPayloadSize > 0, subsequentChunkPayloadSize > 0 else {
        logger.error("MTU size too small: \(mtuSize)")
        throw BleError.illegalArgument("MTU size is too small")
    }
    
    logger.info("Payload size: First chunk: \(firstChunkPayloadSize), Subsequent: \(subsequentChunkPayloadSize)")

    var offset = 0
    var sequence: UInt16 = 0
    
    while offset < apdu.count {
        let isFirstChunk = sequence == 0
        let chunkSize = isFirstChunk ? firstChunkPayloadSize : subsequentChunkPayloadSize
        
        let remaining = apdu.count - offset
        let size = min(remaining, chunkSize)
        
        logger.info("Preparing chunk \(sequence + 1):")
        logger.info("  Offset: \(offset), Size: \(size)")
        
        var buffer = Data()
        buffer.append(TAG_ID)
        buffer.append(contentsOf: withUnsafeBytes(of: sequence.bigEndian) { Array($0) })
        
        if isFirstChunk {
            logger.info("  First chunk - adding length header: \(apdu.count)")
            buffer.append(contentsOf: withUnsafeBytes(of: UInt16(apdu.count).bigEndian) { Array($0) })
        }
        
        let chunkData = apdu.subdata(in: offset..<offset + size)
        buffer.append(chunkData)
        
        logger.debug("Chunk \(sequence) (\(buffer.count) bytes): \(hexPreview(buffer))")
        
        try await write(buffer)
        
        offset += size
        sequence += 1
    }
    
    logger.info("APDU send completed - \(sequence) chunks")
}

func receiveApdu(
    notificationStream: AsyncThrowingStream<Data, Error>
) -> AsyncThrowingStream<Data, Error> {
    logger.info("Starting APDU receive process...")
    
    return AsyncThrowingStream { continuation in
        Task {
            var notifiedIndex: UInt16 = 0
            var notifiedDataLength: Int = 0
            var notifiedData = Data()
            
            logger.info("Listening for APDU chunks...")
            
            do {
                for try await value in notificationStream {
                    logger.debug("Raw notification (\(value.count) bytes): \(hexPreview(value))")
                    
                    guard !value.isEmpty, value[0] == TAG_ID else {
                        logger.info("Skipping - invalid TAG_ID or empty data")
                        continue
                    }
                    
                    guard value.count >= 3 else {
                        logger.warning("Skipping - data too short: \(value.count) bytes")
                        continue
                    }
                    
                    let chunkIndex = value.subdata(in: 1..<3).toUInt16()
                    logger.info("Processing chunk \(chunkIndex + 1) (expected: \(notifiedIndex + 1))")
                    
                    if notifiedIndex != chunkIndex {
                        logger.error("Sequence error - expected \(notifiedIndex), got \(chunkIndex)")
                        throw BleError.invalidSequence("Expected \(notifiedIndex), got \(chunkIndex)")
                    }

                    let chunkData: Data
                    if chunkIndex == 0 {
                        guard value.count >= 5 else {
                            logger.warning("First chunk too short: \(value.count) bytes")
                            continue
                        }
                        notifiedDataLength = Int(value.subdata(in: 3..<5).toUInt16())
                        chunkData = value.subdata(in: 5..<value.count)
                        logger.info("First chunk - total expected length: \(notifiedDataLength)")
                    } else {
                        chunkData = value.subdata(in: 3..<value.count)
                    }
                    
                    logger.debug("Chunk \(chunkIndex) payload (\(chunkData.count) bytes): \(hexPreview(chunkData))")
                    
                    notifiedIndex += 1
                    notifiedData.append(chunkData)
                    
                    logger.info("Progress: \(notifiedData.count)/\(notifiedDataLength) bytes received")
                    
                    if notifiedData.count > notifiedDataLength {
                        logger.error("Received too much data - expected \(notifiedDataLength), got \(notifiedData.count)")
                        throw BleError.tooMuchData("Expected \(notifiedDataLength), got \(notifiedData.count)")
                    }
                    
                    if notifiedData.count == notifiedDataLength {
                        logger.info("APDU receive completed (\(notifiedData.count) bytes)")
                        // Full-APDU hex logging removed: signature payloads are sensitive.
                        continuation.yield(notifiedData)
                        continuation.finish()
                        return
                    }
                }
                logger.info("Notification stream ended")
                continuation.finish()
            } catch {
                logger.error("APDU receive failed: \(error.localizedDescription)")
                continuation.finish(throwing: error)
            }
        }
    }
}

// Утилиты для работы с Data
extension Data {
    func toUInt16() -> UInt16 {
        guard self.count >= 2 else {
            logger.warning("Data too short for UInt16 conversion: \(self.count) bytes")
            return 0
        }
        return self.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
    }
}

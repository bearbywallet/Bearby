import Foundation

private let TAG_ID: UInt8 = 0x05

func sendApdu(
    write: @escaping (Data) async throws -> Void,
    apdu: Data,
    mtuSize: Int
) async throws {
    let chunkSize = mtuSize - 3
    guard chunkSize > 0 else { throw BleError.illegalArgument("MTU size is too small") }

    var offset = 0
    var sequence: UInt16 = 0
    
    while offset < apdu.count {
        let remaining = apdu.count - offset
        let size = min(remaining, chunkSize)
        
        var buffer: Data
        if sequence == 0 {
            buffer = Data(capacity: 5 + size)
            buffer.append(TAG_ID)
            buffer.append(UInt16(sequence).bigEndian.data)
            buffer.append(UInt16(apdu.count).bigEndian.data)
        } else {
            buffer = Data(capacity: 3 + size)
            buffer.append(TAG_ID)
            buffer.append(UInt16(sequence).bigEndian.data)
        }
        
        buffer.append(apdu.subdata(in: offset ..< offset + size))
        try await write(buffer)
        
        offset += size
        sequence += 1
    }
}


func receiveApdu(
    notificationStream: AsyncThrowingStream<Data, Error>
) -> AsyncThrowingStream<Data, Error> {
    return AsyncThrowingStream { continuation in
        Task {
            var notifiedIndex: UInt16 = 0
            var notifiedDataLength: Int = 0
            var notifiedData = Data()
            
            do {
                for try await value in notificationStream {
                    guard !value.isEmpty, value[0] == TAG_ID else { continue }
                    
                    var data = value.dropFirst() // Skip TAG

                    let chunkIndex = data.prefix(2).toUInt16()
                    data = data.dropFirst(2)
                    
                    if notifiedIndex != chunkIndex {
                        throw BleError.invalidSequence("Expected \(notifiedIndex), got \(chunkIndex)")
                    }

                    if chunkIndex == 0 {
                        notifiedDataLength = Int(data.prefix(2).toUInt16())
                        data = data.dropFirst(2)
                    }
                    
                    notifiedIndex += 1
                    notifiedData.append(data)
                    
                    if notifiedData.count > notifiedDataLength {
                        throw BleError.tooMuchData("Expected \(notifiedDataLength), got \(notifiedData.count)")
                    }
                    
                    if notifiedData.count == notifiedDataLength {
                        continuation.yield(notifiedData)
                        continuation.finish()
                        return
                    }
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

// Утилиты для работы с Data
extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension Data {
    func toUInt16() -> UInt16 {
        return self.withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
    }
}

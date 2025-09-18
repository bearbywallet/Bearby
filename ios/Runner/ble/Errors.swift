import Foundation

enum BleError: Error, LocalizedError {
    case permissionError(String)
    case scanError(String)
    case deviceNotFound
    case notConnected(String)
    case characteristicNotFound(String)
    case writeFailed(String)
    case invalidSequence(String)
    case tooMuchData(String)
    case unimplemented
    case illegalArgument(String)

    var errorDescription: String? {
        switch self {
        case .permissionError(let msg): return msg
        case .scanError(let msg): return msg
        case .deviceNotFound: return "Device not found"
        case .notConnected(let msg): return msg
        case .characteristicNotFound(let type): return "\(type) characteristic not found"
        case .writeFailed(let msg): return msg
        case .invalidSequence(let msg): return msg
        case .tooMuchData(let msg): return msg
        case .unimplemented: return "Not implemented"
        case .illegalArgument(let msg): return msg
        }
    }
}

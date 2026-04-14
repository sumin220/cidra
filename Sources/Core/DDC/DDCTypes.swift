import Foundation

/// DDC/CI VCP (Virtual Control Panel) codes
enum VCPCode: UInt8 {
    case brightness = 0x10
    case contrast   = 0x12
    case volume     = 0x62
    case inputSource = 0x60
    case powerMode  = 0xD6
}

enum DDCError: LocalizedError {
    case serviceUnavailable
    case writeFailed(status: Int32)
    case readFailed(status: Int32)
    case noExternalDisplay
    case unsupportedPlatform
    case timeout

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable: "DDC service unavailable"
        case .writeFailed(let s): "DDC write failed (status: \(s))"
        case .readFailed(let s): "DDC read failed (status: \(s))"
        case .noExternalDisplay: "No external display found"
        case .unsupportedPlatform: "Unsupported platform for DDC"
        case .timeout: "DDC command timed out"
        }
    }
}

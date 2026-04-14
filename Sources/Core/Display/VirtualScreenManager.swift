import Foundation
import CoreGraphics

/// Sharpening is now handled by DisplayOverrideManager (plist approach).
/// This file is kept as a thin wrapper for backward compatibility.
final class VirtualScreenManager {
    static let shared = VirtualScreenManager()
    private init() {}

    var isAvailable: Bool {
        true // plist approach always available
    }

    func enableSharpening(targetDisplayID: CGDirectDisplayID,
                          physicalWidth: Int,
                          physicalHeight: Int,
                          refreshRate: Int) -> UUID? {
        // No-op: sharpening is now handled by SharpeningSetupSheet + DisplayOverrideManager
        return nil
    }

    func disableSharpening(id: UUID) {
        // No-op
    }
}

enum DisplayError: LocalizedError {
    case configFailed, mirrorFailed, applyFailed, notAvailable

    var errorDescription: String? {
        switch self {
        case .configFailed: "Failed to begin display configuration"
        case .mirrorFailed: "Failed to configure display mirroring"
        case .applyFailed: "Failed to apply display configuration"
        case .notAvailable: "Virtual display API not available"
        }
    }
}

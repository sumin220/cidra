import Foundation
import CoreGraphics

/// Software brightness control via gamma table adjustment.
/// Used as fallback when DDC/CI is not supported by the monitor.
/// This doesn't change the backlight — it adjusts the color output,
/// similar to how f.lux or Night Shift work.
final class GammaBrightnessService {
    static let shared = GammaBrightnessService()
    private init() {}

    /// Set software brightness for a specific display.
    /// value: 0.0 (black) to 1.0 (full brightness / no gamma adjustment)
    func setBrightness(_ value: Double, displayID: CGDirectDisplayID) {
        let clamped = max(min(Float(value), 1.0), 0.0)

        // CGSetDisplayTransferByFormula takes min/max/gamma for each RGB channel.
        // To dim: set max to the desired brightness level.
        // min=0, max=brightness, gamma=1 gives a linear dimming effect.
        let result = CGSetDisplayTransferByFormula(
            displayID,
            0, clamped, 1,  // red:   min, max, gamma
            0, clamped, 1,  // green: min, max, gamma
            0, clamped, 1   // blue:  min, max, gamma
        )

        if result != .success {
            print("[Gamma] SetTransfer failed: \(result)")
        }
    }

    /// Reset gamma to default (full brightness, no tint)
    func resetBrightness(displayID: CGDirectDisplayID) {
        CGDisplayRestoreColorSyncSettings()
    }
}

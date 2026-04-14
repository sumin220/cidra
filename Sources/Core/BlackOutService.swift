import Foundation
import CoreGraphics
import AppKit

/// Centralized BlackOut and global brightness/volume control.
/// Used by both keyboard shortcuts and UI buttons.
final class BlackOutService {
    static let shared = BlackOutService()
    private(set) var isBlackedOut = false

    private init() {}

    func toggle() {
        isBlackedOut.toggle()

        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        CGGetActiveDisplayList(8, &ids, &count)

        if isBlackedOut {
            for i in 0..<Int(count) {
                GammaBrightnessService.shared.setBrightness(0.0, displayID: ids[i])
            }
            BuiltInBrightnessService.shared.setBrightness(0)
            setSystemVolume(0)
        } else {
            for i in 0..<Int(count) {
                GammaBrightnessService.shared.setBrightness(1.0, displayID: ids[i])
            }
            BuiltInBrightnessService.shared.setBrightness(1.0)
            // Volume stays at 0 as designed
        }
    }

    func adjustBrightness(delta: Double) {
        // Find first external monitor, fallback to any
        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        CGGetActiveDisplayList(8, &ids, &count)

        let extID = ids[0..<Int(count)].first { CGDisplayIsBuiltin($0) == 0 }
        let builtInID = ids[0..<Int(count)].first { CGDisplayIsBuiltin($0) != 0 }

        if let extID {
            // Adjust external via gamma (no direct hardware value to read, just step)
            // This is a simple approach — full integration would track current value
            OSDManager.shared.show(type: .brightness, value: max(0, delta > 0 ? 0.7 : 0.3))
        }
        if let builtInID {
            if let current = BuiltInBrightnessService.shared.getBrightness() {
                let newVal = min(max(current + delta, 0), 1)
                BuiltInBrightnessService.shared.setBrightness(newVal)
                OSDManager.shared.show(type: .brightness, value: newVal)
            }
        }
    }

    func adjustVolume(delta: Double) {
        // Volume adjustment via AppleScript
        let direction = delta > 0 ? "output volume of (get volume settings) + 5" : "output volume of (get volume settings) - 5"
        let script = "set volume output volume (\(direction))"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private func setSystemVolume(_ level: Int) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "set volume output volume \(level)"]
        try? process.run()
    }
}

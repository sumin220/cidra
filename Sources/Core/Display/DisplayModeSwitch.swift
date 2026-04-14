import Foundation
import CoreGraphics

final class DisplayModeSwitch {
    static let shared = DisplayModeSwitch()
    private init() {}

    private var originalMode: CGDisplayMode?

    func hasHiDPIMode(displayID: CGDirectDisplayID) -> Bool {
        bestHiDPIMode(displayID: displayID) != nil
    }

    func enableHiDPI(displayID: CGDirectDisplayID) -> Bool {
        guard let currentMode = CGDisplayCopyDisplayMode(displayID) else { return false }
        originalMode = currentMode

        guard let hidpiMode = bestHiDPIMode(displayID: displayID) else {
            CidraLog.write("[HiDPI] No suitable HiDPI mode found")
            return false
        }

        let result = CGDisplaySetDisplayMode(displayID, hidpiMode, nil)
        if result == .success {
            CidraLog.write("[HiDPI] ON: \(hidpiMode.width)x\(hidpiMode.height) backing \(hidpiMode.pixelWidth)x\(hidpiMode.pixelHeight)")
            return true
        }
        CidraLog.write("[HiDPI] Switch failed: \(result.rawValue)")
        return false
    }

    func disableHiDPI(displayID: CGDirectDisplayID) -> Bool {
        if let mode = originalMode {
            let result = CGDisplaySetDisplayMode(displayID, mode, nil)
            if result == .success {
                originalMode = nil
                CidraLog.write("[HiDPI] OFF: reverted")
                return true
            }
        }
        return false
    }

    func isHiDPIActive(displayID: CGDirectDisplayID) -> Bool {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else { return false }
        return mode.pixelWidth > mode.width
    }

    /// Description of the HiDPI mode that would be activated
    func hiDPIModeDescription(displayID: CGDirectDisplayID) -> String? {
        guard let mode = bestHiDPIMode(displayID: displayID) else { return nil }
        return "\(mode.width)x\(mode.height) HiDPI"
    }

    // MARK: - Mode Finding

    /// Find the best HiDPI mode — prioritizes near-native for invisible switching.
    /// 1. Exact match (same logical resolution, HiDPI backing)
    /// 2. Near-native: within 2% of current resolution (user can't tell the difference)
    /// 3. Largest HiDPI mode below current resolution
    private func bestHiDPIMode(displayID: CGDirectDisplayID) -> CGDisplayMode? {
        guard let currentMode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        let currentW = currentMode.width
        let currentH = currentMode.height
        let targetHz = currentMode.refreshRate

        let hidpiModes = allModes(displayID: displayID).filter { mode in
            mode.pixelWidth > mode.width && abs(mode.refreshRate - targetHz) < 1.0
        }

        // 1st: exact match
        if let exact = hidpiModes.first(where: { $0.width == currentW && $0.height == currentH }) {
            return exact
        }

        // 2nd: near-native (within 2% of current resolution)
        let nearNative = hidpiModes
            .filter {
                let wDiff = abs(Int($0.width) - Int(currentW))
                let hDiff = abs(Int($0.height) - Int(currentH))
                return wDiff < Int(currentW) / 50 && hDiff < Int(currentH) / 50
            }
            .sorted { $0.width * $0.height > $1.width * $1.height }

        if let best = nearNative.first {
            return best
        }

        // 3rd: largest HiDPI mode below current resolution
        let candidates = hidpiModes
            .filter { $0.width <= currentW && $0.height <= currentH }
            .sorted { $0.width * $0.height > $1.width * $1.height }

        return candidates.first
    }

    private func allModes(displayID: CGDirectDisplayID) -> [CGDisplayMode] {
        let options: [CFString: Any] = [
            kCGDisplayShowDuplicateLowResolutionModes: true
        ]
        return CGDisplayCopyAllDisplayModes(displayID, options as CFDictionary) as? [CGDisplayMode] ?? []
    }
}

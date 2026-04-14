import Foundation
import CoreGraphics

/// Syncs external monitor brightness to MacBook's ambient light sensor.
/// Polls built-in display brightness every 500ms and mirrors it to external monitors.
final class AmbientLightSync: ObservableObject {
    static let shared = AmbientLightSync()

    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "ambientLightSync")
            if isEnabled { start() } else { stop() }
        }
    }

    private var timer: Timer?
    private var lastBuiltInBrightness: Double = -1
    private let threshold = 0.02 // Minimum change to trigger update

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "ambientLightSync")
        if isEnabled { start() }
    }

    private func start() {
        stop()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        CidraLog.write("[AmbientSync] Started")
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        // Reset external monitors to full gamma
        resetExternalMonitors()
        CidraLog.write("[AmbientSync] Stopped")
    }

    private func poll() {
        guard let builtInBrightness = BuiltInBrightnessService.shared.getBrightness() else { return }

        // Only update if brightness changed significantly
        guard abs(builtInBrightness - lastBuiltInBrightness) > threshold else { return }
        lastBuiltInBrightness = builtInBrightness

        // Apply to all external monitors
        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        CGGetActiveDisplayList(8, &ids, &count)

        for i in 0..<Int(count) {
            let id = ids[i]
            guard CGDisplayIsBuiltin(id) == 0 else { continue }
            GammaBrightnessService.shared.setBrightness(builtInBrightness, displayID: id)
        }
    }

    private func resetExternalMonitors() {
        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        CGGetActiveDisplayList(8, &ids, &count)

        for i in 0..<Int(count) {
            let id = ids[i]
            guard CGDisplayIsBuiltin(id) == 0 else { continue }
            GammaBrightnessService.shared.setBrightness(1.0, displayID: id)
        }
    }
}

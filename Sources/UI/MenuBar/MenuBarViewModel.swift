import SwiftUI
import Combine
import CoreGraphics

extension Notification.Name {
    static let cidraSharpening = Notification.Name("cidraSharpening")
}

// File-level callback function for CGDisplayRegisterReconfigurationCallback.
// Must be a named function (not closure) so the same pointer can be used for register/remove.
private func displayReconfigCallback(displayID: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags, userInfo: UnsafeMutableRawPointer?) {
    guard flags.contains(.addFlag) || flags.contains(.removeFlag) else { return }
    guard let userInfo else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let vm = Unmanaged<MenuBarViewModel>.fromOpaque(userInfo).takeUnretainedValue()
        guard !vm.isSharpeningInProgress else { return }
        vm.refreshMonitors()
    }
}

final class MenuBarViewModel: ObservableObject {
    @Published var monitors: [MonitorState] = []
    @Published var presets: [Preset] = []
    @Published var activePresetID: UUID?
    // isPro removed — now using TrialManager.shared.isUnlocked

    private var displayReconfigToken: Any?

    init() {
        refreshMonitors()
        loadPresets()
        observeDisplayChanges()

        // Start auto-trigger engine
        AutoTriggerEngine.shared.start { [weak self] presetID in
            guard let self else { return }
            if let preset = self.presets.first(where: { $0.id == presetID }) {
                DispatchQueue.main.async {
                    self.applyPreset(preset)
                }
            }
        }
    }

    /// Detect connected monitors and build MonitorState list
    func refreshMonitors() {
        let displays = MonitorDetector.shared.detectDisplays()

        // Preserve existing slider values when refreshing
        let oldStates = Dictionary(uniqueKeysWithValues: monitors.map { ($0.cgDisplayID, $0) })

        monitors = displays.map { info in
            if let existing = oldStates[info.displayID] {
                return existing
            }
            let state = MonitorState(
                id: UUID(),
                name: info.name,
                isBuiltIn: info.isBuiltIn,
                brightness: 0.5,
                volume: info.isBuiltIn ? 0 : 0.5,
                sharpeningEnabled: false
            )
            state.cgDisplayID = info.displayID
            state.physicalWidth = info.width
            state.physicalHeight = info.height
            state.refreshRate = info.refreshRate
            return state
        }

        // Sort: external monitors first, built-in last
        monitors.sort { !$0.isBuiltIn && $1.isBuiltIn }

        print("[Cidra] Detected \(monitors.count) display(s): \(monitors.map { $0.name }.joined(separator: ", "))")
    }

    /// Suppress refreshMonitors during sharpening toggle
    var isSharpeningInProgress = false

    /// Listen for display connect/disconnect events.
    /// Uses passRetained to prevent dangling pointer — must be balanced with release in deinit.
    private func observeDisplayChanges() {
        let retained = Unmanaged.passRetained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(displayReconfigCallback, retained)
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(displayReconfigCallback, Unmanaged.passUnretained(self).toOpaque())
        // Balance the passRetained from observeDisplayChanges
        Unmanaged.passUnretained(self).release()
    }

    func loadPresets() {
        presets = PresetStore.shared.loadPresets()
        if presets.isEmpty {
            // Default presets with sensible brightness/volume values
            // Uses displayID 0 as wildcard — applyPreset will match any external monitor
            presets = [
                Preset(name: "Night", icon: "moon.fill", defaultBrightness: 0.2, defaultVolume: 0.2),
                Preset(name: "Work", icon: "desktopcomputer", defaultBrightness: 0.7, defaultVolume: 0.4),
                Preset(name: "Cinema", icon: "play.rectangle", defaultBrightness: 0.4, defaultVolume: 0.8),
            ]
        }
    }

    func applyPreset(_ preset: Preset) {
        activePresetID = preset.id

        if !preset.monitorSettings.isEmpty {
            // Per-monitor settings (user-saved presets)
            for setting in preset.monitorSettings {
                if let monitor = monitors.first(where: { $0.cgDisplayID == setting.displayID }) {
                    if let b = setting.brightness {
                        monitor.brightness = b
                        monitor.setBrightness(b)
                    }
                    if let v = setting.volume {
                        monitor.volume = v
                        monitor.setVolume(v)
                    }
                }
            }
        } else if let defB = preset.defaultBrightness {
            // Default presets — apply to all monitors
            for monitor in monitors {
                monitor.brightness = defB
                monitor.setBrightness(defB)
                if !monitor.isBuiltIn, let defV = preset.defaultVolume {
                    monitor.volume = defV
                    monitor.setVolume(defV)
                }
            }
        }
        CidraLog.write("[Preset] Applied: \(preset.name)")
    }

    func saveCurrentAsPreset(name: String, icon: String) {
        let settings = monitors.map { monitor in
            Preset.MonitorSetting(
                displayID: monitor.cgDisplayID,
                brightness: monitor.brightness,
                volume: monitor.isBuiltIn ? nil : monitor.volume
            )
        }
        let preset = Preset(name: name, icon: icon, monitorSettings: settings)
        presets.append(preset)
        PresetStore.shared.savePresets(presets)
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        if activePresetID == preset.id { activePresetID = nil }
        PresetStore.shared.savePresets(presets)
    }

    /// Re-read actual hardware state when panel opens
    func syncWithHardware() {
        for monitor in monitors {
            if monitor.isBuiltIn {
                if let hw = BuiltInBrightnessService.shared.getBrightness() {
                    monitor.brightness = hw
                }
            }
            // Reset active preset if hardware state changed
        }
    }

    @MainActor
    func openSettings() {
        SettingsWindowController.shared.show()
    }
}

// MARK: - Monitor State

final class MonitorState: ObservableObject, Identifiable {
    let id: UUID
    let name: String
    let isBuiltIn: Bool
    @Published var brightness: Double
    @Published var volume: Double
    @Published var sharpeningEnabled: Bool

    private var virtualScreenID: UUID?

    var physicalWidth: Int = 0
    var physicalHeight: Int = 0
    var refreshRate: Int = 60
    var cgDisplayID: CGDirectDisplayID = 0

    init(id: UUID, name: String, isBuiltIn: Bool, brightness: Double, volume: Double, sharpeningEnabled: Bool) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.brightness = brightness
        self.volume = volume
        self.sharpeningEnabled = sharpeningEnabled
    }

    /// Brightness range: -0.5 to 1.5
    /// -0.5~0.0: software dimming (gamma, below hardware minimum)
    /// 0.0~1.0: normal brightness
    /// 1.0~1.5: XDR brightness (built-in only)
    func setBrightness(_ value: Double) {
        let osdValue = min(max(value, 0), 1)
        OSDManager.shared.show(type: .brightness, value: osdValue)

        let displayID = cgDisplayID != 0 ? cgDisplayID : CGMainDisplayID()

        if isBuiltIn {
            // Built-in: use DisplayServices for hardware + XDR for boost
            if value > 1.0 {
                BuiltInBrightnessService.shared.setBrightness(1.0)
                GammaBrightnessService.shared.setBrightness(1.0, displayID: displayID)
                let xdrLevel = Float((value - 1.0) / 0.5)
                XDRBrightnessService.shared.setXDRBrightness(xdrLevel)
            } else if value < 0 {
                BuiltInBrightnessService.shared.setBrightness(0)
                XDRBrightnessService.shared.setXDRBrightness(0)
                let gamma = max(value + 0.5, 0) / 0.5
                GammaBrightnessService.shared.setBrightness(gamma, displayID: displayID)
            } else {
                BuiltInBrightnessService.shared.setBrightness(value)
                XDRBrightnessService.shared.setXDRBrightness(0)
                GammaBrightnessService.shared.setBrightness(1.0, displayID: displayID)
            }
        } else {
            // External: use gamma for entire range (smooth, no DDC timing issues)
            // Map -0.5~1.0 → gamma 0.0~1.0
            let gamma = min(max((value + 0.5) / 1.5, 0), 1)
            GammaBrightnessService.shared.setBrightness(gamma, displayID: displayID)
        }
    }

    func setVolume(_ value: Double) {
        let percent = Int(value * 100)
        OSDManager.shared.show(type: .volume, value: value)

        if !isBuiltIn {
            DDCService.shared.setVolume(percent)
        }
    }

    // Sharpening is now handled by SharpeningSetupSheet + DisplayOverrideManager
    // No runtime toggle needed — it's a one-time setup with reboot
}

// MARK: - Preset Model

struct Preset: Identifiable, Codable, Hashable {
    static func == (lhs: Preset, rhs: Preset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: UUID
    var name: String
    var icon: String
    var monitorSettings: [MonitorSetting]

    struct MonitorSetting: Codable {
        let displayID: CGDirectDisplayID
        var brightness: Double?
        var volume: Double?
    }

    /// Default brightness/volume for presets without per-monitor settings
    var defaultBrightness: Double?
    var defaultVolume: Double?

    init(name: String, icon: String, monitorSettings: [MonitorSetting] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.monitorSettings = monitorSettings
    }

    init(name: String, icon: String, defaultBrightness: Double, defaultVolume: Double) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.monitorSettings = []
        self.defaultBrightness = defaultBrightness
        self.defaultVolume = defaultVolume
    }
}

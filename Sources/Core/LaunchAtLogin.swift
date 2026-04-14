import ServiceManagement
import SwiftUI

/// Manages login item registration via SMAppService (macOS 13+).
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool {
        didSet { toggle(isEnabled) }
    }

    private init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    private func toggle(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[LaunchAtLogin] Failed: \(error.localizedDescription)")
            // Revert on failure
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}

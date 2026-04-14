import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        OnboardingWindowController.shared.showIfNeeded()
        registerGlobalShortcuts()
    }

    /// Register global keyboard shortcuts at app launch (not on panel appear).
    /// These work even when the app has no focus — true global hotkeys.
    private func registerGlobalShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .blackOut) {
            BlackOutService.shared.toggle()
        }

        KeyboardShortcuts.onKeyDown(for: .brightnessUp) {
            BlackOutService.shared.adjustBrightness(delta: 0.05)
        }

        KeyboardShortcuts.onKeyDown(for: .brightnessDown) {
            BlackOutService.shared.adjustBrightness(delta: -0.05)
        }

        KeyboardShortcuts.onKeyDown(for: .volumeUp) {
            BlackOutService.shared.adjustVolume(delta: 0.05)
        }

        KeyboardShortcuts.onKeyDown(for: .volumeDown) {
            BlackOutService.shared.adjustVolume(delta: -0.05)
        }
    }
}

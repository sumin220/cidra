import AppKit

final class OSDManager {
    static let shared = OSDManager()

    private var window: OSDOverlayWindow?

    private init() {}

    func show(type: OSDType, value: Double, screen: NSScreen? = nil) {
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let targetScreen else { return }

        if let existing = window {
            // Reuse existing window — update content and reset timer
            existing.update(type: type, value: value)
            existing.showOnScreen(targetScreen)
        } else {
            let w = OSDOverlayWindow(type: type, value: value)
            window = w
            w.showOnScreen(targetScreen)
        }
    }
}

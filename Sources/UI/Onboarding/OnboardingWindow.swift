import AppKit
import SwiftUI

final class OnboardingWindowController {
    private var window: NSWindow?

    static let shared = OnboardingWindowController()
    private init() {}

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    func showIfNeeded() {
        guard !Self.hasCompletedOnboarding else { return }
        show()
    }

    func show() {
        let onboardingView = OnboardingFlow {
            Self.hasCompletedOnboarding = true
            self.window?.close()
            self.window = nil
        }

        let hostingView = NSHostingView(rootView: onboardingView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 400),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

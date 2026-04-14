import KeyboardShortcuts
import AppKit

// MARK: - Shortcut Name Definitions

extension KeyboardShortcuts.Name {
    static let brightnessUp = Self("brightnessUp", default: .init(.f1))
    static let brightnessDown = Self("brightnessDown", default: .init(.f2))
    static let volumeUp = Self("volumeUp")
    static let volumeDown = Self("volumeDown")
    static let blackOut = Self("blackOut", default: .init(.b, modifiers: [.command, .shift]))
}

// MARK: - Shortcut Manager

/// Global shortcuts are registered in AppDelegate at launch.
/// This class is kept for MenuBarPanel compatibility (viewModel reference).
final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    private init() {}

    weak var viewModel: MenuBarViewModel?

    func start() {
        // Global shortcuts are now registered in AppDelegate.
        // This method is intentionally empty — kept for backward compatibility.
    }
}

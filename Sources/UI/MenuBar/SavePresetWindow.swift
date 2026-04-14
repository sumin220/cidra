import AppKit
import SwiftUI

final class SavePresetWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show(onSave: @escaping (String, String) -> Void) {
        // Always create fresh window so fields are reset
        window?.close()
        window = nil

        let view = SavePresetContent(
            onSave: { [weak self] name, icon in
                onSave(name, icon)
                DispatchQueue.main.async {
                    self?.window?.orderOut(nil)
                    self?.window = nil
                }
            },
            onCancel: { [weak self] in
                self?.window?.orderOut(nil)
                self?.window = nil
            }
        )

        let hosting = NSHostingView(rootView: view)
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 340),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.isReleasedWhenClosed = false
        win.contentView = hosting
        win.center()
        win.level = .floating
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

private struct SavePresetContent: View {
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    @State private var name = ""
    @State private var selectedIcon = "desktopcomputer"

    private let icons = [
        ("moon.fill", "Night"),
        ("desktopcomputer", "Work"),
        ("play.rectangle", "Cinema"),
        ("book", "Reading"),
        ("gamecontroller", "Gaming"),
        ("paintpalette", "Design"),
        ("music.note", "Music"),
        ("sun.max", "Bright"),
    ]

    var body: some View {
        VStack(spacing: 14) {
            Text("Save Preset")
                .font(.system(size: 14, weight: .semibold))

            TextField("Preset name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(icons, id: \.0) { icon, label in
                        VStack(spacing: 2) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                            Text(label)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedIcon == icon ? Color.accentColor.opacity(0.15) : Color(.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedIcon == icon ? Color.accentColor.opacity(0.4) : .clear, lineWidth: 1)
                        )
                        .onTapGesture { selectedIcon = icon }
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.controlBackgroundColor)))

                Button("Save") {
                    guard !name.isEmpty else { return }
                    onSave(name, selectedIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(name.isEmpty ? Color.gray : Color.accentColor))
                .disabled(name.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}

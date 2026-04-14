import SwiftUI

struct SavePresetSheet: View {
    let onSave: (String, String) -> Void
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
                Button("Cancel") {
                    DispatchQueue.main.async {
                        NSApp.keyWindow?.close()
                    }
                }
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

import SwiftUI

struct MenuBarPanel: View {
    @StateObject private var vm = MenuBarViewModel()
    @State private var isAddingPreset = false
    @State private var newPresetName = ""
    @State private var newPresetIcon = "desktopcomputer"

    private let presetIcons = [
        ("moon.fill", "Night"), ("desktopcomputer", "Work"),
        ("play.rectangle", "Cinema"), ("book", "Reading"),
        ("gamecontroller", "Gaming"), ("paintpalette", "Design"),
        ("music.note", "Music"), ("sun.max", "Bright"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Monitor controls
            ForEach(Array(vm.monitors.enumerated()), id: \.element.id) { index, monitor in
                if index > 0 {
                    SectionDivider()
                }
                MonitorControlCard(monitor: monitor)
            }

            // Ambient Light Sync
            SectionDivider()
            AmbientSyncRow()

            // Presets or inline add
            SectionDivider()
            if isAddingPreset {
                inlinePresetCreation
            } else {
                PresetSection(
                    presets: vm.presets,
                    activePresetID: vm.activePresetID,
                    isPro: true,
                    onSelect: { preset in vm.applyPreset(preset) },
                    onAdd: { isAddingPreset = true },
                    onDelete: { preset in vm.deletePreset(preset) }
                )
            }

            // Preferences
            SectionDivider()
            PreferencesButton(action: vm.openSettings)
        }
        .frame(width: 272)
        .fixedSize()
        .onAppear {
            KeyboardShortcutManager.shared.viewModel = vm
            KeyboardShortcutManager.shared.start()
            vm.syncWithHardware()
        }
    }

    private var inlinePresetCreation: some View {
        VStack(spacing: 8) {
            HStack {
                Text("NEW PRESET")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: cancelAddPreset) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            TextField("Name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 4) {
                ForEach(presetIcons, id: \.0) { icon, _ in
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(newPresetIcon == icon ? Color.accentColor.opacity(0.2) : .clear)
                        )
                        .onTapGesture { newPresetIcon = icon }
                }
            }

            Button(action: savePreset) {
                Text("Save")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 6).fill(newPresetName.isEmpty ? Color.gray : Color.accentColor))
            .disabled(newPresetName.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func savePreset() {
        guard !newPresetName.isEmpty else { return }
        vm.saveCurrentAsPreset(name: newPresetName, icon: newPresetIcon)
        cancelAddPreset()
    }

    private func cancelAddPreset() {
        isAddingPreset = false
        newPresetName = ""
        newPresetIcon = "desktopcomputer"
    }
}

struct SectionDivider: View {
    var body: some View {
        Divider()
            .frame(height: 0.5)
            .padding(.horizontal, 14)
    }
}

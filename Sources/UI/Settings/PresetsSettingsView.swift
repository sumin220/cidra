import SwiftUI

struct PresetsSettingsView: View {
    @ObservedObject private var triggerEngine = AutoTriggerEngine.shared
    @State private var selectedPreset: Preset?
    @State private var newTriggerType: AutoTriggerEngine.TriggerType = .time
    @State private var newTriggerValue = ""

    private var presets: [Preset] {
        PresetStore.shared.loadPresets()
    }

    var body: some View {
        Form {
            Section("Auto-Trigger Rules") {
                if triggerEngine.triggers.isEmpty {
                    Text("No triggers set. Add a rule to automatically switch presets based on time or app.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                ForEach(triggerEngine.triggers) { trigger in
                    HStack {
                        Image(systemName: trigger.type == .app ? "app" : "clock")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(presetName(for: trigger.presetID))
                                .font(.system(size: 12, weight: .medium))
                            Text(triggerDescription(trigger))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            triggerEngine.removeTrigger(id: trigger.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Add Trigger") {
                Picker("Preset", selection: $selectedPreset) {
                    Text("Select...").tag(nil as Preset?)
                    ForEach(presets) { preset in
                        Label(preset.name, systemImage: preset.icon).tag(preset as Preset?)
                    }
                }

                Picker("When", selection: $newTriggerType) {
                    ForEach(AutoTriggerEngine.TriggerType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                if newTriggerType == .time {
                    TextField("Time (HH:mm)", text: $newTriggerValue)
                        .font(.system(size: 12))
                } else {
                    TextField("App Bundle ID (e.g. com.netflix.Netflix)", text: $newTriggerValue)
                        .font(.system(size: 12))
                }

                Button("Add") {
                    guard let preset = selectedPreset, !newTriggerValue.isEmpty else { return }
                    let trigger = AutoTriggerEngine.Trigger(
                        presetID: preset.id,
                        type: newTriggerType,
                        value: newTriggerValue
                    )
                    triggerEngine.addTrigger(trigger)
                    newTriggerValue = ""
                    selectedPreset = nil
                }
                .disabled(selectedPreset == nil || newTriggerValue.isEmpty)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Presets")
    }

    private func presetName(for id: UUID) -> String {
        presets.first { $0.id == id }?.name ?? "Unknown"
    }

    private func triggerDescription(_ trigger: AutoTriggerEngine.Trigger) -> String {
        switch trigger.type {
        case .app: "When \(trigger.value) launches"
        case .time: "At \(trigger.value) every day"
        }
    }
}

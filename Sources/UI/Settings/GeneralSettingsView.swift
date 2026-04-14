import SwiftUI
import KeyboardShortcuts

struct GeneralSettingsView: View {
    @ObservedObject private var loginManager = LaunchAtLoginManager.shared
    @AppStorage("checkForUpdates") private var checkForUpdates = true
    @AppStorage("showAdvancedOptions") private var showAdvanced = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $loginManager.isEnabled) {
                    Label("Launch at login", systemImage: "arrow.right.square")
                }
            }

            Section("Keyboard Shortcuts") {
                HStack {
                    Label("Brightness up", systemImage: "sun.max")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .brightnessUp)
                }
                HStack {
                    Label("Brightness down", systemImage: "sun.min")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .brightnessDown)
                }
                HStack {
                    Label("Volume up", systemImage: "speaker.wave.3")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .volumeUp)
                }
                HStack {
                    Label("Volume down", systemImage: "speaker")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .volumeDown)
                }
                HStack {
                    Label("BlackOut", systemImage: "power.circle")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .blackOut)
                }
            }

            Section {
                Toggle(isOn: $checkForUpdates) {
                    Label("Check for updates", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section {
                Toggle(isOn: $showAdvanced) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show advanced options")
                            .foregroundStyle(Color.accentColor)
                        Text("Color mode, refresh rate, custom resolution")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if showAdvanced {
                AdvancedOptionsSection()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

// MARK: - Advanced Options

struct AdvancedOptionsSection: View {
    @State private var colorMode = "RGB"
    @State private var refreshRate = "100Hz"
    @State private var inputSource = "DisplayPort"

    private let colorModes = ["RGB", "YCbCr 4:4:4", "YCbCr 4:2:2"]
    private let refreshRates = ["60Hz", "100Hz", "144Hz"]
    private let inputSources = ["HDMI", "DisplayPort", "USB-C"]

    var body: some View {
        Section("Advanced") {
            Picker("Color mode", selection: $colorMode) {
                ForEach(colorModes, id: \.self) { Text($0) }
            }
            Picker("Refresh rate", selection: $refreshRate) {
                ForEach(refreshRates, id: \.self) { Text($0) }
            }
            Picker("Input source", selection: $inputSource) {
                ForEach(inputSources, id: \.self) { Text($0) }
            }
        }
    }
}

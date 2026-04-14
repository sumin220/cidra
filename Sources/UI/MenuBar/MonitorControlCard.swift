import SwiftUI

struct MonitorControlCard: View {
    @ObservedObject var monitor: MonitorState
    @State private var isSharpeningOn = false
    @State private var sharpeningInitialized = false
    @State private var isBlackedOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Monitor name
            HStack(spacing: 6) {
                Image(systemName: monitor.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(monitor.name)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(-0.1)
            }

            // BlackOut button (external monitors only)
            if !monitor.isBuiltIn {
                Button(action: toggleBlackOut) {
                    HStack(spacing: 6) {
                        Image(systemName: isBlackedOut ? "power.circle.fill" : "power.circle")
                            .font(.system(size: 13))
                        Text(isBlackedOut ? "Turn On" : "Display Off")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text("\u{2318}\u{21E7}B")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isBlackedOut ? Color.red.opacity(0.15) : Color(.controlBackgroundColor).opacity(0.5))
                    )
                    .foregroundStyle(isBlackedOut ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }

            // Brightness slider (extended range: dimming below 0, XDR above 1)
            SliderRow(
                leftIcon: "sun.min",
                rightIcon: "sun.max",
                value: $monitor.brightness,
                range: monitor.isBuiltIn ? -0.5...1.5 : -0.5...1.0,
                onChange: monitor.setBrightness
            )

            // Volume slider (external monitors only)
            if !monitor.isBuiltIn {
                SliderRow(
                    leftIcon: "speaker",
                    rightIcon: "speaker.wave.3",
                    value: $monitor.volume,
                    onChange: monitor.setVolume
                )

                // Sharpening toggle — HiDPI mode switch
                HStack {
                    Text("Sharpening")
                        .font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: $isSharpeningOn)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                        .onChange(of: isSharpeningOn) { _, enabled in
                            guard sharpeningInitialized else { return }
                            let switcher = DisplayModeSwitch.shared
                            if enabled {
                                if !switcher.enableHiDPI(displayID: monitor.cgDisplayID) {
                                    isSharpeningOn = false
                                }
                            } else {
                                if !switcher.disableHiDPI(displayID: monitor.cgDisplayID) {
                                    isSharpeningOn = true
                                }
                            }
                        }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onAppear {
            if !monitor.isBuiltIn && !sharpeningInitialized {
                isSharpeningOn = DisplayModeSwitch.shared.isHiDPIActive(displayID: monitor.cgDisplayID)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    sharpeningInitialized = true
                }
            }
        }
    }

    private func toggleBlackOut() {
        BlackOutService.shared.toggle()
        isBlackedOut = BlackOutService.shared.isBlackedOut
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let leftIcon: String
    let rightIcon: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    let onChange: (Double) -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: leftIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: rightIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
            }
            CapsuleSlider(value: $value, range: range, onChange: onChange)
        }
    }
}

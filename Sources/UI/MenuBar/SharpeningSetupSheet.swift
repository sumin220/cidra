import SwiftUI

struct SharpeningSetupSheet: View {
    let monitorName: String
    let vendorID: UInt32
    let productID: UInt32
    let physicalWidth: Int
    let physicalHeight: Int
    let isInstalled: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var resultMessage = ""
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "textformat.abc.dottedunderline")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentColor)

            Text("Text Sharpening")
                .font(.system(size: 15, weight: .semibold))

            if isInstalled {
                Text("Sharpening is set up for \(monitorName).\nRemove to revert to default rendering.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Enable HiDPI rendering for sharper text on \(monitorName). A one-time reboot is required.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Show what will happen
                let nearNative = DisplayOverrideManager.shared.nearNativeResolution(
                    physicalWidth: physicalWidth, physicalHeight: physicalHeight)
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text("Renders at \(nearNative.backingWidth)x\(nearNative.backingHeight), scaled to native. No visible resolution change.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(.controlBackgroundColor)))
            }

            if showResult {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(resultMessage)
                        .font(.system(size: 11))
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 6).fill(.green.opacity(0.1)))

                Button("Reboot Now") { reboot() }
                    .buttonStyle(.borderedProminent)

                Button("Later") { dismiss() }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            } else {
                Button(action: performAction) {
                    if isProcessing {
                        ProgressView().controlSize(.small).frame(maxWidth: .infinity)
                    } else {
                        Text(isInstalled ? "Remove Sharpening" : "Enable Sharpening")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 6).fill(isInstalled ? .red : Color.accentColor))
                .disabled(isProcessing)

                Button("Cancel") { dismiss() }
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(width: 280)
    }

    private func performAction() {
        isProcessing = true
        let mgr = DisplayOverrideManager.shared

        if isInstalled {
            mgr.uninstall(vendorID: vendorID, productID: productID) { success, message in
                isProcessing = false
                if success {
                    resultMessage = "Removed. Reboot to apply."
                    showResult = true
                }
            }
        } else {
            let resolutions = mgr.recommendedResolutions(physicalWidth: physicalWidth, physicalHeight: physicalHeight)
            mgr.install(vendorID: vendorID, productID: productID, resolutions: resolutions) { success, message in
                isProcessing = false
                if success {
                    resultMessage = "Enabled. Reboot to apply."
                    showResult = true
                }
            }
        }
    }

    private func reboot() {
        // System confirmation before rebooting to prevent accidental data loss
        let alert = NSAlert()
        alert.messageText = "Restart your Mac?"
        alert.informativeText = "Save your work before restarting. HiDPI settings will take effect after restart."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Later")
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to restart"]
        try? process.run()
    }
}

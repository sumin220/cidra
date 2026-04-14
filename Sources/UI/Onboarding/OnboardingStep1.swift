import SwiftUI

struct OnboardingStep1: View {
    let monitorName: String
    let resolution: String
    let onApply: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Step indicator
            Text("STEP 1")
                .font(.system(size: 10, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Monitor icon
            Image(systemName: "display")
                .font(.system(size: 32))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 32)

            // Monitor info
            VStack(spacing: 4) {
                Text("\(monitorName) detected")
                    .font(.system(size: 14, weight: .semibold))
                Text(resolution)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Sharpening recommendation card
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable text sharpening?")
                        .font(.system(size: 11, weight: .medium))
                    Text("Makes text clearer and sharper on your external display.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )

            // Buttons
            HStack(spacing: 10) {
                Button(action: onLater) {
                    Text("Later")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.controlBackgroundColor))
                )

                Button(action: onApply) {
                    Text("Apply")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
}

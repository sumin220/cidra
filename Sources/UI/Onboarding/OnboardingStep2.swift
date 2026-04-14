import SwiftUI

struct OnboardingStep2: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Step indicator
            Text("STEP 2")
                .font(.system(size: 10, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Checkmark icon
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28))
                .foregroundStyle(.green)

            // Title + description
            VStack(spacing: 6) {
                Text("Ready")
                    .font(.system(size: 14, weight: .semibold))
                Text("Use the menu bar icon to adjust brightness and volume.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Get started button
            Button(action: onGetStarted) {
                Text("Get started")
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
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
}

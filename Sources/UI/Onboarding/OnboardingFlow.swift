import SwiftUI

struct OnboardingFlow: View {
    let onComplete: () -> Void

    @State private var step: Int = 1
    // Stub monitor info — will be replaced by real detection later
    private let monitorName = "S34CG50"
    private let resolution = "3440 x 1440 · 100 Hz"

    var body: some View {
        VStack(spacing: 0) {
            if step == 1 {
                OnboardingStep1(
                    monitorName: monitorName,
                    resolution: resolution,
                    onApply: { advanceToStep2() },
                    onLater: { advanceToStep2() }
                )
                .transition(.opacity)
            } else {
                OnboardingStep2(onGetStarted: onComplete)
                    .transition(.opacity)
            }
        }
        .frame(width: 280)
        .fixedSize(horizontal: true, vertical: true)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private func advanceToStep2() {
        step = 2
    }
}

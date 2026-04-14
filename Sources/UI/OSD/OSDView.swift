import SwiftUI

struct OSDView: View {
    let type: OSDType
    let value: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 20)

            // Progress track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 4)

                    // Filled track
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * min(max(value, 0), 1), height: 4)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 200, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.65))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
}

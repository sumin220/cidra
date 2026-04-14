import SwiftUI

struct CapsuleSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    let onChange: (Double) -> Void

    @State private var isDragging = false

    /// Normalized position (0~1) within the slider track
    private var normalizedValue: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (value - range.lowerBound) / span
    }

    /// Where the "zero point" sits on the track (for visual reference)
    private var zeroPosition: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (0 - range.lowerBound) / span
    }

    /// Whether the slider has extended range (dimming or XDR)
    private var isExtended: Bool {
        range.lowerBound < 0 || range.upperBound > 1
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color(.controlBackgroundColor).opacity(0.5))

                // Filled track
                Capsule()
                    .fill(fillColor)
                    .frame(width: max(22, geo.size.width * normalizedValue))
            }
            .frame(height: 22)
            .clipShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let normalized = min(max(drag.location.x / geo.size.width, 0), 1)
                        let newValue = range.lowerBound + normalized * (range.upperBound - range.lowerBound)
                        value = newValue
                        onChange(newValue)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .animation(.easeOut(duration: 0.1), value: value)
        }
        .frame(height: 22)
    }

    private var fillColor: Color {
        if value < 0 {
            // Dimming region — orange tint
            return Color.orange.opacity(isDragging ? 0.9 : 0.8)
        } else if value > 1 {
            // XDR region — yellow tint
            return Color.yellow.opacity(isDragging ? 0.9 : 0.8)
        } else {
            return Color(.labelColor).opacity(isDragging ? 0.95 : 0.85)
        }
    }
}

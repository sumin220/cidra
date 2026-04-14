import SwiftUI

struct AmbientSyncRow: View {
    @ObservedObject private var sync = AmbientLightSync.shared

    var body: some View {
        HStack {
            Image(systemName: "sun.and.horizon")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("Ambient Sync")
                .font(.system(size: 12))
            Spacer()
            Toggle("", isOn: $sync.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

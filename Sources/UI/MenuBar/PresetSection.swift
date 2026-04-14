import SwiftUI

struct PresetSection: View {
    let presets: [Preset]
    let activePresetID: UUID?
    let isPro: Bool
    let onSelect: (Preset) -> Void
    var onAdd: (() -> Void)? = nil
    var onDelete: ((Preset) -> Void)? = nil

    @State private var deletingPresetID: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRESETS")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(.secondary)
                Spacer()
                if !isPro {
                    ProBadge()
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(presets) { preset in
                        PresetCard(
                            preset: preset,
                            isActive: preset.id == activePresetID,
                            isPro: isPro,
                            isConfirmingDelete: deletingPresetID == preset.id,
                            onXTap: { deletingPresetID = preset.id },
                            onConfirmDelete: {
                                onDelete?(preset)
                                deletingPresetID = nil
                            }
                        )
                        .onTapGesture {
                            if deletingPresetID != nil {
                                deletingPresetID = nil
                            } else {
                                onSelect(preset)
                            }
                        }
                    }

                    if isPro {
                        AddPresetCard()
                            .onTapGesture {
                                deletingPresetID = nil
                                onAdd?()
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .opacity(isPro ? 1.0 : 0.3)
        .contentShape(Rectangle())
        .onTapGesture {
            deletingPresetID = nil
        }
    }
}

struct PresetCard: View {
    let preset: Preset
    let isActive: Bool
    let isPro: Bool
    var isConfirmingDelete: Bool = false
    var onXTap: (() -> Void)? = nil
    var onConfirmDelete: (() -> Void)? = nil

    var body: some View {
        if isConfirmingDelete {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                Text("Delete?")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.red)
            }
            .frame(width: 56, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .onTapGesture { onConfirmDelete?() }
        } else {
            VStack(spacing: 4) {
                Image(systemName: preset.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? Color.accentColor : .primary)
                Text(preset.name)
                    .font(.system(size: 9))
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)
            }
            .frame(width: 56, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor.opacity(0.12) : Color(.controlBackgroundColor).opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if isPro, onXTap != nil {
                    Button(action: { onXTap?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(3)
                }
            }
        }
    }
}

struct AddPresetCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text("New")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(width: 56, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.15))
            )
    }
}

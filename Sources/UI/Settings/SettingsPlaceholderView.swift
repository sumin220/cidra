import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case presets = "Presets"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .presets: "slider.horizontal.3"
        }
    }
}

struct SettingsRootView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(130)
        } detail: {
            switch selectedTab {
            case .general:
                GeneralSettingsView()
            case .presets:
                PresetsSettingsView()
            }
        }
        .frame(width: 580, height: 400)
    }
}

// Kept for backwards compatibility with CidraApp.swift Settings scene
struct SettingsPlaceholderView: View {
    var body: some View {
        SettingsRootView()
    }
}

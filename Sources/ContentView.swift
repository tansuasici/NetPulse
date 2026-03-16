import SwiftUI

enum Tab: String, CaseIterable {
    case dashboard = "Speed"
    case history = "History"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "bolt.fill"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var historyStore: HistoryStore
    @StateObject private var speedTest = SpeedTestService()
    @State private var activeTab: Tab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control
            Picker("", selection: $activeTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            // Content
            switch activeTab {
            case .dashboard:
                DashboardView(
                    monitor: monitor,
                    speedTest: speedTest,
                    historyStore: historyStore
                )
            case .history:
                HistoryView(historyStore: historyStore)
            case .settings:
                SettingsView()
            }
        }
        .frame(width: 340, height: 460)
    }
}

import SwiftUI

enum Tab: String, CaseIterable {
    case dashboard = "Speed"
    case history = "History"
    case settings = "Settings"
}

struct ContentView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var historyStore: HistoryStore
    @StateObject private var speedTest = SpeedTestService()
    @State private var activeTab: Tab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            HStack(spacing: 2) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { activeTab = tab } }) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundColor(activeTab == tab ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                activeTab == tab
                                    ? RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08))
                                    : nil
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

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
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

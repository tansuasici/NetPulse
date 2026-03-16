import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore

    var body: some View {
        VStack(spacing: 0) {
            if historyStore.entries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(historyStore.entries) { entry in
                        historyRow(entry)
                    }
                }
                .listStyle(.inset)

                Divider()

                HStack {
                    Spacer()
                    Button(role: .destructive, action: { historyStore.clearHistory() }) {
                        Label("Clear History", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .padding(8)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No test results yet")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("Run a speed test from the Speed tab")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func historyRow(_ entry: SpeedTestResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                statBadge(icon: "arrow.down", value: entry.downloadMbps, unit: "Mbps", color: .green)
                statBadge(icon: "arrow.up", value: entry.uploadMbps, unit: "Mbps", color: .blue)
                statBadge(icon: "timer", value: entry.pingMs, unit: "ms", color: .orange)
            }
        }
        .padding(.vertical, 2)
    }

    private func statBadge(icon: String, value: Double, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
            Text(String(format: unit == "ms" ? "%.0f" : "%.1f", value))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
            Text(unit)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

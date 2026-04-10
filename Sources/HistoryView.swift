import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore

    var body: some View {
        VStack(spacing: 0) {
            if historyStore.entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(historyStore.entries) { entry in
                            historyRow(entry)
                            Rectangle().fill(Color.primary.opacity(0.05)).frame(height: 1)
                        }
                    }
                }
                .frame(maxHeight: 260)

                Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)

                Button(role: .destructive, action: { historyStore.clearHistory() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                        Text("Clear")
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 20))
                .foregroundColor(.secondary.opacity(0.3))
            Text("No results yet")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private func historyRow(_ entry: SpeedTestResult) -> some View {
        HStack(spacing: 0) {
            // Date
            Text(entry.formattedDate)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .frame(width: 62, alignment: .leading)

            Spacer(minLength: 4)

            // Stats inline
            HStack(spacing: 8) {
                statValue(value: entry.downloadMbps, color: .green)
                statValue(value: entry.uploadMbps, color: .blue)
                statValue(value: entry.pingMs, color: .orange, format: "%.0f ms")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func statValue(value: Double, color: Color, format: String = "%.0f") -> some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 4, height: 4)
            Text(String(format: format, value))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
    }
}

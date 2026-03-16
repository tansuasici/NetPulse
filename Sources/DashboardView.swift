import SwiftUI

struct DashboardView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var speedTest: SpeedTestService
    @ObservedObject var historyStore: HistoryStore

    var body: some View {
        VStack(spacing: 14) {
            // Live Monitor
            GroupBox {
                HStack {
                    liveItem(
                        icon: "arrow.down.circle.fill",
                        color: .green,
                        value: NetworkStats.formatFull(monitor.currentStats.downloadBytesPerSec)
                    )
                    Spacer()
                    Divider().frame(height: 28)
                    Spacer()
                    liveItem(
                        icon: "arrow.up.circle.fill",
                        color: .blue,
                        value: NetworkStats.formatFull(monitor.currentStats.uploadBytesPerSec)
                    )
                }
                .padding(.vertical, 2)
            } label: {
                Label("Live Traffic", systemImage: "network")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Speed Test Results / Indicator
            if let result = speedTest.lastResult {
                testResultsView(result)
            } else if speedTest.isRunning {
                testingView
            } else {
                idleView
            }

            Spacer(minLength: 0)

            // Action button
            Button(action: { speedTest.runTest(historyStore: historyStore) }) {
                Label(
                    speedTest.isRunning ? "Testing..." :
                    speedTest.lastResult != nil ? "Test Again" : "Start Speed Test",
                    systemImage: speedTest.isRunning ? "hourglass" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(speedTest.isRunning)
        }
        .padding(12)
    }

    private func liveItem(icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .frame(minWidth: 80, alignment: .leading)
        }
    }

    // MARK: - Results

    private func testResultsView(_ result: SpeedTestResult) -> some View {
        GroupBox {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    SpeedGaugeView(
                        value: result.downloadMbps,
                        maxValue: max(result.downloadMbps * 1.3, 100),
                        label: "Download",
                        color: .green
                    )
                    SpeedGaugeView(
                        value: result.uploadMbps,
                        maxValue: max(result.uploadMbps * 1.3, 100),
                        label: "Upload",
                        color: .blue
                    )
                }

                Divider()

                HStack {
                    Label("Ping", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f ms", result.pingMs))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
            }
        } label: {
            Label("Speed Test Result", systemImage: "gauge.with.dots.needle.67percent")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Testing

    private var testingView: some View {
        GroupBox {
            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text(phaseLabel)
                    .font(.callout)
                    .foregroundColor(.secondary)

                if speedTest.currentValue > 0 {
                    Text(String(format: "%.1f Mbps", speedTest.currentValue))
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private var phaseLabel: String {
        switch speedTest.phase {
        case "ping": return "Measuring ping..."
        case "download": return "Testing download..."
        case "upload": return "Testing upload..."
        default: return "Starting..."
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        GroupBox {
            VStack(spacing: 6) {
                Image(systemName: "speedometer")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("Test your internet speed")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

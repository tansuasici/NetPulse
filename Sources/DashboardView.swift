import SwiftUI

struct DashboardView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var speedTest: SpeedTestService
    @ObservedObject var historyStore: HistoryStore

    var body: some View {
        VStack(spacing: 0) {
            // Live traffic - compact inline
            HStack(spacing: 0) {
                liveItem(
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    value: NetworkStats.formatFull(monitor.currentStats.downloadBytesPerSec)
                )
                Spacer()
                liveItem(
                    icon: "arrow.up.circle.fill",
                    color: .blue,
                    value: NetworkStats.formatFull(monitor.currentStats.uploadBytesPerSec)
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))

            Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)

            // Error banner
            if let error = speedTest.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 10))
                        .lineLimit(1)
                    Spacer()
                    Button { speedTest.errorMessage = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))

                Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)
            }

            // Main content area
            if let result = speedTest.lastResult {
                testResultsView(result)
            } else if speedTest.isRunning {
                testingView
            } else {
                idleView
            }

            Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1)

            // Action button - flush bottom
            Button(action: {
                speedTest.lastResult = nil
                speedTest.runTest(historyStore: historyStore)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: speedTest.isRunning ? "hourglass" : "play.fill")
                        .font(.system(size: 9))
                    Text(
                        speedTest.isRunning ? "Testing..." :
                        speedTest.lastResult != nil ? "Test Again" : "Start Speed Test"
                    )
                    .font(.system(size: 11, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .disabled(speedTest.isRunning)
            .opacity(speedTest.isRunning ? 0.5 : 1)
        }
    }

    // MARK: - Live item

    private func liveItem(icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }

    // MARK: - Results

    private func testResultsView(_ result: SpeedTestResult) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                resultMetric(value: result.downloadMbps, unit: "Mbps", label: "Download", color: .green)
                Rectangle().fill(Color.primary.opacity(0.06)).frame(width: 1)
                resultMetric(value: result.uploadMbps, unit: "Mbps", label: "Upload", color: .blue)
                Rectangle().fill(Color.primary.opacity(0.06)).frame(width: 1)
                resultMetric(value: result.pingMs, unit: "ms", label: "Ping", color: .orange, format: "%.0f")
            }
        }
    }

    private func resultMetric(value: Double, unit: String, label: String, color: Color, format: String = "%.1f") -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: format, value))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Testing

    private var testingView: some View {
        VStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)

            Text(phaseLabel)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            if speedTest.currentValue > 0 {
                Text(String(format: "%.1f Mbps", speedTest.currentValue))
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var phaseLabel: String {
        switch speedTest.phase {
        case "latency": return "Measuring latency..."
        case "download": return "Testing download..."
        case "upload": return "Testing upload..."
        default: return "Starting..."
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 4) {
            Image(systemName: "speedometer")
                .font(.system(size: 20))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Test your internet speed")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

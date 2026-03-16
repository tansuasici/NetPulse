import Foundation

class SpeedTestService: ObservableObject {
    @Published var isRunning = false
    @Published var phase: String = ""
    @Published var currentValue: Double = 0
    @Published var lastResult: SpeedTestResult?

    private let downURL = "https://speed.cloudflare.com/__down"
    private let upURL = "https://speed.cloudflare.com/__up"

    func runTest(historyStore: HistoryStore) {
        guard !isRunning else { return }

        DispatchQueue.main.async {
            self.isRunning = true
            self.phase = "ping"
            self.currentValue = 0
        }

        Task {
            do {
                // Ping
                let ping = try await measurePing()
                await MainActor.run {
                    self.currentValue = ping
                    self.phase = "download"
                }

                // Download
                let download = try await measureDownload()
                await MainActor.run {
                    self.currentValue = download
                    self.phase = "upload"
                }

                // Upload
                let upload = try await measureUpload()

                let result = historyStore.save(
                    download: round(download * 100) / 100,
                    upload: round(upload * 100) / 100,
                    ping: round(ping * 100) / 100
                )

                await MainActor.run {
                    self.lastResult = result
                    self.isRunning = false
                    self.phase = ""
                }
            } catch {
                await MainActor.run {
                    self.isRunning = false
                    self.phase = ""
                }
            }
        }
    }

    private func measurePing() async throws -> Double {
        var pings: [Double] = []

        for _ in 0..<5 {
            let start = CFAbsoluteTimeGetCurrent()
            let url = URL(string: "\(downURL)?bytes=0")!
            let _ = try await URLSession.shared.data(from: url)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            pings.append(elapsed)
        }

        pings.sort()
        return pings[pings.count / 2]
    }

    private func measureDownload() async throws -> Double {
        let sizes: [Int] = [100_000, 500_000, 1_000_000, 5_000_000, 10_000_000, 25_000_000]
        var speeds: [Double] = []

        for size in sizes {
            let url = URL(string: "\(downURL)?bytes=\(size)")!
            let start = CFAbsoluteTimeGetCurrent()
            let (data, _) = try await URLSession.shared.data(from: url)
            let elapsed = CFAbsoluteTimeGetCurrent() - start

            if elapsed > 0 {
                let mbps = Double(data.count) * 8.0 / (elapsed * 1_000_000)
                speeds.append(mbps)

                await MainActor.run {
                    self.currentValue = mbps
                }
            }

            if elapsed > 5 { break }
        }

        guard !speeds.isEmpty else { return 0 }
        speeds.sort()
        let idx = min(Int(ceil(Double(speeds.count) * 0.9)) - 1, speeds.count - 1)
        return speeds[idx]
    }

    private func measureUpload() async throws -> Double {
        let sizes: [Int] = [100_000, 500_000, 1_000_000, 5_000_000, 10_000_000]
        var speeds: [Double] = []

        for size in sizes {
            let url = URL(string: upURL)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = Data(count: size)

            let start = CFAbsoluteTimeGetCurrent()
            let _ = try await URLSession.shared.data(for: request)
            let elapsed = CFAbsoluteTimeGetCurrent() - start

            if elapsed > 0 {
                let mbps = Double(size) * 8.0 / (elapsed * 1_000_000)
                speeds.append(mbps)

                await MainActor.run {
                    self.currentValue = mbps
                }
            }

            if elapsed > 5 { break }
        }

        guard !speeds.isEmpty else { return 0 }
        speeds.sort()
        let idx = min(Int(ceil(Double(speeds.count) * 0.9)) - 1, speeds.count - 1)
        return speeds[idx]
    }
}

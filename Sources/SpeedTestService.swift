import Foundation

class SpeedTestService: ObservableObject {
    @Published var isRunning = false
    @Published var phase: String = ""
    @Published var currentValue: Double = 0
    @Published var lastResult: SpeedTestResult?
    @Published var errorMessage: String?

    private let downURL = "https://speed.cloudflare.com/__down"
    private let upURL = "https://speed.cloudflare.com/__up"

    /// Atomic flag to prevent concurrent test runs
    private let runLock = NSLock()
    private var isRunningInternal = false

    /// Ephemeral session: no cache, no cookies, no keep-alive reuse
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        config.httpShouldSetCookies = false
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    func runTest(historyStore: HistoryStore) {
        // Atomic check-and-set to prevent race condition
        runLock.lock()
        if isRunningInternal {
            runLock.unlock()
            return
        }
        isRunningInternal = true
        runLock.unlock()

        DispatchQueue.main.async {
            self.isRunning = true
            self.phase = "latency"
            self.currentValue = 0
            self.errorMessage = nil
        }

        Task {
            defer {
                self.runLock.lock()
                self.isRunningInternal = false
                self.runLock.unlock()
            }

            do {
                // Warm up: establish TLS before measuring latency
                let warmupURL = URL(string: "\(downURL)?bytes=0")!
                _ = try await session.data(from: warmupURL)

                let latency = try await measureLatency()
                await MainActor.run {
                    self.currentValue = latency
                    self.phase = "download"
                }

                let download = try await measureDownload()
                await MainActor.run {
                    self.currentValue = download
                    self.phase = "upload"
                }

                let upload = try await measureUpload()

                let result = historyStore.save(
                    download: round(download * 100) / 100,
                    upload: round(upload * 100) / 100,
                    ping: round(latency * 100) / 100
                )

                await MainActor.run {
                    if let result = result {
                        self.lastResult = result
                    } else {
                        self.errorMessage = "Failed to save result"
                    }
                    self.isRunning = false
                    self.phase = ""
                }
            } catch {
                await MainActor.run {
                    self.isRunning = false
                    self.phase = ""
                    self.errorMessage = Self.friendlyError(error)
                }
            }
        }
    }

    /// Measures HTTP round-trip latency (not ICMP ping).
    /// TLS handshake is excluded via warmup request.
    private func measureLatency() async throws -> Double {
        var times: [Double] = []

        for _ in 0..<5 {
            let url = URL(string: "\(downURL)?bytes=0")!
            let start = CFAbsoluteTimeGetCurrent()
            let _ = try await session.data(from: url)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            times.append(elapsed)
        }

        times.sort()
        return times[times.count / 2]
    }

    private func measureDownload() async throws -> Double {
        let sizes: [Int] = [100_000, 500_000, 1_000_000, 5_000_000, 10_000_000, 25_000_000]
        var speeds: [Double] = []

        for size in sizes {
            let url = URL(string: "\(downURL)?bytes=\(size)")!
            let start = CFAbsoluteTimeGetCurrent()
            let (data, _) = try await session.data(from: url)
            let elapsed = CFAbsoluteTimeGetCurrent() - start

            if elapsed > 0 {
                let mbps = Double(data.count) * 8.0 / (elapsed * 1_000_000)
                speeds.append(mbps)

                await MainActor.run { self.currentValue = mbps }
            }

            if elapsed > 5 { break }
        }

        guard !speeds.isEmpty else {
            throw SpeedTestError.noMeasurement("Download measurement failed")
        }
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
            let _ = try await session.data(for: request)
            let elapsed = CFAbsoluteTimeGetCurrent() - start

            if elapsed > 0 {
                let mbps = Double(size) * 8.0 / (elapsed * 1_000_000)
                speeds.append(mbps)

                await MainActor.run { self.currentValue = mbps }
            }

            if elapsed > 5 { break }
        }

        guard !speeds.isEmpty else {
            throw SpeedTestError.noMeasurement("Upload measurement failed")
        }
        speeds.sort()
        let idx = min(Int(ceil(Double(speeds.count) * 0.9)) - 1, speeds.count - 1)
        return speeds[idx]
    }

    private static func friendlyError(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet: return "No internet connection"
            case .timedOut: return "Connection timed out"
            case .cannotFindHost, .cannotConnectToHost: return "Cannot reach speed test server"
            default: return "Network error: \(urlError.localizedDescription)"
            }
        }
        if let stError = error as? SpeedTestError {
            switch stError {
            case .noMeasurement(let msg): return msg
            }
        }
        return "Test failed: \(error.localizedDescription)"
    }
}

enum SpeedTestError: Error {
    case noMeasurement(String)
}

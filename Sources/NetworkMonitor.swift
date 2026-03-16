import Foundation
import Darwin

class NetworkMonitor: ObservableObject {
    @Published var currentStats = NetworkStats()

    private var timer: Timer?
    private var lastRx: UInt64 = 0
    private var lastTx: UInt64 = 0
    private var isFirstRead = true

    func start() {
        let (rx, tx) = Self.getNetworkBytes()
        lastRx = rx
        lastTx = tx

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func update() {
        let (rx, tx) = Self.getNetworkBytes()

        if isFirstRead {
            isFirstRead = false
            lastRx = rx
            lastTx = tx
            return
        }

        let deltaRx = rx >= lastRx ? rx - lastRx : rx
        let deltaTx = tx >= lastTx ? tx - lastTx : tx

        DispatchQueue.main.async {
            self.currentStats.downloadBytesPerSec = Double(deltaRx)
            self.currentStats.uploadBytesPerSec = Double(deltaTx)
        }

        lastRx = rx
        lastTx = tx
    }

    static func getNetworkBytes() -> (rx: UInt64, tx: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if isUp && !isLoopback {
                if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = current.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self)
                        totalRx += UInt64(networkData.pointee.ifi_ibytes)
                        totalTx += UInt64(networkData.pointee.ifi_obytes)
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }

        return (totalRx, totalTx)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

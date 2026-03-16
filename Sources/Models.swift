import Foundation

struct NetworkStats {
    var downloadBytesPerSec: Double = 0
    var uploadBytesPerSec: Double = 0

    var trayText: String {
        "↓\(Self.formatShort(downloadBytesPerSec)) ↑\(Self.formatShort(uploadBytesPerSec))"
    }

    static func formatShort(_ bytesPerSec: Double) -> String {
        let bits = bytesPerSec * 8
        let raw: String
        if bits >= 1_000_000_000 {
            raw = String(format: "%.1fG", bits / 1_000_000_000)
        } else if bits >= 1_000_000 {
            raw = String(format: "%.1fM", bits / 1_000_000)
        } else if bits >= 1_000 {
            raw = String(format: "%.0fK", bits / 1_000)
        } else {
            raw = "0K"
        }
        // Pad to 6 chars so the menu bar doesn't jump around
        return raw.count < 6 ? String(repeating: " ", count: 6 - raw.count) + raw : raw
    }

    static func formatFull(_ bytesPerSec: Double) -> String {
        let bits = bytesPerSec * 8
        if bits >= 1_000_000_000 {
            return String(format: "%.1f Gbps", bits / 1_000_000_000)
        } else if bits >= 1_000_000 {
            return String(format: "%.1f Mbps", bits / 1_000_000)
        } else if bits >= 1_000 {
            return String(format: "%.0f Kbps", bits / 1_000)
        }
        return "0 Kbps"
    }
}

struct SpeedTestResult: Identifiable {
    let id: Int64
    let downloadMbps: Double
    let uploadMbps: Double
    let pingMs: Double
    let timestamp: Date

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: timestamp)
    }
}

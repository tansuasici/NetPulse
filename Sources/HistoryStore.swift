import Foundation
import SQLite3

class HistoryStore: ObservableObject {
    @Published var entries: [SpeedTestResult] = []

    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NetPulse")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        dbPath = dir.appendingPathComponent("history.db").path

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            let sql = """
                CREATE TABLE IF NOT EXISTS speed_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    download_mbps REAL NOT NULL,
                    upload_mbps REAL NOT NULL,
                    ping_ms REAL NOT NULL,
                    timestamp REAL NOT NULL
                )
            """
            sqlite3_exec(db, sql, nil, nil, nil)
        }

        loadEntries()
    }

    deinit {
        sqlite3_close(db)
    }

    @discardableResult
    func save(download: Double, upload: Double, ping: Double) -> SpeedTestResult {
        let now = Date()
        let sql = "INSERT INTO speed_history (download_mbps, upload_mbps, ping_ms, timestamp) VALUES (?, ?, ?, ?)"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_double(stmt, 1, download)
            sqlite3_bind_double(stmt, 2, upload)
            sqlite3_bind_double(stmt, 3, ping)
            sqlite3_bind_double(stmt, 4, now.timeIntervalSince1970)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)

        let rowId = sqlite3_last_insert_rowid(db)
        let result = SpeedTestResult(
            id: rowId,
            downloadMbps: download,
            uploadMbps: upload,
            pingMs: ping,
            timestamp: now
        )

        DispatchQueue.main.async {
            self.entries.insert(result, at: 0)
        }

        return result
    }

    func loadEntries() {
        var results: [SpeedTestResult] = []
        let sql = "SELECT id, download_mbps, upload_mbps, ping_ms, timestamp FROM speed_history ORDER BY id DESC LIMIT 50"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let entry = SpeedTestResult(
                    id: Int64(sqlite3_column_int64(stmt, 0)),
                    downloadMbps: sqlite3_column_double(stmt, 1),
                    uploadMbps: sqlite3_column_double(stmt, 2),
                    pingMs: sqlite3_column_double(stmt, 3),
                    timestamp: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
                )
                results.append(entry)
            }
        }
        sqlite3_finalize(stmt)

        DispatchQueue.main.async {
            self.entries = results
        }
    }

    func clearHistory() {
        sqlite3_exec(db, "DELETE FROM speed_history", nil, nil, nil)
        DispatchQueue.main.async {
            self.entries = []
        }
    }
}

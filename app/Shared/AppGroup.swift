import Foundation

/// Storage shared by the app and its Screen Time extensions.
enum AppGroup {
    static let id = "group.org.leafmonkey.gylt"

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) ?? FileManager.default.temporaryDirectory
    }
    static func file(_ name: String) -> URL { containerURL.appendingPathComponent(name) }
}

/// Diagnostics for the Screen Time extensions, written only by debug builds. A release build writes and keeps nothing.
/// Read it from a connected device with `tools/read-device-log.sh`.
enum DebugLog {
    private static var url: URL { AppGroup.file("debug-log.txt") }
    private static let lock = NSLock()
    private static let maxBytes = 120_000

    static func write(_ source: String, _ message: String) {
        #if DEBUG
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let line = "\(f.string(from: Date())) [\(source)] \(message)\n"
        lock.withLock {
            if let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int, size > maxBytes { try? FileManager.default.removeItem(at: url) }
            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
        #endif
    }
}

/// What the shield screen needs to show, written by the app when a restriction is applied.
struct ShieldLeaseInfo: Codable, Equatable {
    var leaseId: UUID
    var expiresAt: Date
    /// The promise the pause is for, so the shield can name it.
    var promiseTitle: String?
}

enum ShieldLeaseFile {
    private static var url: URL { AppGroup.file("shield-lease.json") }
    static func write(_ info: ShieldLeaseInfo) { if let d = try? JSONEncoder().encode(info) { try? d.write(to: url, options: .atomic) } }
    static func read() -> ShieldLeaseInfo? { (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(ShieldLeaseInfo.self, from: $0) } }
    static func clear() { try? FileManager.default.removeItem(at: url) }
}

/// "End this session" pressed on the shield. The extension releases the restriction itself (no network, no AI);
/// the app reads this on its next launch to record the honest outcome.
struct OverrideRequest: Codable, Equatable {
    var leaseId: UUID?
    var at: Date
}

enum OverrideInbox {
    private static var url: URL { AppGroup.file("override-inbox.json") }
    private static let lock = NSLock()

    static func append(_ request: OverrideRequest) {
        lock.withLock {
            var all = readAll(); all.append(request)
            if let d = try? JSONEncoder().encode(all) { try? d.write(to: url, options: .atomic) }
        }
    }
    static func drain() -> [OverrideRequest] {
        lock.withLock {
            let all = readAll(); try? FileManager.default.removeItem(at: url); return all
        }
    }
    private static func readAll() -> [OverrideRequest] {
        (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode([OverrideRequest].self, from: $0) } ?? []
    }
}

enum ShieldStoreName {
    static let name = "gylt"
}

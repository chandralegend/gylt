import Foundation

/// Storage shared by the app and its Screen Time extensions.
enum AppGroup {
    static let id = "group.org.leafmonkey.gylt"

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) ?? FileManager.default.temporaryDirectory
    }
    static func file(_ name: String) -> URL { containerURL.appendingPathComponent(name) }
}

/// Append-only log written by the app AND the extensions, so the spike can see what happened while the app was closed.
enum SpikeLog {
    private static var url: URL { AppGroup.file("spike-log.txt") }
    private static let lock = NSLock()

    static func write(_ source: String, _ message: String) {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let line = "\(f.string(from: Date())) [\(source)] \(message)\n"
        lock.withLock {
            if let data = line.data(using: .utf8) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    defer { try? handle.close() }
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                } else {
                    try? data.write(to: url, options: .atomic)
                }
            }
        }
    }

    static func recent(_ count: Int = 40) -> [String] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return Array(text.split(separator: "\n").suffix(count).map(String.init))
    }

    static func clear() { try? FileManager.default.removeItem(at: url) }
}

/// What the shield screen needs to show, written by the app when a restriction is applied.
struct ShieldLeaseInfo: Codable, Equatable {
    var leaseId: UUID
    var expiresAt: Date
    /// A shield started from the Screen Time test screen. It is not an engine lease, so the app's launch cleanup must leave it alone.
    var isTest: Bool?
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

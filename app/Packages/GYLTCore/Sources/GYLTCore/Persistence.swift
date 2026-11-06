import Foundation

public protocol StateStore: Sendable {
    func load() throws -> AppState?
    func save(_ state: AppState) throws
}

/// Atomic JSON snapshot. Safe to share between the app and its extensions through an App Group container.
public struct FileStateStore: StateStore {
    public let url: URL
    public init(url: URL) { self.url = url }

    public func load() throws -> AppState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try Self.decoder.decode(AppState.self, from: data)
    }

    public func save(_ state: AppState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try Self.encoder.encode(state)
        try data.write(to: url, options: [.atomic])
    }

    public static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }
    public static var decoder: JSONDecoder { JSONDecoder() }
}

/// For tests and previews.
public final class InMemoryStateStore: StateStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: AppState?
    public init(_ initial: AppState? = nil) { stored = initial }
    public func load() throws -> AppState? { lock.lock(); defer { lock.unlock() }; return stored }
    public func save(_ state: AppState) throws { lock.lock(); stored = state; lock.unlock() }
}

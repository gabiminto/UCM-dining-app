import Foundation

/// Thread-safe disk & memory cache so menus load immediately even on spotty campus Wi-Fi.
public actor MenuCacheStore {
    public static let shared = MenuCacheStore()

    private var memoryCache: [String: Data] = [:]
    private let cacheDirectory: URL

    public init(directoryName: String = "UCMDiningCache") {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        self.cacheDirectory = dir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    public struct CachedValue<Value: Sendable>: Sendable {
        public let value: Value
        public let savedAt: Date
        public let expiresAt: Date

        public var isExpired: Bool { expiresAt <= Date() }
    }

    private struct DiskEntry<Value: Codable>: Codable {
        let value: Value
        let savedAt: Date
        let expiresAt: Date
    }

    public func save<T: Codable & Sendable>(
        _ value: T,
        forKey key: String,
        expiresAt: Date = Date().addingTimeInterval(30 * 60)
    ) {
        let entry = DiskEntry(value: value, savedAt: Date(), expiresAt: expiresAt)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        memoryCache[key] = data
        let fileURL = fileURL(for: key)
        try? data.write(to: fileURL, options: .atomic)
    }

    public func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) -> T? {
        loadCached(type, forKey: key)?.value
    }

    public func loadCached<T: Codable & Sendable>(_ type: T.Type, forKey key: String) -> CachedValue<T>? {
        if let memData = memoryCache[key], let cached = decode(type, from: memData, fileDate: nil) {
            return cached
        }
        let fileURL = fileURL(for: key)
        guard let diskData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        let fileDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        guard let decoded = decode(type, from: diskData, fileDate: fileDate) else { return nil }
        memoryCache[key] = diskData
        return decoded
    }

    public func clearAll() {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(
            of: "[^a-zA-Z0-9_-]",
            with: "_",
            options: .regularExpression
        )
        return cacheDirectory.appendingPathComponent("\(safeKey).json")
    }

    private func decode<T: Codable & Sendable>(
        _ type: T.Type,
        from data: Data,
        fileDate: Date?
    ) -> CachedValue<T>? {
        if let entry = try? JSONDecoder().decode(DiskEntry<T>.self, from: data) {
            return CachedValue(value: entry.value, savedAt: entry.savedAt, expiresAt: entry.expiresAt)
        }

        // Preserve caches written by earlier app versions.
        guard let legacyValue = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        let savedAt = fileDate ?? .distantPast
        return CachedValue(
            value: legacyValue,
            savedAt: savedAt,
            expiresAt: savedAt.addingTimeInterval(30 * 60)
        )
    }
}

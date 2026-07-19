import Foundation

public enum FornixAssetKind: String, CaseIterable, Codable, Sendable {
    case photo
    case document
    case video
    case audio
    case archive
    case other

    public var label: String {
        rawValue.capitalized
    }

    public var systemImage: String {
        switch self {
        case .photo: "photo.fill"
        case .document: "doc.fill"
        case .video: "film.fill"
        case .audio: "waveform"
        case .archive: "archivebox.fill"
        case .other: "square.stack.3d.up.fill"
        }
    }
}

public struct FornixAsset: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: FornixAssetKind
    public var byteCount: Int64
    public var createdAt: Date
    public var modifiedAt: Date
    public var fingerprint: String
    public var tags: [String]
    public var folderName: String?
    public var isFavorite: Bool
    public var isArchived: Bool
    public var sourceURLString: String?

    public init(
        id: UUID = UUID(),
        name: String,
        kind: FornixAssetKind,
        byteCount: Int64,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        fingerprint: String,
        tags: [String] = [],
        folderName: String? = nil,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        sourceURLString: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.byteCount = max(0, byteCount)
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.fingerprint = fingerprint.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tags = tags
        self.folderName = folderName
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.sourceURLString = sourceURLString
    }
}

public struct FornixNubiumSnapshot: Equatable, Codable, Sendable {
    public var assets: [FornixAsset]

    public init(assets: [FornixAsset] = []) {
        self.assets = assets
    }
}

public enum FornixNubiumIndex {
    public static func search(_ query: String, in assets: [FornixAsset]) -> [FornixAsset] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return assets }

        return assets.filter { asset in
            [asset.name, asset.kind.label, asset.folderName]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(normalized) }
            || asset.tags.contains { $0.localizedCaseInsensitiveContains(normalized) }
        }
    }

    public static func duplicateGroups(in assets: [FornixAsset]) -> [[FornixAsset]] {
        Dictionary(grouping: assets.filter { !$0.fingerprint.isEmpty }, by: \.fingerprint)
            .values
            .filter { $0.count > 1 }
            .map { $0.sorted { $0.modifiedAt > $1.modifiedAt } }
            .sorted { lhs, rhs in
                let left = lhs.first?.name ?? ""
                let right = rhs.first?.name ?? ""
                return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
            }
    }

    public static func totalBytes(in assets: [FornixAsset]) -> Int64 {
        assets.reduce(0) { $0 + $1.byteCount }
    }

    public static func duplicateBytes(in assets: [FornixAsset]) -> Int64 {
        duplicateGroups(in: assets).reduce(0) { total, group in
            total + group.dropFirst().reduce(0) { $0 + $1.byteCount }
        }
    }

    public static func uniqueBytes(in assets: [FornixAsset]) -> Int64 {
        max(0, totalBytes(in: assets) - duplicateBytes(in: assets))
    }
}

public actor FornixNubiumStore {
    private var snapshot: FornixNubiumSnapshot
    private let persistenceURL: URL?

    public init(snapshot: FornixNubiumSnapshot = .init(), persistenceURL: URL? = nil) {
        self.snapshot = snapshot
        self.persistenceURL = persistenceURL
    }

    public static var defaultPersistenceURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MyDataDC", isDirectory: true)
            .appendingPathComponent("FornixNubium.json")
    }

    public func currentSnapshot() -> FornixNubiumSnapshot {
        snapshot
    }

    public func upsert(_ asset: FornixAsset) {
        if let index = snapshot.assets.firstIndex(where: { $0.id == asset.id }) {
            snapshot.assets[index] = asset
        } else {
            snapshot.assets.append(asset)
        }
        try? save()
    }

    public func remove(id: UUID) {
        snapshot.assets.removeAll { $0.id == id }
        try? save()
    }

    public func setFavorite(_ favorite: Bool, for id: UUID) {
        guard let index = snapshot.assets.firstIndex(where: { $0.id == id }) else { return }
        snapshot.assets[index].isFavorite = favorite
        try? save()
    }

    public func setArchived(_ archived: Bool, for id: UUID) {
        guard let index = snapshot.assets.firstIndex(where: { $0.id == id }) else { return }
        snapshot.assets[index].isArchived = archived
        try? save()
    }

    public func search(_ query: String) -> [FornixAsset] {
        FornixNubiumIndex.search(query, in: snapshot.assets)
    }

    public func duplicateGroups() -> [[FornixAsset]] {
        FornixNubiumIndex.duplicateGroups(in: snapshot.assets)
    }

    public func load() throws {
        guard let persistenceURL,
              FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
        let data = try Data(contentsOf: persistenceURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        snapshot = try decoder.decode(FornixNubiumSnapshot.self, from: data)
    }

    public func save() throws {
        guard let persistenceURL else { return }
        try FileManager.default.createDirectory(
            at: persistenceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: persistenceURL, options: .atomic)
    }

    @discardableResult
    public func importFiles(_ urls: [URL]) throws -> [FornixAsset] {
        var imported: [FornixAsset] = []
        for url in urls where url.isFileURL {
            let existing = snapshot.assets.first { $0.sourceURLString == url.path }
            let asset = try Self.asset(from: url, preserving: existing)
            if let index = snapshot.assets.firstIndex(where: { $0.id == asset.id }) {
                snapshot.assets[index] = asset
            } else {
                snapshot.assets.append(asset)
            }
            imported.append(asset)
        }
        try save()
        return imported
    }

    @discardableResult
    public func reindex() throws -> Int {
        var refreshed = 0
        for index in snapshot.assets.indices {
            guard let sourceURLString = snapshot.assets[index].sourceURLString else { continue }
            let url = URL(fileURLWithPath: sourceURLString)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            snapshot.assets[index] = try Self.asset(from: url, preserving: snapshot.assets[index])
            refreshed += 1
        }
        try save()
        return refreshed
    }

    private static func asset(from url: URL, preserving existing: FornixAsset?) throws -> FornixAsset {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let byteCount = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let createdAt = attributes[.creationDate] as? Date ?? existing?.createdAt ?? Date()
        let modifiedAt = attributes[.modificationDate] as? Date ?? Date()
        let kind = kind(forExtension: url.pathExtension)
        let folderName = url.deletingLastPathComponent().lastPathComponent
        return FornixAsset(
            id: existing?.id ?? UUID(),
            name: url.lastPathComponent,
            kind: kind,
            byteCount: byteCount,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            fingerprint: try fingerprint(for: url),
            tags: existing?.tags ?? defaultTags(for: kind),
            folderName: folderName.isEmpty ? nil : folderName,
            isFavorite: existing?.isFavorite ?? false,
            isArchived: existing?.isArchived ?? false,
            sourceURLString: url.path
        )
    }

    private static func kind(forExtension pathExtension: String) -> FornixAssetKind {
        switch pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "heif", "tif", "tiff", "webp", "raw": .photo
        case "mov", "mp4", "m4v", "avi", "mkv", "webm": .video
        case "mp3", "m4a", "wav", "aiff", "flac", "aac": .audio
        case "zip", "rar", "7z", "tar", "gz", "bz2": .archive
        case "pdf", "txt", "rtf", "md", "doc", "docx", "pages", "xls", "xlsx", "numbers", "ppt", "pptx", "key": .document
        default: .other
        }
    }

    private static func defaultTags(for kind: FornixAssetKind) -> [String] {
        [kind.label.lowercased(), "imported"]
    }

    private static func fingerprint(for url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hash: UInt64 = 14_695_981_039_346_656_037
        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            for byte in chunk {
                hash ^= UInt64(byte)
                hash = hash &* 1_099_511_628_211
            }
        }
        return String(format: "%016llx", hash)
    }
}

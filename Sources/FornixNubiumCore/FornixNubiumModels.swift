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
        isArchived: Bool = false
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

    public init(snapshot: FornixNubiumSnapshot = .init()) {
        self.snapshot = snapshot
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
    }

    public func remove(id: UUID) {
        snapshot.assets.removeAll { $0.id == id }
    }

    public func setFavorite(_ favorite: Bool, for id: UUID) {
        guard let index = snapshot.assets.firstIndex(where: { $0.id == id }) else { return }
        snapshot.assets[index].isFavorite = favorite
    }

    public func setArchived(_ archived: Bool, for id: UUID) {
        guard let index = snapshot.assets.firstIndex(where: { $0.id == id }) else { return }
        snapshot.assets[index].isArchived = archived
    }

    public func search(_ query: String) -> [FornixAsset] {
        FornixNubiumIndex.search(query, in: snapshot.assets)
    }

    public func duplicateGroups() -> [[FornixAsset]] {
        FornixNubiumIndex.duplicateGroups(in: snapshot.assets)
    }
}

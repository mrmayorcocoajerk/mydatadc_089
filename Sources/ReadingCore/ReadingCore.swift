import Foundation

public enum ReadingProvider: String, Codable, CaseIterable, Sendable {
    case audible, appleBooks, kindle, pdf, epub
}

public enum ReadingFormat: String, Codable, CaseIterable, Sendable {
    case audiobook, ebook, document
}

public enum ReadingStatus: String, Codable, CaseIterable, Sendable {
    case planned, inProgress, completed, paused, abandoned
}

public struct ReadingProgress: Codable, Hashable, Sendable {
    public var fractionCompleted: Double
    public var positionSeconds: TimeInterval?
    public var durationSeconds: TimeInterval?
    public var currentChapter: String?
    public var updatedAt: Date

    public init(
        fractionCompleted: Double = 0,
        positionSeconds: TimeInterval? = nil,
        durationSeconds: TimeInterval? = nil,
        currentChapter: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.fractionCompleted = min(1, max(0, fractionCompleted))
        self.positionSeconds = positionSeconds.map { max(0, $0) }
        self.durationSeconds = durationSeconds.map { max(0, $0) }
        self.currentChapter = currentChapter
        self.updatedAt = updatedAt
    }

    public var remainingSeconds: TimeInterval? {
        guard let positionSeconds, let durationSeconds else { return nil }
        return max(0, durationSeconds - positionSeconds)
    }
}

public struct ReadingItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var provider: ReadingProvider
    public var format: ReadingFormat
    public var title: String
    public var author: String
    public var status: ReadingStatus
    public var progress: ReadingProgress
    public var artworkReference: String?
    public var externalIdentifier: String?
    public var tags: Set<String>

    public init(
        id: UUID = UUID(),
        provider: ReadingProvider,
        format: ReadingFormat,
        title: String,
        author: String,
        status: ReadingStatus = .planned,
        progress: ReadingProgress = .init(),
        artworkReference: String? = nil,
        externalIdentifier: String? = nil,
        tags: Set<String> = []
    ) {
        self.id = id
        self.provider = provider
        self.format = format
        self.title = title
        self.author = author
        self.status = status
        self.progress = progress
        self.artworkReference = artworkReference
        self.externalIdentifier = externalIdentifier
        self.tags = tags
    }
}

public struct ReadingBookmark: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let itemID: UUID
    public var location: String
    public var note: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        itemID: UUID,
        location: String,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.itemID = itemID
        self.location = location
        self.note = note
        self.createdAt = createdAt
    }
}

public struct ReadingSession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let itemID: UUID
    public var startedAt: Date
    public var endedAt: Date
    public var progressDelta: Double

    public init(
        id: UUID = UUID(),
        itemID: UUID,
        startedAt: Date,
        endedAt: Date,
        progressDelta: Double
    ) {
        self.id = id
        self.itemID = itemID
        self.startedAt = startedAt
        self.endedAt = max(startedAt, endedAt)
        self.progressDelta = max(0, progressDelta)
    }

    public var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) }
}

public struct ReadingSnapshot: Codable, Equatable, Sendable {
    public var items: [ReadingItem]
    public var bookmarks: [ReadingBookmark]
    public var sessions: [ReadingSession]

    public init(
        items: [ReadingItem] = [],
        bookmarks: [ReadingBookmark] = [],
        sessions: [ReadingSession] = []
    ) {
        self.items = items
        self.bookmarks = bookmarks
        self.sessions = sessions
    }
}

public struct ReadingSummary: Equatable, Sendable {
    public var inProgressCount: Int
    public var completedCount: Int
    public var totalSessionMinutes: Int
    public var currentItem: ReadingItem?
}

public enum ReadingError: Error, Equatable, Sendable {
    case duplicateExternalIdentifier(String)
    case unknownItem(UUID)
    case invalidSessionRange
}

public actor ReadingCoordinator {
    private var items: [UUID: ReadingItem]
    private var bookmarks: [UUID: ReadingBookmark]
    private var sessions: [UUID: ReadingSession]

    public init(snapshot: ReadingSnapshot = .init()) {
        self.items = .init(uniqueKeysWithValues: snapshot.items.map { ($0.id, $0) })
        self.bookmarks = .init(uniqueKeysWithValues: snapshot.bookmarks.map { ($0.id, $0) })
        self.sessions = .init(uniqueKeysWithValues: snapshot.sessions.map { ($0.id, $0) })
    }

    public func addItem(_ item: ReadingItem) throws {
        if let externalIdentifier = item.externalIdentifier,
           items.values.contains(where: {
               $0.provider == item.provider &&
               $0.externalIdentifier?.caseInsensitiveCompare(externalIdentifier) == .orderedSame
           }) {
            throw ReadingError.duplicateExternalIdentifier(externalIdentifier)
        }
        items[item.id] = item
    }

    public func updateProgress(
        itemID: UUID,
        progress: ReadingProgress,
        status: ReadingStatus? = nil
    ) throws {
        guard var item = items[itemID] else { throw ReadingError.unknownItem(itemID) }
        item.progress = progress
        item.status = status ?? (progress.fractionCompleted >= 1 ? .completed : .inProgress)
        items[itemID] = item
    }

    public func addBookmark(_ bookmark: ReadingBookmark) throws {
        guard items[bookmark.itemID] != nil else { throw ReadingError.unknownItem(bookmark.itemID) }
        bookmarks[bookmark.id] = bookmark
    }

    public func recordSession(_ session: ReadingSession) throws {
        guard items[session.itemID] != nil else { throw ReadingError.unknownItem(session.itemID) }
        guard session.endedAt >= session.startedAt else { throw ReadingError.invalidSessionRange }
        sessions[session.id] = session
    }

    public func continueReading() -> ReadingItem? {
        items.values
            .filter { $0.status == .inProgress || $0.status == .paused }
            .sorted { lhs, rhs in
                if lhs.progress.updatedAt != rhs.progress.updatedAt {
                    return lhs.progress.updatedAt > rhs.progress.updatedAt
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            .first
    }

    public func items(from provider: ReadingProvider) -> [ReadingItem] {
        items.values
            .filter { $0.provider == provider }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func search(_ query: String) -> [ReadingItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return itemList() }
        return items.values.filter { item in
            item.title.localizedCaseInsensitiveContains(needle) ||
            item.author.localizedCaseInsensitiveContains(needle) ||
            item.tags.contains(where: { $0.localizedCaseInsensitiveContains(needle) })
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func summary() -> ReadingSummary {
        let totalMinutes = Int(sessions.values.reduce(0) { $0 + $1.duration } / 60)
        return ReadingSummary(
            inProgressCount: items.values.filter { $0.status == .inProgress }.count,
            completedCount: items.values.filter { $0.status == .completed }.count,
            totalSessionMinutes: totalMinutes,
            currentItem: continueReading()
        )
    }

    public func itemList() -> [ReadingItem] {
        items.values.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func bookmarkList(for itemID: UUID? = nil) -> [ReadingBookmark] {
        bookmarks.values
            .filter { itemID == nil || $0.itemID == itemID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func snapshot() -> ReadingSnapshot {
        ReadingSnapshot(
            items: itemList(),
            bookmarks: bookmarkList(),
            sessions: sessions.values.sorted { $0.startedAt < $1.startedAt }
        )
    }
}

public actor ReadingStore {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func save(_ snapshot: ReadingSnapshot) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load() throws -> ReadingSnapshot {
        guard FileManager.default.fileExists(atPath: url.path) else { return .init() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(ReadingSnapshot.self, from: Data(contentsOf: url))
    }
}

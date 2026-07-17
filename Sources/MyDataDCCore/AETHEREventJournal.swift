import Foundation

public struct AETHEREventRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let sequence: UInt64
    public let recordedAt: Date
    public let event: AETHEREvent

    public init(
        id: UUID = UUID(),
        sequence: UInt64,
        recordedAt: Date = Date(),
        event: AETHEREvent
    ) {
        self.id = id
        self.sequence = sequence
        self.recordedAt = recordedAt
        self.event = event
    }
}

public protocol AETHEREventJournalStore: Sendable {
    func loadRecords() async throws -> [AETHEREventRecord]
    func saveRecords(_ records: [AETHEREventRecord]) async throws
}

public actor InMemoryAETHEREventJournalStore: AETHEREventJournalStore {
    private var records: [AETHEREventRecord]

    public init(records: [AETHEREventRecord] = []) {
        self.records = records
    }

    public func loadRecords() async throws -> [AETHEREventRecord] {
        records
    }

    public func saveRecords(_ records: [AETHEREventRecord]) async throws {
        self.records = records
    }
}

public actor JSONFileAETHEREventJournalStore: AETHEREventJournalStore {
    private let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(url: URL) {
        self.url = url
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func loadRecords() async throws -> [AETHEREventRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try decoder.decode([AETHEREventRecord].self, from: data)
    }

    public func saveRecords(_ records: [AETHEREventRecord]) async throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(records)
        try data.write(to: url, options: .atomic)
    }
}

public actor AETHEREventJournal {
    private let store: any AETHEREventJournalStore
    private let capacity: Int?
    private var records: [AETHEREventRecord] = []
    private var nextSequence: UInt64 = 1

    public init(
        store: any AETHEREventJournalStore = InMemoryAETHEREventJournalStore(),
        capacity: Int? = nil
    ) {
        self.store = store
        self.capacity = capacity.map { max(0, $0) }
    }

    public func restore() async throws {
        let loaded = try await store.loadRecords().sorted { lhs, rhs in
            if lhs.sequence == rhs.sequence {
                return lhs.recordedAt < rhs.recordedAt
            }
            return lhs.sequence < rhs.sequence
        }
        records = retainedRecords(from: loaded)
        nextSequence = (records.last?.sequence ?? 0) + 1
    }

    @discardableResult
    public func append(
        _ event: AETHEREvent,
        at date: Date = Date()
    ) async throws -> AETHEREventRecord? {
        guard capacity != 0 else { return nil }

        let record = AETHEREventRecord(
            sequence: nextSequence,
            recordedAt: date,
            event: event
        )
        nextSequence += 1
        records.append(record)
        records = retainedRecords(from: records)
        try await store.saveRecords(records)
        return record
    }

    public func snapshot() -> [AETHEREventRecord] {
        records
    }

    public func events() -> [AETHEREvent] {
        records.map(\.event)
    }

    public func replay(into bus: AETHEREventBus) async {
        for record in records {
            await bus.publish(record.event)
        }
    }

    public func clear() async throws {
        records.removeAll(keepingCapacity: true)
        nextSequence = 1
        try await store.saveRecords([])
    }

    private func retainedRecords(from records: [AETHEREventRecord]) -> [AETHEREventRecord] {
        guard let capacity else { return records }
        guard capacity > 0 else { return [] }
        return Array(records.suffix(capacity))
    }
}

public actor AETHEREventJournalSubscription {
    private let bus: AETHEREventBus
    private let journal: AETHEREventJournal
    private var subscription: AETHEREventSubscription?
    private var lastError: Error?

    public init(bus: AETHEREventBus, journal: AETHEREventJournal) {
        self.bus = bus
        self.journal = journal
    }

    public func start() async {
        guard subscription == nil else { return }
        subscription = await bus.subscribe { [journal] event in
            do {
                try await journal.append(event)
            } catch {
                // Persistence errors are exposed through the journal's caller-facing
                // operations; event delivery must not take down the bus.
            }
        }
    }

    public func stop() async {
        guard let subscription else { return }
        await bus.unsubscribe(subscription)
        self.subscription = nil
    }

    public func isActive() -> Bool {
        subscription != nil
    }
}

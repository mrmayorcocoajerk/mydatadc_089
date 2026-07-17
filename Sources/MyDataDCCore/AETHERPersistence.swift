import Foundation

public protocol AETHERPersistenceStore: Sendable {
    func loadObjects() async throws -> [AETHERObject]
    func save(_ objects: [AETHERObject]) async throws
}

public actor InMemoryAETHERPersistenceStore: AETHERPersistenceStore {
    private var storage: [AETHERObject] = []
    public init() {}
    public func loadObjects() async throws -> [AETHERObject] { storage }
    public func save(_ objects: [AETHERObject]) async throws { storage = objects }
}

public actor AETHERRepository {
    private let store: AETHERObjectStore
    private let persistence: any AETHERPersistenceStore & Sendable
    private let eventBus: AETHEREventBus?

    public init(
        store: AETHERObjectStore = AETHERObjectStore(),
        persistence: any AETHERPersistenceStore = InMemoryAETHERPersistenceStore(),
        eventBus: AETHEREventBus? = nil
    ) {
        self.store = store
        self.persistence = persistence
        self.eventBus = eventBus
    }

    public func synchronize() async throws {
        let objects = try await persistence.loadObjects()
        await store.replaceAll(with: objects)
    }

    public func upsert(_ object: AETHERObject) async throws {
        _ = try await commit(AETHERTransaction(operations: [.upsert(object)]))
    }

    @discardableResult
    public func remove(id: AETHERObjectID) async throws -> AETHERObject? {
        let result = try await commit(AETHERTransaction(operations: [.remove(id)]))
        return result.removed.first
    }

    @discardableResult
    public func commit(_ transaction: AETHERTransaction) async throws -> AETHERTransactionResult {
        let currentObjects = await store.allObjects()
        var staged = Dictionary(uniqueKeysWithValues: currentObjects.map { ($0.id, $0) })
        var upserted: [AETHERObject] = []
        var removed: [AETHERObject] = []

        for operation in transaction.operations {
            switch operation {
            case .upsert(let object):
                staged[object.id] = object
                upserted.append(object)
            case .remove(let id):
                if let object = staged.removeValue(forKey: id) {
                    removed.append(object)
                }
            }
        }

        let committedObjects = staged.values.sorted { $0.id.description < $1.id.description }

        // Persistence is written before the live object store is replaced. If this
        // throws, the repository remains unchanged and the transaction is rolled back.
        try await persistence.save(committedObjects)
        await store.replaceAll(with: committedObjects)

        if let eventBus {
            for object in upserted {
                await eventBus.publish(.objectUpdated(object.id.description))
            }
            for object in removed {
                await eventBus.publish(.objectUpdated(object.id.description))
            }
        }

        return AETHERTransactionResult(
            transactionID: transaction.id,
            insertedOrUpdated: upserted,
            removed: removed
        )
    }

    public func object(id: AETHERObjectID) async -> AETHERObject? {
        await store.object(id: id)
    }

    public func allObjects() async -> [AETHERObject] {
        await store.allObjects()
    }

    public func persist() async throws {
        try await persistence.save(await store.allObjects())
    }
}

public actor JSONFileAETHERPersistenceStore: AETHERPersistenceStore {
    private let url: URL
    public init(url: URL) { self.url = url }

    public func loadObjects() async throws -> [AETHERObject] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return try JSONDecoder().decode([AETHERObject].self, from: data)
    }

    public func save(_ objects: [AETHERObject]) async throws {
        let data = try JSONEncoder().encode(objects)
        try data.write(to: url, options: .atomic)
    }
}

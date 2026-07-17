import Testing
@testable import MyDataDCCore

private enum TransactionTestError: Error {
    case forcedFailure
}

private actor FailingPersistenceStore: AETHERPersistenceStore {
    private var objects: [AETHERObject] = []
    private var shouldFail = false

    func loadObjects() async throws -> [AETHERObject] { objects }

    func save(_ objects: [AETHERObject]) async throws {
        if shouldFail { throw TransactionTestError.forcedFailure }
        self.objects = objects
    }

    func failNextSave() {
        shouldFail = true
    }
}

private actor TransactionEventRecorder {
    private(set) var events: [AETHEREvent] = []
    func record(_ event: AETHEREvent) { events.append(event) }
    func snapshot() -> [AETHEREvent] { events }
}

@Test
func transactionCommitsMultipleOperationsAtomically() async throws {
    let repository = AETHERRepository()
    let workspaceID = AETHERWorkspaceID()
    let first = AETHERObject(workspaceID: workspaceID, kind: "note")
    let second = AETHERObject(workspaceID: workspaceID, kind: "task")

    let result = try await repository.commit(
        AETHERTransaction(operations: [.upsert(first), .upsert(second), .remove(first.id)])
    )

    #expect(await repository.allObjects() == [second])
    #expect(result.insertedOrUpdated == [first, second])
    #expect(result.removed == [first])
}

@Test
func failedTransactionLeavesRepositoryUnchanged() async throws {
    let persistence = FailingPersistenceStore()
    let repository = AETHERRepository(persistence: persistence)
    let original = AETHERObject(workspaceID: AETHERWorkspaceID(), kind: "note")
    let replacement = AETHERObject(workspaceID: AETHERWorkspaceID(), kind: "task")

    try await repository.upsert(original)
    await persistence.failNextSave()

    await #expect(throws: TransactionTestError.forcedFailure) {
        try await repository.commit(
            AETHERTransaction(operations: [.remove(original.id), .upsert(replacement)])
        )
    }

    #expect(await repository.allObjects() == [original])
}

@Test
func committedTransactionPublishesObjectEvents() async throws {
    let bus = AETHEREventBus()
    let recorder = TransactionEventRecorder()
    _ = await bus.subscribe { event in await recorder.record(event) }
    let repository = AETHERRepository(eventBus: bus)
    let object = AETHERObject(workspaceID: AETHERWorkspaceID(), kind: "note")

    try await repository.upsert(object)
    _ = try await repository.remove(id: object.id)

    #expect(await recorder.snapshot() == [
        .objectUpdated(object.id.description),
        .objectUpdated(object.id.description)
    ])
}

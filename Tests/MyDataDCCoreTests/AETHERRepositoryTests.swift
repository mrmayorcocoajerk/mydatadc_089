import Testing
@testable import MyDataDCCore

@Test
func repositoryPersistsAndRestoresObjects() async throws {
    let persistence = InMemoryAETHERPersistenceStore()
    let workspaceID = AETHERWorkspaceID()
    let object = AETHERObject(workspaceID: workspaceID, kind: "note", payload: ["title": "Mayor"])

    let writer = AETHERRepository(persistence: persistence)
    try await writer.upsert(object)

    let reader = AETHERRepository(persistence: persistence)
    try await reader.synchronize()

    #expect(await reader.object(id: object.id) == object)
    #expect(await reader.allObjects() == [object])
}

@Test
func repositoryRemovalIsPersisted() async throws {
    let persistence = InMemoryAETHERPersistenceStore()
    let object = AETHERObject(workspaceID: AETHERWorkspaceID(), kind: "note")
    let repository = AETHERRepository(persistence: persistence)

    try await repository.upsert(object)
    let removed = try await repository.remove(id: object.id)

    #expect(removed == object)
    #expect(try await persistence.loadObjects().isEmpty)
}

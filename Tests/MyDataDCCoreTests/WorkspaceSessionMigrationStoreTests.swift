import Testing
import Foundation
@testable import MyDataDCCore

@Test
func workspaceSessionStoreLoadsThroughMigrationRegistry() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = WorkspaceSessionStore(url: url)

    try await store.save(
        WorkspaceSession(
            activeWorkspaceID: nil,
            openWorkspaceIDs: [],
            schemaVersion: 1
        )
    )

    let registry = WorkspaceSessionMigrationRegistry(steps: [
        WorkspaceSessionMigrationStep(fromVersion: 1, toVersion: 2) { session in
            WorkspaceSession(
                activeWorkspaceID: session.activeWorkspaceID,
                openWorkspaceIDs: session.openWorkspaceIDs,
                schemaVersion: 2
            )
        }
    ])

    let migrated = try await store.load(migratingWith: registry, to: 2)

    #expect(migrated?.schemaVersion == 2)
}

@Test
func workspaceSessionStoreReturnsCurrentVersionWithoutMigration() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = WorkspaceSessionStore(url: url)
    let session = WorkspaceSession(
        activeWorkspaceID: nil,
        openWorkspaceIDs: [],
        schemaVersion: 3
    )

    try await store.save(session)

    let loaded = try await store.load(
        migratingWith: WorkspaceSessionMigrationRegistry(),
        to: 3
    )

    #expect(loaded == session)
}

import Testing
@testable import MyDataDCCore

@Test
func workspaceSessionMigrationRunsSequentialSteps() throws {
    let registry = WorkspaceSessionMigrationRegistry(steps: [
        WorkspaceSessionMigrationStep(fromVersion: 1, toVersion: 2) { session in
            WorkspaceSession(
                activeWorkspaceID: session.activeWorkspaceID,
                openWorkspaceIDs: session.openWorkspaceIDs,
                schemaVersion: 2
            )
        },
        WorkspaceSessionMigrationStep(fromVersion: 2, toVersion: 3) { session in
            WorkspaceSession(
                activeWorkspaceID: session.activeWorkspaceID,
                openWorkspaceIDs: session.openWorkspaceIDs,
                schemaVersion: 3
            )
        }
    ])

    let migrated = try registry.migrate(
        WorkspaceSession(
            activeWorkspaceID: nil,
            openWorkspaceIDs: [],
            schemaVersion: 1
        ),
        to: 3
    )

    #expect(migrated.schemaVersion == 3)
}

@Test
func workspaceSessionMigrationRejectsMissingStep() {
    let registry = WorkspaceSessionMigrationRegistry()

    #expect(throws: WorkspaceSessionMigrationRegistry.MigrationError.missingStep(from: 1)) {
        try registry.migrate(
            WorkspaceSession(
                activeWorkspaceID: nil,
                openWorkspaceIDs: [],
                schemaVersion: 1
            ),
            to: 2
        )
    }
}

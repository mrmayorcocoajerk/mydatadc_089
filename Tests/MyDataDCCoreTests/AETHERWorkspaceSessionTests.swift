import Testing
@testable import MyDataDCCore

@Test
func workspaceRegistryCapturesAndRestoresSession() async throws {
    let first = AETHERWorkspace(name: "Career", moduleID: .careerHQ)
    let second = AETHERWorkspace(name: "Money", moduleID: .moneyHQ)
    let source = AETHERWorkspaceRegistry(workspaces: [first, second])

    try await source.open(first.id)
    try await source.open(second.id)
    try await source.activate(first.id)

    let session = await source.captureSession(schemaVersion: 87)

    let restored = AETHERWorkspaceRegistry(workspaces: [first, second])
    try await restored.restoreSession(session)

    #expect(await restored.activeWorkspace()?.id == first.id)
    #expect(Set(await restored.openWorkspaces().map(\.id)) == Set([first.id, second.id]))
    #expect(session.schemaVersion == 87)
}

@Test
func workspaceRegistryRejectsSessionWithUnknownWorkspace() async {
    let registry = AETHERWorkspaceRegistry()
    let missingID = AETHERWorkspaceID()
    let session = WorkspaceSession(
        activeWorkspaceID: missingID,
        openWorkspaceIDs: [missingID]
    )

    await #expect(throws: AETHERWorkspaceRegistry.RegistryError.workspaceNotFound(missingID)) {
        try await registry.restoreSession(session)
    }
}

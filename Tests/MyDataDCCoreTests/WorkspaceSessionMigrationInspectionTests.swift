import Testing
@testable import MyDataDCCore

@Test
func migrationRegistryReportsSupportedVersions() {
    let r = WorkspaceSessionMigrationRegistry(steps:[
        .init(fromVersion:1,toVersion:2){ WorkspaceSession(activeWorkspaceID:$0.activeWorkspaceID,openWorkspaceIDs:$0.openWorkspaceIDs,schemaVersion:2)},
        .init(fromVersion:2,toVersion:3){ WorkspaceSession(activeWorkspaceID:$0.activeWorkspaceID,openWorkspaceIDs:$0.openWorkspaceIDs,schemaVersion:3)}
    ])
    #expect(r.containsStep(from:1))
    #expect(r.supportedVersions()==[1,2])
}

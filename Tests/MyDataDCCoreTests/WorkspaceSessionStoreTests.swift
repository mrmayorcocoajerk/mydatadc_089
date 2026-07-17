import Testing
import Foundation
@testable import MyDataDCCore

@Test
func workspaceSessionRoundTrips() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = WorkspaceSessionStore(url: url)
    let session = WorkspaceSession(activeWorkspaceID: nil, openWorkspaceIDs: [])
    try await store.save(session)
    let loaded = try await store.load()
    #expect(loaded?.schemaVersion == session.schemaVersion)
}


@Test
func workspaceSessionDeleteRemovesFile() async throws {
 let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
 let s=WorkspaceSessionStore(url:url)
 try await s.save(WorkspaceSession(activeWorkspaceID:nil,openWorkspaceIDs:[]))
 try await s.delete()
 #expect((try await s.load()) == nil)
}

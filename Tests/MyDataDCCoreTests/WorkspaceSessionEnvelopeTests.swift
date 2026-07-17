import Testing
import Foundation
@testable import MyDataDCCore

@Test
func workspaceSessionEnvelopeRoundTripsWithMetadata() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = WorkspaceSessionStore(url: url)
    let session = WorkspaceSession(
        activeWorkspaceID: nil,
        openWorkspaceIDs: [],
        schemaVersion: 91
    )

    try await store.save(session)
    let envelope = try await store.loadEnvelope()

    #expect(envelope?.session == session)
    #expect(envelope?.metadata.schemaVersion == 91)
}

@Test
func workspaceSessionEnvelopeRejectsSchemaMismatch() {
    let session = WorkspaceSession(
        activeWorkspaceID: nil,
        openWorkspaceIDs: [],
        schemaVersion: 91
    )
    let envelope = WorkspaceSessionEnvelope(
        metadata: WorkspaceSessionMetadata(schemaVersion: 90),
        session: session
    )

    #expect(throws: WorkspaceSessionEnvelope.ValidationError.schemaVersionMismatch(
        metadata: 90,
        session: 91
    )) {
        try envelope.validate()
    }
}

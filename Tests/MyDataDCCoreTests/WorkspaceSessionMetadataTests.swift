import Testing
@testable import MyDataDCCore

@Test
func metadataStoresSchemaVersion() {
    let m=WorkspaceSessionMetadata(schemaVersion: 88)
    #expect(m.schemaVersion == 88)
}

import Foundation

public actor WorkspaceSessionStore {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func save(_ session: WorkspaceSession) throws {
        try save(WorkspaceSessionEnvelope(session: session))
    }

    public func save(_ envelope: WorkspaceSessionEnvelope) throws {
        try envelope.validate()
        let data = try JSONEncoder().encode(envelope)
        try data.write(to: url, options: .atomic)
    }

    public func load() throws -> WorkspaceSession? {
        try loadEnvelope()?.session
    }

    public func loadEnvelope() throws -> WorkspaceSessionEnvelope? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let envelope = try JSONDecoder().decode(WorkspaceSessionEnvelope.self, from: data)
        try envelope.validate()
        return envelope
    }

    public func load(
        migratingWith registry: WorkspaceSessionMigrationRegistry,
        to targetVersion: Int
    ) throws -> WorkspaceSession? {
        guard let envelope = try loadEnvelope() else { return nil }

        if envelope.session.schemaVersion == targetVersion {
            return envelope.session
        }

        return try registry.migrate(envelope.session, to: targetVersion)
    }

    public func delete() throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

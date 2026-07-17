import Foundation

public struct WorkspaceSessionEnvelope: Codable, Sendable, Equatable {
    public let metadata: WorkspaceSessionMetadata
    public let session: WorkspaceSession

    public init(
        metadata: WorkspaceSessionMetadata,
        session: WorkspaceSession
    ) {
        self.metadata = metadata
        self.session = session
    }

    public init(
        session: WorkspaceSession,
        createdAt: Date = .now
    ) {
        self.session = session
        self.metadata = WorkspaceSessionMetadata(
            createdAt: createdAt,
            schemaVersion: session.schemaVersion
        )
    }

    public func validate() throws {
        guard metadata.schemaVersion == session.schemaVersion else {
            throw ValidationError.schemaVersionMismatch(
                metadata: metadata.schemaVersion,
                session: session.schemaVersion
            )
        }
    }

    public enum ValidationError: Error, Equatable {
        case schemaVersionMismatch(metadata: Int, session: Int)
    }
}

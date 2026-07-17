import Foundation

public struct WorkspaceSessionMetadata: Codable, Sendable, Equatable {
    public let createdAt: Date
    public let schemaVersion: Int

    public init(createdAt: Date = .now, schemaVersion: Int) {
        self.createdAt = createdAt
        self.schemaVersion = schemaVersion
    }
}

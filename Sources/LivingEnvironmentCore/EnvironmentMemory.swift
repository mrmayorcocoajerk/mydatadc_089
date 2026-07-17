import Foundation

public struct EnvironmentMemory: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let capturedAt: Date
    public let title: String
    public let profile: AtmosphereProfile
    public let dominantTags: Set<String>
    public let importance: Double

    public init(
        id: UUID = UUID(),
        capturedAt: Date,
        title: String,
        profile: AtmosphereProfile,
        dominantTags: Set<String> = [],
        importance: Double = 0.5
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.title = title
        self.profile = profile
        self.dominantTags = dominantTags
        self.importance = min(max(importance, 0), 1)
    }
}

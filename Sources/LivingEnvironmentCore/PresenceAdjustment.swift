import Foundation

public struct PresenceAdjustment: Codable, Equatable, Sendable {
    public let lightMultiplier: Double
    public let motionMultiplier: Double
    public let audioEnabled: Bool
    public let welcomesResident: Bool
    public let concealsPersonalContent: Bool

    public init(
        lightMultiplier: Double,
        motionMultiplier: Double,
        audioEnabled: Bool,
        welcomesResident: Bool,
        concealsPersonalContent: Bool
    ) {
        self.lightMultiplier = min(max(lightMultiplier, 0), 1.5)
        self.motionMultiplier = min(max(motionMultiplier, 0), 1.5)
        self.audioEnabled = audioEnabled
        self.welcomesResident = welcomesResident
        self.concealsPersonalContent = concealsPersonalContent
    }
}

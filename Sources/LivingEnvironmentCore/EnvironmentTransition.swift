import Foundation

public struct EnvironmentTransition: Codable, Equatable, Sendable {
    public enum Pace: String, Codable, Sendable {
        case immediate, brisk, graceful, cinematic
    }

    public let pace: Pace
    public let durationSeconds: Double
    public let crossfadesAudio: Bool
    public let interpolatesLighting: Bool

    public init(
        pace: Pace,
        durationSeconds: Double,
        crossfadesAudio: Bool,
        interpolatesLighting: Bool
    ) {
        self.pace = pace
        self.durationSeconds = max(0, durationSeconds)
        self.crossfadesAudio = crossfadesAudio
        self.interpolatesLighting = interpolatesLighting
    }
}

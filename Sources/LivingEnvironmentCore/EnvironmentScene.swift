import Foundation

public struct EnvironmentScene: Codable, Equatable, Sendable {
    public enum TemperatureCharacter: String, Codable, Sendable {
        case cold, cool, neutral, warm, hot
    }

    public enum MotionLevel: String, Codable, Sendable {
        case still, gentle, active, urgent
    }

    public let temperatureCharacter: TemperatureCharacter
    public let motionLevel: MotionLevel
    public let showsRainReflections: Bool
    public let showsSnowfall: Bool
    public let showsLightningReflections: Bool
    public let showsMist: Bool
    public let isSafetyElevated: Bool
    public let summary: String

    public init(
        temperatureCharacter: TemperatureCharacter,
        motionLevel: MotionLevel,
        showsRainReflections: Bool,
        showsSnowfall: Bool,
        showsLightningReflections: Bool,
        showsMist: Bool,
        isSafetyElevated: Bool,
        summary: String
    ) {
        self.temperatureCharacter = temperatureCharacter
        self.motionLevel = motionLevel
        self.showsRainReflections = showsRainReflections
        self.showsSnowfall = showsSnowfall
        self.showsLightningReflections = showsLightningReflections
        self.showsMist = showsMist
        self.isSafetyElevated = isSafetyElevated
        self.summary = summary
    }
}

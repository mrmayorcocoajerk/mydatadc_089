import Foundation

public struct AtmosphereProfile: Codable, Equatable, Sendable {
    public enum LightingTone: String, Codable, Sendable {
        case ice, silver, daylight, warm, amber, violet, midnight
    }

    public enum AmbientSound: String, Codable, Sendable {
        case silent, softRoom, rain, wind, distantThunder, snowfall
    }

    public let lightingTone: LightingTone
    public let lightIntensity: Double
    public let reflectionIntensity: Double
    public let motionScale: Double
    public let ambientSound: AmbientSound
    public let showsSeasonalAccents: Bool
    public let celebrationAccent: LivingContext.Celebration
    public let reducesDistractions: Bool

    public init(
        lightingTone: LightingTone,
        lightIntensity: Double,
        reflectionIntensity: Double,
        motionScale: Double,
        ambientSound: AmbientSound,
        showsSeasonalAccents: Bool,
        celebrationAccent: LivingContext.Celebration,
        reducesDistractions: Bool
    ) {
        self.lightingTone = lightingTone
        self.lightIntensity = Self.clamp(lightIntensity)
        self.reflectionIntensity = Self.clamp(reflectionIntensity)
        self.motionScale = Self.clamp(motionScale)
        self.ambientSound = ambientSound
        self.showsSeasonalAccents = showsSeasonalAccents
        self.celebrationAccent = celebrationAccent
        self.reducesDistractions = reducesDistractions
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

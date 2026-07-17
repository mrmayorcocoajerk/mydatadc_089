import Foundation

public enum LivingAtmosphereEngine {
    public static func profile(
        weather: WeatherSnapshot,
        context: LivingContext
    ) -> AtmosphereProfile {
        let scene = LivingEnvironmentEngine.scene(for: weather)

        let baseTone: AtmosphereProfile.LightingTone
        let baseLight: Double
        switch context.timeOfDay {
        case .dawn:
            baseTone = .amber
            baseLight = 0.58
        case .morning:
            baseTone = .daylight
            baseLight = 0.78
        case .afternoon:
            baseTone = .daylight
            baseLight = 0.92
        case .evening:
            baseTone = .warm
            baseLight = 0.62
        case .night:
            baseTone = .violet
            baseLight = 0.38
        case .lateNight:
            baseTone = .midnight
            baseLight = 0.22
        }

        let seasonalTone: AtmosphereProfile.LightingTone
        switch context.season {
        case .spring: seasonalTone = baseTone
        case .summer: seasonalTone = context.timeOfDay == .evening ? .amber : baseTone
        case .autumn: seasonalTone = .warm
        case .winter: seasonalTone = scene.temperatureCharacter == .cold ? .ice : .silver
        }

        let weatherSound: AtmosphereProfile.AmbientSound
        switch weather.condition {
        case .rain: weatherSound = .rain
        case .thunderstorm: weatherSound = .distantThunder
        case .snow: weatherSound = .snowfall
        case .wind: weatherSound = .wind
        default: weatherSound = context.timeOfDay == .lateNight ? .silent : .softRoom
        }

        let safetyPenalty = scene.isSafetyElevated ? 0.18 : 0
        let focusMultiplier = context.focusModeEnabled ? 0.45 : 1
        let motion = min(max((scene.motionLevel == .urgent ? 0.88 : scene.motionLevel == .active ? 0.66 : scene.motionLevel == .gentle ? 0.38 : 0.18) * focusMultiplier, 0), 1)

        return AtmosphereProfile(
            lightingTone: seasonalTone,
            lightIntensity: max(0.12, baseLight - safetyPenalty),
            reflectionIntensity: scene.showsRainReflections ? 0.9 : scene.showsSnowfall ? 0.62 : 0.46,
            motionScale: motion,
            ambientSound: context.focusModeEnabled && weather.condition != .thunderstorm ? .silent : weatherSound,
            showsSeasonalAccents: true,
            celebrationAccent: context.celebration,
            reducesDistractions: context.focusModeEnabled || context.timeOfDay == .lateNight
        )
    }

    public static func transition(
        from old: AtmosphereProfile,
        to new: AtmosphereProfile
    ) -> EnvironmentTransition {
        if new.reducesDistractions && !old.reducesDistractions {
            return EnvironmentTransition(
                pace: .graceful,
                durationSeconds: 1.2,
                crossfadesAudio: true,
                interpolatesLighting: true
            )
        }

        let intensityDelta = abs(new.lightIntensity - old.lightIntensity)
        if intensityDelta > 0.45 || old.ambientSound != new.ambientSound {
            return EnvironmentTransition(
                pace: .cinematic,
                durationSeconds: 1.8,
                crossfadesAudio: true,
                interpolatesLighting: true
            )
        }

        return EnvironmentTransition(
            pace: .brisk,
            durationSeconds: 0.55,
            crossfadesAudio: old.ambientSound != new.ambientSound,
            interpolatesLighting: true
        )
    }
}

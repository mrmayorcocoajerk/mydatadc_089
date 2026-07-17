import Foundation

public enum LivingEnvironmentEngine {
    public static func scene(for weather: WeatherSnapshot) -> EnvironmentScene {
        let character: EnvironmentScene.TemperatureCharacter
        switch weather.feelsLikeFahrenheit {
        case ..<32: character = .cold
        case 32..<55: character = .cool
        case 55..<75: character = .neutral
        case 75..<90: character = .warm
        default: character = .hot
        }

        let safetyElevated = weather.condition == .extremeHeat
            || weather.condition == .extremeCold
            || weather.condition == .thunderstorm
            || weather.feelsLikeFahrenheit >= 100
            || weather.feelsLikeFahrenheit <= 10

        let motion: EnvironmentScene.MotionLevel
        if safetyElevated {
            motion = .urgent
        } else if weather.condition == .rain || weather.condition == .snow || weather.condition == .wind {
            motion = .active
        } else if weather.condition == .partlyCloudy || weather.condition == .cloudy || weather.condition == .fog {
            motion = .gentle
        } else {
            motion = .still
        }

        return EnvironmentScene(
            temperatureCharacter: character,
            motionLevel: motion,
            showsRainReflections: weather.condition == .rain || weather.condition == .thunderstorm,
            showsSnowfall: weather.condition == .snow,
            showsLightningReflections: weather.condition == .thunderstorm,
            showsMist: weather.condition == .fog,
            isSafetyElevated: safetyElevated,
            summary: summary(for: weather)
        )
    }

    private static func summary(for weather: WeatherSnapshot) -> String {
        let rounded = Int(weather.feelsLikeFahrenheit.rounded())
        switch weather.condition {
        case .rain: return "Rain outside. Feels like \(rounded)°F. Reflections enabled."
        case .thunderstorm: return "Thunderstorm conditions. Feels like \(rounded)°F. Safety awareness elevated."
        case .snow: return "Snowfall outside. Feels like \(rounded)°F. Quiet winter atmosphere enabled."
        case .fog: return "Low visibility. Feels like \(rounded)°F. Mist atmosphere enabled."
        case .extremeHeat: return "Extreme heat. Feels like \(rounded)°F. Safety awareness elevated."
        case .extremeCold: return "Extreme cold. Feels like \(rounded)°F. Safety awareness elevated."
        default: return "\(weather.condition.rawValue) outside. Feels like \(rounded)°F."
        }
    }
}

import Foundation

public struct WeatherSnapshot: Codable, Equatable, Sendable {
    public enum Condition: String, Codable, CaseIterable, Sendable {
        case clear, partlyCloudy, cloudy, rain, thunderstorm, snow, fog, wind, extremeHeat, extremeCold
    }

    public let locationName: String
    public let temperatureFahrenheit: Double
    public let feelsLikeFahrenheit: Double
    public let highFahrenheit: Double
    public let lowFahrenheit: Double
    public let condition: Condition
    public let humidityPercent: Int
    public let windMilesPerHour: Double
    public let precipitationChancePercent: Int
    public let uvIndex: Int
    public let observedAt: Date

    public init(
        locationName: String,
        temperatureFahrenheit: Double,
        feelsLikeFahrenheit: Double,
        highFahrenheit: Double,
        lowFahrenheit: Double,
        condition: Condition,
        humidityPercent: Int,
        windMilesPerHour: Double,
        precipitationChancePercent: Int,
        uvIndex: Int,
        observedAt: Date = .now
    ) {
        self.locationName = locationName
        self.temperatureFahrenheit = temperatureFahrenheit
        self.feelsLikeFahrenheit = feelsLikeFahrenheit
        self.highFahrenheit = highFahrenheit
        self.lowFahrenheit = lowFahrenheit
        self.condition = condition
        self.humidityPercent = min(max(humidityPercent, 0), 100)
        self.windMilesPerHour = max(windMilesPerHour, 0)
        self.precipitationChancePercent = min(max(precipitationChancePercent, 0), 100)
        self.uvIndex = min(max(uvIndex, 0), 15)
        self.observedAt = observedAt
    }

    public var feelsLikeDelta: Double {
        feelsLikeFahrenheit - temperatureFahrenheit
    }
}

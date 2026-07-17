import Foundation

public struct GrandHallWeatherPanelState: Equatable, Sendable {
    public let location: String
    public let temperatureText: String
    public let feelsLikeText: String
    public let highLowText: String
    public let conditionText: String
    public let environment: EnvironmentScene

    public init(snapshot: WeatherSnapshot) {
        location = snapshot.locationName
        temperatureText = Self.degrees(snapshot.temperatureFahrenheit)
        feelsLikeText = "Feels like \(Self.degrees(snapshot.feelsLikeFahrenheit))"
        highLowText = "H: \(Self.degrees(snapshot.highFahrenheit))  L: \(Self.degrees(snapshot.lowFahrenheit))"
        conditionText = snapshot.condition.rawValue
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
        environment = LivingEnvironmentEngine.scene(for: snapshot)
    }

    private static func degrees(_ value: Double) -> String {
        "\(Int(value.rounded()))°F"
    }
}

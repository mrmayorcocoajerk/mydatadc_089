import Foundation
import GalleryCore
import LivingEnvironmentCore

public struct WeatherPanelProvider: PanelSnapshotProvider {
    public let supportedKind: PanelKind = .weather
    private let weather: @Sendable () async throws -> WeatherSnapshot

    public init(weather: @escaping @Sendable () async throws -> WeatherSnapshot) {
        self.weather = weather
    }

    public func snapshot(for panel: GalleryPanel, at date: Date) async throws -> PanelSnapshot {
        let value = try await weather()
        let feelsLike = Int(value.feelsLikeFahrenheit.rounded())
        let actual = Int(value.temperatureFahrenheit.rounded())
        let delta = feelsLike - actual
        let badge = delta == 0 ? nil : (delta > 0 ? "+\(delta)° feels" : "\(delta)° feels")
        let isHazardous = value.condition == .extremeHeat || value.condition == .extremeCold || value.condition == .thunderstorm

        return PanelSnapshot(
            panelID: panel.id,
            title: "\(actual)°",
            subtitle: "Feels like \(feelsLike)° · \(displayName(for: value.condition))",
            badge: badge,
            health: isHazardous ? .degraded : .nominal,
            priority: isHazardous ? max(panel.priority, 100) : panel.priority,
            updatedAt: date,
            expiresAt: date.addingTimeInterval(15 * 60),
            metadata: [
                "location": value.locationName,
                "humidity": "\(value.humidityPercent)%",
                "wind": "\(Int(value.windMilesPerHour.rounded())) mph",
                "condition": value.condition.rawValue,
                "high": "\(Int(value.highFahrenheit.rounded()))°",
                "low": "\(Int(value.lowFahrenheit.rounded()))°"
            ]
        )
    }

    private func displayName(for condition: WeatherSnapshot.Condition) -> String {
        condition.rawValue
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
}

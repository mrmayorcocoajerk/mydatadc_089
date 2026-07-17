import Foundation

public struct LivingContext: Codable, Equatable, Sendable {
    public enum TimeOfDay: String, Codable, CaseIterable, Sendable {
        case dawn, morning, afternoon, evening, night, lateNight
    }

    public enum Season: String, Codable, CaseIterable, Sendable {
        case spring, summer, autumn, winter
    }

    public enum Celebration: String, Codable, CaseIterable, Sendable {
        case none, birthday, newYear, halloween, winterHoliday
    }

    public let timeOfDay: TimeOfDay
    public let season: Season
    public let celebration: Celebration
    public let focusModeEnabled: Bool

    public init(
        timeOfDay: TimeOfDay,
        season: Season,
        celebration: Celebration = .none,
        focusModeEnabled: Bool = false
    ) {
        self.timeOfDay = timeOfDay
        self.season = season
        self.celebration = celebration
        self.focusModeEnabled = focusModeEnabled
    }

    public static func timeOfDay(for date: Date, calendar: Calendar = .current) -> TimeOfDay {
        switch calendar.component(.hour, from: date) {
        case 5..<7: return .dawn
        case 7..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        case 21..<24: return .night
        default: return .lateNight
        }
    }

    public static func season(for date: Date, calendar: Calendar = .current) -> Season {
        switch calendar.component(.month, from: date) {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
}

import Foundation

public struct VitalsEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var date: Date
    public var sleepHours: Double
    public var waterGlasses: Int
    public var activeMinutes: Int
    public var note: String

    public init(id: UUID = UUID(), date: Date = Date(), sleepHours: Double, waterGlasses: Int, activeMinutes: Int, note: String = "") {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.waterGlasses = waterGlasses
        self.activeMinutes = activeMinutes
        self.note = note
    }
}

public struct VitalsSnapshot: Codable, Equatable, Sendable {
    public var entries: [VitalsEntry]

    public init(entries: [VitalsEntry] = []) {
        self.entries = entries
    }
}

public struct VitalsSummary: Equatable, Sendable {
    public let daysLogged: Int
    public let averageSleepHours: Double
    public let totalWaterGlasses: Int
    public let totalActiveMinutes: Int

    public init(daysLogged: Int, averageSleepHours: Double, totalWaterGlasses: Int, totalActiveMinutes: Int) {
        self.daysLogged = daysLogged
        self.averageSleepHours = averageSleepHours
        self.totalWaterGlasses = totalWaterGlasses
        self.totalActiveMinutes = totalActiveMinutes
    }
}

public enum VitalsError: Error, Equatable, Sendable {
    case invalidSleepHours
    case invalidWaterGlasses
    case invalidActiveMinutes
}

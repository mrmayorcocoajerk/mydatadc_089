import Foundation

public enum TimeStudioMode: String, CaseIterable, Identifiable, Sendable {
    case stopwatch = "Stopwatch"
    case timer = "Timer"

    public var id: String { rawValue }
}

public struct StopwatchState: Equatable, Sendable {
    public private(set) var accumulated: TimeInterval
    public private(set) var startedAt: Date?
    public private(set) var laps: [TimeInterval]

    public init(accumulated: TimeInterval = 0, startedAt: Date? = nil, laps: [TimeInterval] = []) {
        self.accumulated = max(0, accumulated)
        self.startedAt = startedAt
        self.laps = laps
    }

    public var isRunning: Bool { startedAt != nil }

    public mutating func start(at date: Date = Date()) {
        guard startedAt == nil else { return }
        startedAt = date
    }

    public mutating func pause(at date: Date = Date()) {
        guard let startedAt else { return }
        accumulated += max(0, date.timeIntervalSince(startedAt))
        self.startedAt = nil
    }

    public mutating func reset() {
        accumulated = 0
        startedAt = nil
        laps = []
    }

    @discardableResult
    public mutating func recordLap(at date: Date = Date()) -> TimeInterval? {
        let value = elapsed(at: date)
        guard value > 0 else { return nil }
        laps.append(value)
        return value
    }

    public func elapsed(at date: Date = Date()) -> TimeInterval {
        guard let startedAt else { return accumulated }
        return accumulated + max(0, date.timeIntervalSince(startedAt))
    }
}

public struct CountdownState: Equatable, Sendable {
    public private(set) var duration: TimeInterval
    public private(set) var remainingWhenPaused: TimeInterval
    public private(set) var deadline: Date?

    public init(duration: TimeInterval = 300) {
        let safeDuration = max(1, duration)
        self.duration = safeDuration
        self.remainingWhenPaused = safeDuration
        self.deadline = nil
    }

    public var isRunning: Bool { deadline != nil }

    public mutating func setDuration(_ seconds: TimeInterval) {
        let safeDuration = max(1, seconds)
        duration = safeDuration
        remainingWhenPaused = safeDuration
        deadline = nil
    }

    public mutating func start(at date: Date = Date()) {
        guard deadline == nil, remainingWhenPaused > 0 else { return }
        deadline = date.addingTimeInterval(remainingWhenPaused)
    }

    public mutating func pause(at date: Date = Date()) {
        remainingWhenPaused = remaining(at: date)
        deadline = nil
    }

    public mutating func reset() {
        remainingWhenPaused = duration
        deadline = nil
    }

    public func remaining(at date: Date = Date()) -> TimeInterval {
        guard let deadline else { return remainingWhenPaused }
        return max(0, deadline.timeIntervalSince(date))
    }

    public func isFinished(at date: Date = Date()) -> Bool {
        isRunning && remaining(at: date) <= 0
    }
}

public enum TimeDisplayFormatter {
    public static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

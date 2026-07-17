import Foundation

public struct CrystalSignal: Codable, Equatable, Sendable {
    public enum Event: String, Codable, CaseIterable, Sendable {
        case idle, notification, packageArrival, interviewScheduled, renderProgress, focusStarted, safetyAlert, success
    }

    public enum Pattern: String, Codable, Sendable {
        case dormant, ripple, doublePulse, breathing, progressOrbit, quietGlow, urgentBeacon, radiantBloom
    }

    public let event: Event
    public let pattern: Pattern
    public let intensity: Double
    public let durationSeconds: Double
    public let suppressesOtherSignals: Bool

    public init(event: Event, pattern: Pattern, intensity: Double, durationSeconds: Double, suppressesOtherSignals: Bool) {
        self.event = event
        self.pattern = pattern
        self.intensity = min(max(intensity, 0), 1)
        self.durationSeconds = max(0, durationSeconds)
        self.suppressesOtherSignals = suppressesOtherSignals
    }
}

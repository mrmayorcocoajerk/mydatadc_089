import Foundation

public struct PresenceState: Codable, Equatable, Sendable {
    public enum Occupancy: String, Codable, CaseIterable, Sendable {
        case away, arriving, present, idle, sleeping
    }

    public let occupancy: Occupancy
    public let nearbyDeviceCount: Int
    public let lastInteractionAt: Date?
    public let privacyModeEnabled: Bool

    public init(
        occupancy: Occupancy,
        nearbyDeviceCount: Int = 0,
        lastInteractionAt: Date? = nil,
        privacyModeEnabled: Bool = false
    ) {
        self.occupancy = occupancy
        self.nearbyDeviceCount = max(0, nearbyDeviceCount)
        self.lastInteractionAt = lastInteractionAt
        self.privacyModeEnabled = privacyModeEnabled
    }
}

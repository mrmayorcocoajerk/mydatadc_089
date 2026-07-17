import Foundation
import GalleryCore

public enum PanelRefreshPolicy: Codable, Equatable, Sendable {
    case manual
    case interval(TimeInterval)
    case eventDriven

    public var minimumInterval: TimeInterval? {
        switch self {
        case .interval(let value): max(1, value)
        case .manual, .eventDriven: nil
        }
    }
}

public enum PanelHealth: String, Codable, CaseIterable, Sendable {
    case nominal
    case stale
    case degraded
    case unavailable
}

public struct PanelSnapshot: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let panelID: UUID
    public var title: String
    public var subtitle: String?
    public var badge: String?
    public var health: PanelHealth
    public var priority: Int
    public var updatedAt: Date
    public var expiresAt: Date?
    public var metadata: [String: String]

    public init(
        id: UUID = UUID(),
        panelID: UUID,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        health: PanelHealth = .nominal,
        priority: Int = 0,
        updatedAt: Date = .now,
        expiresAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.panelID = panelID
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.health = health
        self.priority = priority
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
        self.metadata = metadata
    }

    public func evaluated(at date: Date) -> PanelSnapshot {
        guard let expiresAt, date >= expiresAt, health == .nominal else { return self }
        var copy = self
        copy.health = .stale
        return copy
    }
}

public struct PanelRegistration: Identifiable, Sendable {
    public let id: UUID
    public let panel: GalleryPanel
    public let policy: PanelRefreshPolicy

    public init(panel: GalleryPanel, policy: PanelRefreshPolicy) {
        self.id = panel.id
        self.panel = panel
        self.policy = policy
    }
}

public enum PanelRuntimeError: Error, Equatable, Sendable {
    case duplicateRegistration
    case unknownPanel
    case noProvider
}

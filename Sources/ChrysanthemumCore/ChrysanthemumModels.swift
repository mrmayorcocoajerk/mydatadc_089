import Foundation

public enum DistrictID: String, Codable, CaseIterable, Sendable {
    case grandHall
    case apple
    case reading
    case connections
    case commerce
    case creative
    case productivity
    case finance
    case netSphere
    case digiSphere
}

public enum ChrysanthemumEventKind: String, Codable, CaseIterable, Sendable {
    case dataChanged
    case attentionRequired
    case workflowCompleted
    case workflowFailed
    case navigationRequested
    case panelRefreshRequested
    case sceneActivationRequested
    case notificationRequested
}

public struct ChrysanthemumEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: ChrysanthemumEventKind
    public let source: DistrictID
    public let destination: DistrictID?
    public let subject: String
    public let correlationID: UUID
    public let occurredAt: Date
    public var priority: Int
    public var payload: [String: String]

    public init(
        id: UUID = UUID(),
        kind: ChrysanthemumEventKind,
        source: DistrictID,
        destination: DistrictID? = nil,
        subject: String,
        correlationID: UUID = UUID(),
        occurredAt: Date = .now,
        priority: Int = 0,
        payload: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.source = source
        self.destination = destination
        self.subject = subject
        self.correlationID = correlationID
        self.occurredAt = occurredAt
        self.priority = max(0, min(100, priority))
        self.payload = payload
    }
}

public enum ChrysanthemumAction: Codable, Equatable, Sendable {
    case refreshPanel(identifier: String)
    case activateScene(identifier: String)
    case openDistrict(DistrictID)
    case postNotification(title: String, body: String)
    case recordTimeline(category: String)
}

public struct ChrysanthemumRule: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var eventKind: ChrysanthemumEventKind
    public var source: DistrictID?
    public var subjectPrefix: String?
    public var minimumPriority: Int
    public var actions: [ChrysanthemumAction]
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        eventKind: ChrysanthemumEventKind,
        source: DistrictID? = nil,
        subjectPrefix: String? = nil,
        minimumPriority: Int = 0,
        actions: [ChrysanthemumAction],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.eventKind = eventKind
        self.source = source
        self.subjectPrefix = subjectPrefix
        self.minimumPriority = max(0, min(100, minimumPriority))
        self.actions = actions
        self.isEnabled = isEnabled
    }

    public func matches(_ event: ChrysanthemumEvent) -> Bool {
        guard isEnabled, event.kind == eventKind, event.priority >= minimumPriority else { return false }
        if let source, source != event.source { return false }
        if let subjectPrefix, !event.subject.lowercased().hasPrefix(subjectPrefix.lowercased()) { return false }
        return true
    }
}

public struct RoutedAction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let eventID: UUID
    public let ruleID: UUID
    public let action: ChrysanthemumAction
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        eventID: UUID,
        ruleID: UUID,
        action: ChrysanthemumAction,
        createdAt: Date = .now
    ) {
        self.id = id
        self.eventID = eventID
        self.ruleID = ruleID
        self.action = action
        self.createdAt = createdAt
    }
}

public enum ChrysanthemumError: Error, Equatable, Sendable {
    case duplicateRule
    case unknownRule
    case duplicateEvent
}

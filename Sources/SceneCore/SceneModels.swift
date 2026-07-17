import Foundation
import GalleryCore

public enum ManorDistrict: String, Codable, CaseIterable, Sendable {
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

public enum SceneKind: String, Codable, CaseIterable, Sendable {
    case morning
    case work
    case studio
    case evening
    case travel
    case sleep
    case custom
}

public enum SceneTrigger: Codable, Equatable, Sendable {
    case manual
    case timeRange(startHour: Int, endHour: Int)
    case focusMode(name: String)
    case location(identifier: String)
}

public struct ManorScene: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: SceneKind
    public var gallery: Gallery
    public var openDistricts: Set<ManorDistrict>
    public var mutedDistricts: Set<ManorDistrict>
    public var triggers: [SceneTrigger]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        kind: SceneKind,
        gallery: Gallery,
        openDistricts: Set<ManorDistrict> = [.grandHall],
        mutedDistricts: Set<ManorDistrict> = [],
        triggers: [SceneTrigger] = [.manual],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.gallery = gallery
        self.openDistricts = openDistricts
        self.mutedDistricts = mutedDistricts
        self.triggers = triggers
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct SceneContext: Equatable, Sendable {
    public var date: Date
    public var focusModeName: String?
    public var locationIdentifier: String?

    public init(date: Date = .now, focusModeName: String? = nil, locationIdentifier: String? = nil) {
        self.date = date
        self.focusModeName = focusModeName
        self.locationIdentifier = locationIdentifier
    }
}

public struct SceneActivation: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let sceneID: UUID
    public let activatedAt: Date
    public let reason: String

    public init(id: UUID = UUID(), sceneID: UUID, activatedAt: Date = .now, reason: String) {
        self.id = id
        self.sceneID = sceneID
        self.activatedAt = activatedAt
        self.reason = reason
    }
}

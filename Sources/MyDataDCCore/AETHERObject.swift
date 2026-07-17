import Foundation

public struct AETHERObjectID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString }
}

public struct AETHERWorkspaceID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString }
}

public struct AETHERObjectKind: Hashable, Codable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { rawValue = value }
}

public struct AETHERObject: Identifiable, Equatable, Codable, Sendable {
    public let id: AETHERObjectID
    public var workspaceID: AETHERWorkspaceID
    public var kind: AETHERObjectKind
    public var payload: [String: String]
    public var updatedAt: Date

    public init(
        id: AETHERObjectID = AETHERObjectID(),
        workspaceID: AETHERWorkspaceID,
        kind: AETHERObjectKind,
        payload: [String: String] = [:],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.kind = kind
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

public actor AETHERObjectStore {
    private var objectsByID: [AETHERObjectID: AETHERObject] = [:]
    private var objectIDsByWorkspace: [AETHERWorkspaceID: Set<AETHERObjectID>] = [:]
    private var objectIDsByKind: [AETHERObjectKind: Set<AETHERObjectID>] = [:]

    public init(objects: [AETHERObject] = []) {
        for object in objects {
            objectsByID[object.id] = object
            objectIDsByWorkspace[object.workspaceID, default: []].insert(object.id)
            objectIDsByKind[object.kind, default: []].insert(object.id)
        }
    }

    @discardableResult
    public func upsert(_ object: AETHERObject) -> AETHERObject? {
        let previous = objectsByID.updateValue(object, forKey: object.id)

        if let previous {
            if previous.workspaceID != object.workspaceID {
                remove(object.id, from: &objectIDsByWorkspace, key: previous.workspaceID)
            }
            if previous.kind != object.kind {
                remove(object.id, from: &objectIDsByKind, key: previous.kind)
            }
        }

        objectIDsByWorkspace[object.workspaceID, default: []].insert(object.id)
        objectIDsByKind[object.kind, default: []].insert(object.id)
        return previous
    }

    public func object(id: AETHERObjectID) -> AETHERObject? {
        objectsByID[id]
    }

    public func objects(in workspaceID: AETHERWorkspaceID) -> [AETHERObject] {
        objects(for: objectIDsByWorkspace[workspaceID] ?? [])
    }

    public func objects(ofKind kind: AETHERObjectKind) -> [AETHERObject] {
        objects(for: objectIDsByKind[kind] ?? [])
    }

    @discardableResult
    public func remove(id: AETHERObjectID) -> AETHERObject? {
        guard let object = objectsByID.removeValue(forKey: id) else { return nil }
        remove(id, from: &objectIDsByWorkspace, key: object.workspaceID)
        remove(id, from: &objectIDsByKind, key: object.kind)
        return object
    }

    public func removeAll(in workspaceID: AETHERWorkspaceID) -> [AETHERObject] {
        let ids = objectIDsByWorkspace[workspaceID] ?? []
        return ids.compactMap { remove(id: $0) }
    }

    public func allObjects() -> [AETHERObject] {
        objectsByID.values.sorted { $0.id.description < $1.id.description }
    }

    public func removeAll() {
        objectsByID.removeAll()
        objectIDsByWorkspace.removeAll()
        objectIDsByKind.removeAll()
    }

    public func replaceAll(with objects: [AETHERObject]) {
        removeAll()
        for object in objects {
            upsert(object)
        }
    }

    public func count() -> Int {
        objectsByID.count
    }

    private func objects(for ids: Set<AETHERObjectID>) -> [AETHERObject] {
        ids.compactMap { objectsByID[$0] }
            .sorted { $0.id.description < $1.id.description }
    }

    private func remove<Key: Hashable>(
        _ objectID: AETHERObjectID,
        from index: inout [Key: Set<AETHERObjectID>],
        key: Key
    ) {
        index[key]?.remove(objectID)
        if index[key]?.isEmpty == true {
            index.removeValue(forKey: key)
        }
    }
}

import Foundation

public struct AETHERWorkspace: Identifiable, Equatable, Codable, Sendable {
    public let id: AETHERWorkspaceID
    public var name: String
    public var moduleID: MyDataDCModuleID
    public var lastOpenedAt: Date

    public init(
        id: AETHERWorkspaceID = AETHERWorkspaceID(),
        name: String,
        moduleID: MyDataDCModuleID,
        lastOpenedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.moduleID = moduleID
        self.lastOpenedAt = lastOpenedAt
    }
}

public actor AETHERWorkspaceRegistry {
    public enum RegistryError: Error, Equatable {
        case workspaceNotFound(AETHERWorkspaceID)
    }

    private var workspacesByID: [AETHERWorkspaceID: AETHERWorkspace]
    private var openWorkspaceIDs: Set<AETHERWorkspaceID> = []
    private var activeWorkspaceID: AETHERWorkspaceID?

    public init(workspaces: [AETHERWorkspace] = []) {
        workspacesByID = Dictionary(uniqueKeysWithValues: workspaces.map { ($0.id, $0) })
    }

    @discardableResult
    public func register(_ workspace: AETHERWorkspace) -> AETHERWorkspace? {
        workspacesByID.updateValue(workspace, forKey: workspace.id)
    }

    public func workspace(id: AETHERWorkspaceID) -> AETHERWorkspace? {
        workspacesByID[id]
    }

    public func allWorkspaces() -> [AETHERWorkspace] {
        workspacesByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    public func open(_ id: AETHERWorkspaceID, at date: Date = Date()) throws {
        guard var workspace = workspacesByID[id] else {
            throw RegistryError.workspaceNotFound(id)
        }
        workspace.lastOpenedAt = date
        workspacesByID[id] = workspace
        openWorkspaceIDs.insert(id)
        activeWorkspaceID = id
    }

    public func activate(_ id: AETHERWorkspaceID) throws {
        guard workspacesByID[id] != nil else {
            throw RegistryError.workspaceNotFound(id)
        }
        openWorkspaceIDs.insert(id)
        activeWorkspaceID = id
    }

    public func close(_ id: AETHERWorkspaceID) throws {
        guard workspacesByID[id] != nil else {
            throw RegistryError.workspaceNotFound(id)
        }

        openWorkspaceIDs.remove(id)

        if activeWorkspaceID == id {
            activeWorkspaceID = openWorkspaceIDs
                .compactMap { workspacesByID[$0] }
                .sorted { $0.lastOpenedAt > $1.lastOpenedAt }
                .first?.id
        }
    }

    public func activeWorkspace() -> AETHERWorkspace? {
        activeWorkspaceID.flatMap { workspacesByID[$0] }
    }

    public func openWorkspaces() -> [AETHERWorkspace] {
        openWorkspaceIDs
            .compactMap { workspacesByID[$0] }
            .sorted { $0.lastOpenedAt > $1.lastOpenedAt }
    }

    public func captureSession(schemaVersion: Int = 82) -> WorkspaceSession {
        WorkspaceSession(
            activeWorkspaceID: activeWorkspaceID,
            openWorkspaceIDs: openWorkspaces().map(\.id),
            schemaVersion: schemaVersion
        )
    }

    public func restoreSession(_ session: WorkspaceSession) throws {
        for id in session.openWorkspaceIDs {
            guard workspacesByID[id] != nil else {
                throw RegistryError.workspaceNotFound(id)
            }
        }

        if let activeID = session.activeWorkspaceID,
           workspacesByID[activeID] == nil {
            throw RegistryError.workspaceNotFound(activeID)
        }

        openWorkspaceIDs = Set(session.openWorkspaceIDs)
        activeWorkspaceID = session.activeWorkspaceID

        if let activeID = session.activeWorkspaceID {
            openWorkspaceIDs.insert(activeID)
        }
    }

}

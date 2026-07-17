import Foundation

public protocol WorkspaceSessionMigrating: Sendable {
    var fromVersion: Int { get }
    var toVersion: Int { get }
    func migrate(_ session: WorkspaceSession) throws -> WorkspaceSession
}

public struct WorkspaceSessionMigrationStep: WorkspaceSessionMigrating, Sendable {
    public let fromVersion: Int
    public let toVersion: Int
    private let transform: @Sendable (WorkspaceSession) throws -> WorkspaceSession

    public init(
        fromVersion: Int,
        toVersion: Int,
        transform: @escaping @Sendable (WorkspaceSession) throws -> WorkspaceSession
    ) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.transform = transform
    }

    public func migrate(_ session: WorkspaceSession) throws -> WorkspaceSession {
        try transform(session)
    }
}

public struct WorkspaceSessionMigrationRegistry: Sendable {
    let steps: [Int: WorkspaceSessionMigrationStep]

    public init(steps: [WorkspaceSessionMigrationStep] = []) {
        self.steps = Dictionary(uniqueKeysWithValues: steps.map { ($0.fromVersion, $0) })
    }

    public func migrate(
        _ session: WorkspaceSession,
        to targetVersion: Int
    ) throws -> WorkspaceSession {
        guard session.schemaVersion <= targetVersion else {
            throw MigrationError.downgradeUnsupported(
                from: session.schemaVersion,
                to: targetVersion
            )
        }

        var current = session

        while current.schemaVersion < targetVersion {
            guard let step = steps[current.schemaVersion] else {
                throw MigrationError.missingStep(from: current.schemaVersion)
            }

            guard step.toVersion > step.fromVersion else {
                throw MigrationError.invalidStep(
                    from: step.fromVersion,
                    to: step.toVersion
                )
            }

            let migrated = try step.migrate(current)

            guard migrated.schemaVersion == step.toVersion else {
                throw MigrationError.invalidResult(
                    expected: step.toVersion,
                    actual: migrated.schemaVersion
                )
            }

            current = migrated
        }

        return current
    }

    public enum MigrationError: Error, Equatable {
        case downgradeUnsupported(from: Int, to: Int)
        case missingStep(from: Int)
        case invalidStep(from: Int, to: Int)
        case invalidResult(expected: Int, actual: Int)
    }
}

import Foundation

public extension WorkspaceSessionMigrationRegistry {
    func containsStep(from version: Int) -> Bool {
        steps[version] != nil
    }

    func supportedVersions() -> [Int] {
        steps.keys.sorted()
    }
}

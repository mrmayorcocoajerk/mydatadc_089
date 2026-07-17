import Foundation
import MyDataDCCore

@MainActor
public final class MyDataDCNavigationSelectionStore {
    public static let defaultKey = "MyDataDC.selectedModuleID"

    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = MyDataDCNavigationSelectionStore.defaultKey
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func restore(fallback: MyDataDCModuleID = .manor) -> MyDataDCModuleID {
        guard
            let rawValue = defaults.string(forKey: key),
            let moduleID = MyDataDCModuleID(rawValue: rawValue)
        else {
            return fallback
        }
        return moduleID
    }

    public func save(_ moduleID: MyDataDCModuleID) {
        defaults.set(moduleID.rawValue, forKey: key)
    }
}

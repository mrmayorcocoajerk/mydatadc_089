import Foundation
import MyDataDCCore

@MainActor
public final class MyDataDCNavigationModel {
    public private(set) var modules: [MyDataDCModule]
    public private(set) var selectedModuleID: MyDataDCModuleID
    public var searchText: String

    private let registry: ModuleRegistry

    public init(
        registry: ModuleRegistry = ModuleRegistry(),
        selectedModuleID: MyDataDCModuleID = .manor,
        searchText: String = ""
    ) {
        self.registry = registry
        self.modules = ModuleRegistry.defaults
        self.selectedModuleID = selectedModuleID
        self.searchText = searchText
    }

    public var selectedModule: MyDataDCModule? {
        modules.first { $0.id == selectedModuleID }
    }

    public var visibleModules: [MyDataDCModule] {
        let enabled = modules.filter(\.isEnabled)
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return enabled
        }
        return enabled.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    public func load() async {
        modules = await registry.allModules()
        if !modules.contains(where: { $0.id == selectedModuleID && $0.isEnabled }) {
            selectedModuleID = .manor
        }
    }

    public func select(_ id: MyDataDCModuleID) {
        guard modules.contains(where: { $0.id == id && $0.isEnabled }) else { return }
        selectedModuleID = id
    }

    public func setEnabled(_ enabled: Bool, for id: MyDataDCModuleID) async throws {
        try await registry.setEnabled(enabled, for: id)
        await load()
    }
}

#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class MyDataDCAppState: ObservableObject {
    @Published public private(set) var modules: [MyDataDCModule]
    @Published public var selectedModuleID: MyDataDCModuleID
    @Published public var searchText: String

    private let model: MyDataDCNavigationModel

    public init(model: MyDataDCNavigationModel = MyDataDCNavigationModel()) {
        self.model = model
        self.modules = model.modules
        self.selectedModuleID = model.selectedModuleID
        self.searchText = model.searchText
    }

    public var selectedModule: MyDataDCModule? {
        modules.first { $0.id == selectedModuleID }
    }

    public var visibleModules: [MyDataDCModule] {
        let enabled = modules.filter(\.isEnabled)
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return enabled }
        return enabled.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    public func load() async {
        model.searchText = searchText
        await model.load()
        synchronize()
    }

    public func select(_ id: MyDataDCModuleID) {
        model.select(id)
        synchronize()
    }

    private func synchronize() {
        modules = model.modules
        selectedModuleID = model.selectedModuleID
        searchText = model.searchText
    }
}
#endif

import Foundation
import Testing
import MyDataDCCore
@testable import MyDataDCAppShell

@MainActor
@Test func appStateStartsAtTheManor() {
    let state = MyDataDCNavigationModel()
    #expect(state.selectedModuleID == .manor)
    #expect(state.selectedModule?.displayName == "The Manor")
}

@MainActor
@Test func appStateFiltersModulesByNameAndSubtitle() {
    let state = MyDataDCNavigationModel(searchText: "financial")
    #expect(state.visibleModules.map(\.id) == [.moneyHQ])

    state.searchText = "video"
    #expect(state.visibleModules.map(\.id) == [.chosenMeiga])
}

@MainActor
@Test func disabledModuleCannotRemainSelected() async throws {
    let state = MyDataDCNavigationModel(selectedModuleID: .newsDesk)
    try await state.setEnabled(false, for: .newsDesk)
    #expect(state.selectedModuleID == .manor)
    #expect(!state.visibleModules.contains { $0.id == .newsDesk })
}

@MainActor
@Test func appStateCanNavigateToEnabledModule() {
    let state = MyDataDCNavigationModel()
    state.select(.careerHQ)
    #expect(state.selectedModuleID == .careerHQ)
}

@MainActor
@Test func navigationSelectionStoreRestoresSavedModule() {
    let suiteName = "MyDataDCAppShellTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = MyDataDCNavigationSelectionStore(defaults: defaults)

    store.save(.careerHQ)

    #expect(store.restore() == .careerHQ)
}

@MainActor
@Test func appStateRestoresAndPersistsNavigationSelection() {
    let suiteName = "MyDataDCAppShellTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = MyDataDCNavigationSelectionStore(defaults: defaults)
    let state = MyDataDCAppState(selectionStore: store)

    state.select(.newsDesk)
    let restoredState = MyDataDCAppState(selectionStore: store)

    #expect(restoredState.selectedModuleID == .newsDesk)
}

@MainActor
@Test func navigationSelectionStoreFallsBackForInvalidValue() {
    let suiteName = "MyDataDCAppShellTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set("retired-module", forKey: MyDataDCNavigationSelectionStore.defaultKey)
    let store = MyDataDCNavigationSelectionStore(defaults: defaults)

    #expect(store.restore() == .manor)
}

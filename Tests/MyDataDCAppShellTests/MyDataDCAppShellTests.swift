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

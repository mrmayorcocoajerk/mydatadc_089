import Foundation
import Testing
import MyDataDCCore
import NetSphereCore
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
@Test func appStateCanClearModuleSearch() {
    let state = MyDataDCNavigationModel(searchText: "financial")
    #expect(state.visibleModules.map(\.id) == [.moneyHQ])

    state.clearSearch()

    #expect(state.searchText.isEmpty)
    #expect(state.visibleModules.count == ModuleRegistry.defaults.filter(\.isEnabled).count)
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
@Test func appStateCanReturnToTheManor() {
    let state = MyDataDCNavigationModel(selectedModuleID: .moneyHQ)

    state.returnToManor()

    #expect(state.selectedModuleID == .manor)
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

@MainActor
@Test func newsDeskRanksAndFiltersArticles() async {
    let now = Date(timeIntervalSince1970: 10_000)
    let source = NewsSource(name: "NewsDesk Wire", domain: "example.com", reliabilityScore: 0.9)
    let routine = NewsArticle(
        headline: "Local arts calendar",
        summary: "A weekly culture roundup.",
        scope: .culture,
        source: source,
        publishedAt: now
    )
    let breaking = NewsArticle(
        headline: "Severe weather warning",
        summary: "Officials issued an urgent alert.",
        scope: .local,
        urgency: .breaking,
        source: source,
        publishedAt: now.addingTimeInterval(-60),
        topics: ["weather"]
    )
    let store = NetSphereStore(snapshot: .init(articles: [routine, breaking]))
    let viewModel = NewsDeskViewModel(store: store, persistenceURL: nil)

    await viewModel.load()
    #expect(viewModel.displayedArticles.first?.id == breaking.id)

    viewModel.query = "arts"
    #expect(viewModel.displayedArticles.map(\.id) == [routine.id])
}

@MainActor
@Test func newsDeskCanClearSearchAndToggleSavedArticle() async {
    let article = NewsArticle(
        headline: "Science briefing",
        summary: "A research update.",
        scope: .science,
        source: NewsSource(name: "Research Desk", domain: "example.com", reliabilityScore: 0.8),
        publishedAt: Date(timeIntervalSince1970: 20_000)
    )
    let viewModel = NewsDeskViewModel(
        store: NetSphereStore(snapshot: .init(articles: [article])),
        query: "science",
        persistenceURL: nil
    )

    await viewModel.load()
    viewModel.clearSearch()
    await viewModel.toggleSaved(article)

    #expect(viewModel.query.isEmpty)
    #expect(viewModel.isSaved(article))
}

private struct StubNewsFeedLoader: NewsFeedLoading {
    let articles: [NewsArticle]

    func fetch(_ endpoint: NewsFeedEndpoint) async throws -> [NewsArticle] {
        articles
    }
}

@MainActor
@Test func newsDeskRefreshesAndPersistsBriefing() async throws {
    let article = NewsArticle(
        headline: "A live briefing",
        summary: "Fresh reporting.",
        scope: .world,
        source: NewsSource(name: "Test Wire", domain: "example.com", reliabilityScore: 0.8),
        publishedAt: Date(timeIntervalSince1970: 30_000)
    )
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("NewsDesk.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let endpoint = NewsFeedEndpoint(
        name: "Test Wire",
        url: URL(string: "https://example.com/rss.xml")!,
        scope: .world
    )
    let viewModel = NewsDeskViewModel(
        feedLoader: StubNewsFeedLoader(articles: [article]),
        endpoints: [endpoint],
        persistenceURL: url
    )

    await viewModel.refresh()

    #expect(viewModel.displayedArticles.map(\.headline) == ["A live briefing"])
    #expect(viewModel.briefing != nil)
    #expect(FileManager.default.fileExists(atPath: url.path))
    #expect(viewModel.errorMessage == nil)
}

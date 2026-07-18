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

    viewModel.query = ""
    viewModel.selectedScope = .culture
    #expect(viewModel.displayedArticles.map(\.id) == [routine.id])

    viewModel.resetFilters()
    #expect(viewModel.displayedArticles.count == 2)
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
    viewModel.showsSavedOnly = true

    #expect(viewModel.query.isEmpty)
    #expect(viewModel.isSaved(article))
    #expect(viewModel.displayedArticles.map(\.id) == [article.id])
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
    #expect(viewModel.sourceStatuses.map(\.state) == [.updated])
}

private enum StubFeedError: Error { case unavailable }

private struct PartialNewsFeedLoader: NewsFeedLoading {
    let availableName: String
    let article: NewsArticle

    func fetch(_ endpoint: NewsFeedEndpoint) async throws -> [NewsArticle] {
        guard endpoint.name == availableName else { throw StubFeedError.unavailable }
        return [article]
    }
}

@MainActor
@Test func newsDeskReportsPartialSourceFailureWithoutDiscardingStories() async {
    let available = NewsFeedEndpoint(
        name: "Available Wire",
        url: URL(string: "https://example.com/available.xml")!,
        scope: .world
    )
    let unavailable = NewsFeedEndpoint(
        name: "Unavailable Wire",
        url: URL(string: "https://example.com/unavailable.xml")!,
        scope: .world
    )
    let article = NewsArticle(
        headline: "Still delivered",
        summary: "One source remained available.",
        scope: .world,
        source: NewsSource(name: available.name, domain: "example.com", reliabilityScore: 0.8),
        publishedAt: Date(timeIntervalSince1970: 40_000)
    )
    let viewModel = NewsDeskViewModel(
        feedLoader: PartialNewsFeedLoader(availableName: available.name, article: article),
        endpoints: [available, unavailable],
        persistenceURL: nil
    )

    await viewModel.refresh()

    #expect(viewModel.displayedArticles.map(\.headline) == ["Still delivered"])
    #expect(viewModel.sourceStatuses.map(\.state) == [.updated, .unavailable])
    #expect(viewModel.statusMessage?.contains("Unavailable Wire") == true)
    #expect(viewModel.errorMessage == nil)
}

@MainActor
@Test func newsDeskTopicPreferencesMuteAndPrioritizeStories() async {
    let now = Date(timeIntervalSince1970: 50_000)
    let source = NewsSource(name: "Topic Wire", domain: "example.com", reliabilityScore: 0.8)
    let technology = NewsArticle(
        headline: "Technology story",
        summary: "A technology update.",
        scope: .technology,
        source: source,
        publishedAt: now,
        topics: ["technology"]
    )
    let culture = NewsArticle(
        headline: "Culture story",
        summary: "A culture update.",
        scope: .culture,
        source: source,
        publishedAt: now,
        topics: ["culture"]
    )
    let viewModel = NewsDeskViewModel(
        store: NetSphereStore(snapshot: .init(articles: [culture, technology])),
        persistenceURL: nil
    )
    await viewModel.load()

    await viewModel.setTopicMode(.followed, for: "technology")
    await viewModel.setPriority(100, for: "technology")
    #expect(viewModel.displayedArticles.first?.id == technology.id)
    #expect(viewModel.priority(for: "technology") == 100)

    await viewModel.setTopicMode(.muted, for: "technology")
    #expect(viewModel.displayedArticles.map(\.id) == [culture.id])

    await viewModel.setTopicMode(.neutral, for: "technology")
    #expect(viewModel.topicMode(for: "technology") == .neutral)
}

@MainActor
@Test func newsDeskTopicPreferencesPersistBetweenViewModels() async {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("NewsDesk.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let first = NewsDeskViewModel(
        store: NetSphereStore(snapshot: .init(subscriptions: [
            .init(name: "science", priority: 80)
        ])),
        endpoints: [],
        persistenceURL: url
    )
    await first.load()
    await first.setPriority(90, for: "science")

    let restored = NewsDeskViewModel(endpoints: [], persistenceURL: url)
    await restored.load()

    #expect(restored.topicMode(for: "science") == .followed)
    #expect(restored.priority(for: "science") == 90)
}

@MainActor
@Test func newsDeskExposesTopicsForPreviouslyUncategorizedStories() async {
    let cached = NewsArticle(
        headline: "World briefing",
        summary: "An uncategorized report.",
        scope: .world,
        source: NewsSource(name: "Cached Wire", domain: "example.com", reliabilityScore: 0.8),
        publishedAt: Date(),
        topics: []
    )
    let viewModel = NewsDeskViewModel(
        store: NetSphereStore(snapshot: .init(articles: [cached])),
        endpoints: [],
        persistenceURL: nil
    )
    await viewModel.load()
    #expect(viewModel.availableTopics.contains("world"))
}

@MainActor
@Test func newsDeskReportsBriefingFreshnessAndPrunesUnsavedStaleStories() async {
    let now = Date()
    let source = NewsSource(name: "Briefing Wire", domain: "example.com", reliabilityScore: 0.8)
    let stale = NewsArticle(
        headline: "Old report",
        summary: "No longer current.",
        scope: .world,
        source: source,
        publishedAt: now.addingTimeInterval(-10 * 24 * 60 * 60)
    )
    let saved = NewsArticle(
        headline: "Saved old report",
        summary: "Kept for later.",
        scope: .world,
        source: source,
        publishedAt: now.addingTimeInterval(-10 * 24 * 60 * 60)
    )
    let briefing = DailyBriefing(
        generatedAt: now.addingTimeInterval(-7 * 60 * 60),
        articles: [stale, saved]
    )
    let viewModel = NewsDeskViewModel(
        store: NetSphereStore(snapshot: .init(
            articles: [stale, saved],
            savedArticleIDs: [saved.id],
            lastBriefing: briefing
        )),
        endpoints: [],
        persistenceURL: nil
    )

    await viewModel.load()

    #expect(viewModel.displayedArticles.map(\.id) == [saved.id])
    #expect(viewModel.briefingFreshness(now: now) == .fresh)
    #expect(viewModel.refreshAgeText(now: now) == "Just updated")
}

@MainActor
@Test func newsDeskMarksAnOldBriefingAsStale() async {
    let now = Date()
    let article = NewsArticle(
        headline: "Current report",
        summary: "Still inside retention.",
        scope: .world,
        source: NewsSource(name: "Briefing Wire", domain: "example.com", reliabilityScore: 0.8),
        publishedAt: now
    )
    let viewModel = NewsDeskViewModel(
        store: NetSphereStore(snapshot: .init(
            articles: [article],
            lastBriefing: DailyBriefing(
                generatedAt: now.addingTimeInterval(-7 * 60 * 60),
                articles: [article]
            )
        )),
        endpoints: [],
        persistenceURL: nil
    )
    await viewModel.load()
    #expect(viewModel.briefingFreshness(now: now) == .stale)
    #expect(viewModel.refreshAgeText(now: now) == "Updated 7h ago")
}

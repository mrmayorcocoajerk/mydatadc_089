#if canImport(SwiftUI)
import Foundation
import SwiftUI
import NetSphereCore

public struct NewsDeskSourceStatus: Identifiable, Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case waiting
        case cached
        case updated
        case unavailable
    }

    public var id: URL { endpointURL }
    public let endpointURL: URL
    public let name: String
    public let state: State
    public let storyCount: Int

    public init(endpoint: NewsFeedEndpoint, state: State, storyCount: Int = 0) {
        self.endpointURL = endpoint.url
        self.name = endpoint.name
        self.state = state
        self.storyCount = storyCount
    }

    public var detail: String {
        switch state {
        case .waiting: "Waiting"
        case .cached: "\(storyCount) cached"
        case .updated: "\(storyCount) new"
        case .unavailable: "Unavailable"
        }
    }
}

public enum NewsDeskTopicMode: String, CaseIterable, Hashable, Sendable {
    case neutral
    case followed
    case muted

    public var displayName: String {
        switch self {
        case .neutral: "Neutral"
        case .followed: "Follow"
        case .muted: "Mute"
        }
    }
}

public enum NewsDeskBriefingFreshness: Equatable, Sendable {
    case fresh
    case aging
    case stale
}

@MainActor
public final class NewsDeskViewModel: ObservableObject {
    @Published public var query: String
    @Published public var selectedScope: NewsScope?
    @Published public var showsSavedOnly: Bool
    @Published public private(set) var snapshot: NetSphereSnapshot
    @Published public private(set) var isRefreshing = false
    @Published public private(set) var statusMessage: String?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var sourceStatuses: [NewsDeskSourceStatus]

    private let store: NetSphereStore
    private let feedLoader: any NewsFeedLoading
    private let endpoints: [NewsFeedEndpoint]
    private let persistenceURL: URL?

    public init(
        store: NetSphereStore = NetSphereStore(),
        query: String = "",
        selectedScope: NewsScope? = nil,
        showsSavedOnly: Bool = false,
        feedLoader: any NewsFeedLoading = RSSNewsFeedClient(),
        endpoints: [NewsFeedEndpoint] = NewsFeedEndpoint.newsDeskDefaults,
        persistenceURL: URL? = NewsDeskViewModel.defaultPersistenceURL
    ) {
        self.store = store
        self.query = query
        self.selectedScope = selectedScope
        self.showsSavedOnly = showsSavedOnly
        self.feedLoader = feedLoader
        self.endpoints = endpoints
        self.persistenceURL = persistenceURL
        self.snapshot = NetSphereSnapshot()
        self.sourceStatuses = endpoints.map { NewsDeskSourceStatus(endpoint: $0, state: .waiting) }
    }

    public var displayedArticles: [NewsArticle] {
        NetSphereEngine.ranked(
            snapshot.articles,
            subscriptions: snapshot.subscriptions
        )
        .filter { NetSphereEngine.matches($0, query: query) }
        .filter { selectedScope == nil || $0.scope == selectedScope }
        .filter { !showsSavedOnly || snapshot.savedArticleIDs.contains($0.id) }
    }

    public var availableScopes: [NewsScope] {
        let scopes = Set(snapshot.articles.map(\.scope))
        return NewsScope.allCases.filter(scopes.contains)
    }

    public var hasActiveFilters: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedScope != nil
            || showsSavedOnly
    }

    public var savedArticleCount: Int { snapshot.savedArticleIDs.count }

    public var availableTopics: [String] {
        let articleTopics = snapshot.articles.flatMap { NetSphereEngine.topics(for: $0) }
        let subscribedTopics = snapshot.subscriptions.map(\.normalizedName)
        return Array(Set(articleTopics).union(subscribedTopics)).sorted()
    }

    public var followedTopicCount: Int {
        snapshot.subscriptions.filter { !$0.isMuted }.count
    }

    public var briefing: DailyBriefing? {
        snapshot.lastBriefing
    }

    public var briefingArticles: [NewsArticle] {
        snapshot.lastBriefing?.articles ?? []
    }

    public var breakingArticles: [NewsArticle] {
        NetSphereEngine.ranked(
            snapshot.articles,
            subscriptions: snapshot.subscriptions
        )
        .filter { NetSphereEngine.urgency(for: $0) >= .breaking }
    }

    public func briefingFreshness(now: Date = Date()) -> NewsDeskBriefingFreshness? {
        guard let generatedAt = briefing?.generatedAt else { return nil }
        let age = max(0, now.timeIntervalSince(generatedAt))
        if age < 3_600 { return .fresh }
        if age < 21_600 { return .aging }
        return .stale
    }

    public func refreshAgeText(now: Date = Date()) -> String? {
        guard let generatedAt = briefing?.generatedAt else { return nil }
        let seconds = max(0, Int(now.timeIntervalSince(generatedAt)))
        if seconds < 60 { return "Just updated" }
        if seconds < 3_600 { return "Updated \(seconds / 60)m ago" }
        if seconds < 86_400 { return "Updated \(seconds / 3_600)h ago" }
        return "Updated \(seconds / 86_400)d ago"
    }

    public func load() async {
        if let persistenceURL, FileManager.default.fileExists(atPath: persistenceURL.path) {
            do {
                try await store.load(from: persistenceURL)
            } catch {
                errorMessage = "Saved briefing could not be loaded: \(error.localizedDescription)"
            }
        }
        let storedSnapshot = await store.currentSnapshot()
        var removedCount = 0
        if storedSnapshot.lastBriefing != nil {
            removedCount = await pruneStaleArticles()
        }
        if removedCount > 0 {
            await store.generateBriefing()
            await persist()
        }
        snapshot = await store.currentSnapshot()
        sourceStatuses = endpoints.map { endpoint in
            let count = snapshot.articles.filter { $0.source.name == endpoint.name }.count
            return NewsDeskSourceStatus(
                endpoint: endpoint,
                state: count == 0 ? .waiting : .cached,
                storyCount: count
            )
        }
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        statusMessage = nil
        errorMessage = nil
        defer { isRefreshing = false }

        var fetched: [NewsArticle] = []
        var failures: [String] = []
        var refreshedStatuses: [NewsDeskSourceStatus] = []
        for endpoint in endpoints {
            do {
                let articles = try await feedLoader.fetch(endpoint)
                fetched += articles
                refreshedStatuses.append(NewsDeskSourceStatus(
                    endpoint: endpoint,
                    state: .updated,
                    storyCount: articles.count
                ))
            } catch {
                failures.append(endpoint.name)
                refreshedStatuses.append(NewsDeskSourceStatus(endpoint: endpoint, state: .unavailable))
            }
        }
        sourceStatuses = refreshedStatuses

        guard !fetched.isEmpty else {
            errorMessage = failures.isEmpty
                ? "No headlines were returned."
                : "Could not refresh: \(failures.joined(separator: ", "))."
            return
        }                                           

        _ = await pruneStaleArticles()
        await store.ingest(fetched)
        await store.generateBriefing()
        await persist()
        snapshot = await store.currentSnapshot()
        statusMessage = failures.isEmpty
            ? "Updated \(fetched.count) headlines."
            : "Updated \(fetched.count) headlines; unavailable: \(failures.joined(separator: ", "))."
    }

    public func clearSearch() {
        query = ""
    }

    public func resetFilters() {
        query = ""
        selectedScope = nil
        showsSavedOnly = false
    }

    public func topicMode(for topic: String) -> NewsDeskTopicMode {
        guard let subscription = subscription(for: topic) else { return .neutral }
        return subscription.isMuted ? .muted : .followed
    }

    public func priority(for topic: String) -> Int {
        subscription(for: topic)?.priority ?? 70
    }

    public func setTopicMode(_ mode: NewsDeskTopicMode, for topic: String) async {
        let current = subscription(for: topic)
        switch mode {
        case .neutral:
            await store.removeSubscription(named: topic)
        case .followed:
            await store.upsertSubscription(TopicSubscription(
                id: current?.id ?? UUID(),
                name: topic,
                isMuted: false,
                priority: current?.priority ?? 70
            ))
        case .muted:
            await store.upsertSubscription(TopicSubscription(
                id: current?.id ?? UUID(),
                name: topic,
                isMuted: true,
                priority: current?.priority ?? 70
            ))
        }
        await updateBriefingAndPersist()
    }

    public func setPriority(_ priority: Int, for topic: String) async {
        let current = subscription(for: topic)
        await store.upsertSubscription(TopicSubscription(
            id: current?.id ?? UUID(),
            name: topic,
            isMuted: false,
            priority: priority
        ))
        await updateBriefingAndPersist()
    }

    public func topicDisplayName(_ topic: String) -> String {
        topic.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
    }

    public func isSaved(_ article: NewsArticle) -> Bool {
        snapshot.savedArticleIDs.contains(article.id)
    }

    public func toggleSaved(_ article: NewsArticle) async {
        await store.toggleSaved(articleID: article.id)
        await persist()
        snapshot = await store.currentSnapshot()
    }

    private func persist() async {
        guard let persistenceURL else { return }
        do {
            try await store.save(to: persistenceURL)
        } catch {
            errorMessage = "Briefing could not be saved: \(error.localizedDescription)"
        }
    }

    private func subscription(for topic: String) -> TopicSubscription? {
        let normalized = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return snapshot.subscriptions.first { $0.normalizedName == normalized }
    }

    private func updateBriefingAndPersist() async {
        await store.generateBriefing()
        await persist()
        snapshot = await store.currentSnapshot()
    }

    private func pruneStaleArticles() async -> Int {
        let cutoff = Date().addingTimeInterval(-Self.articleRetentionInterval)
        return await store.pruneArticles(olderThan: cutoff)
    }

    public static var defaultPersistenceURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MyDataDC", isDirectory: true)
            .appendingPathComponent("NewsDesk.json")
    }

    private static let articleRetentionInterval: TimeInterval = 7 * 24 * 60 * 60
}
#endif

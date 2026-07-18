import Foundation

public actor NetSphereStore {
    private var snapshot: NetSphereSnapshot

    public init(snapshot: NetSphereSnapshot = .init()) {
        self.snapshot = snapshot
    }

    public func currentSnapshot() -> NetSphereSnapshot { snapshot }

    public func ingest(_ articles: [NewsArticle]) {
        snapshot.articles = NetSphereEngine.deduplicated(snapshot.articles + articles)
    }

    public func upsertSubscription(_ subscription: TopicSubscription) {
        if let index = snapshot.subscriptions.firstIndex(where: { $0.id == subscription.id || $0.normalizedName == subscription.normalizedName }) {
            snapshot.subscriptions[index] = subscription
        } else {
            snapshot.subscriptions.append(subscription)
        }
        snapshot.subscriptions.sort { lhs, rhs in
            if lhs.priority == rhs.priority { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
            return lhs.priority > rhs.priority
        }
    }

    public func removeSubscription(named name: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        snapshot.subscriptions.removeAll { $0.normalizedName == normalizedName }
    }

    @discardableResult
    public func pruneArticles(olderThan cutoff: Date, preservingSaved: Bool = true) -> Int {
        let originalCount = snapshot.articles.count
        snapshot.articles.removeAll { article in
            article.publishedAt < cutoff
                && (!preservingSaved || !snapshot.savedArticleIDs.contains(article.id))
        }
        let retainedIDs = Set(snapshot.articles.map(\.id))
        snapshot.savedArticleIDs.formIntersection(retainedIDs)
        return originalCount - snapshot.articles.count
    }

    public func toggleSaved(articleID: UUID) {
        if snapshot.savedArticleIDs.contains(articleID) {
            snapshot.savedArticleIDs.remove(articleID)
        } else {
            snapshot.savedArticleIDs.insert(articleID)
        }
    }

    @discardableResult
    public func generateBriefing(
        weather: WeatherBrief? = nil,
        markets: [MarketBrief] = [],
        limit: Int = 8,
        now: Date = Date()
    ) -> DailyBriefing {
        let result = NetSphereEngine.briefing(
            from: snapshot.articles,
            subscriptions: snapshot.subscriptions,
            weather: weather,
            markets: markets,
            limit: limit,
            now: now
        )
        snapshot.lastBriefing = result
        return result
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        snapshot = try decoder.decode(NetSphereSnapshot.self, from: Data(contentsOf: url))
    }
}

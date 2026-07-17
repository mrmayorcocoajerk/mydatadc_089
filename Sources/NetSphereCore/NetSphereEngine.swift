import Foundation

public enum NetSphereEngine {
    public static func deduplicated(_ articles: [NewsArticle]) -> [NewsArticle] {
        var seen = Set<String>()
        return articles
            .sorted { lhs, rhs in
                if lhs.publishedAt == rhs.publishedAt { return lhs.source.reliabilityScore > rhs.source.reliabilityScore }
                return lhs.publishedAt > rhs.publishedAt
            }
            .filter { article in
                let key = canonicalKey(for: article)
                return seen.insert(key).inserted
            }
    }

    public static func ranked(
        _ articles: [NewsArticle],
        subscriptions: [TopicSubscription],
        now: Date = Date()
    ) -> [NewsArticle] {
        let active = Dictionary(uniqueKeysWithValues: subscriptions.filter { !$0.isMuted }.map { ($0.normalizedName, $0.priority) })
        return deduplicated(articles).sorted { lhs, rhs in
            let lhsScore = score(lhs, activeTopics: active, now: now)
            let rhsScore = score(rhs, activeTopics: active, now: now)
            if lhsScore == rhsScore { return lhs.publishedAt > rhs.publishedAt }
            return lhsScore > rhsScore
        }
    }

    public static func briefing(
        from articles: [NewsArticle],
        subscriptions: [TopicSubscription],
        weather: WeatherBrief? = nil,
        markets: [MarketBrief] = [],
        limit: Int = 8,
        now: Date = Date()
    ) -> DailyBriefing {
        let selected = Array(ranked(articles, subscriptions: subscriptions, now: now).prefix(max(0, limit)))
        var highlights: [String] = []

        if let alert = weather?.severeAlert, !alert.isEmpty {
            highlights.append("Weather alert: \(alert)")
        }
        if let breaking = selected.first(where: { $0.urgency >= .breaking }) {
            highlights.append("Breaking: \(breaking.headline)")
        }
        if let strongest = markets.max(by: { abs($0.changePercent) < abs($1.changePercent) }) {
            let direction = strongest.changePercent >= 0 ? "up" : "down"
            highlights.append("\(strongest.label) is \(direction) \(String(format: "%.1f", abs(strongest.changePercent)))%")
        }

        return DailyBriefing(
            generatedAt: now,
            articles: selected,
            weather: weather,
            markets: markets,
            highlights: highlights
        )
    }

    public static func breakingArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        deduplicated(articles).filter { $0.urgency >= .breaking }
    }

    public static func matches(_ article: NewsArticle, query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return true }
        if article.headline.lowercased().contains(needle) { return true }
        if article.summary.lowercased().contains(needle) { return true }
        if article.source.name.lowercased().contains(needle) { return true }
        return article.topics.contains { $0.contains(needle) }
    }

    private static func canonicalKey(for article: NewsArticle) -> String {
        if let url = article.canonicalURL {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil
            components?.fragment = nil
            if let normalized = components?.url?.absoluteString.lowercased() {
                return "url:\(normalized)"
            }
        }
        let normalizedHeadline = article.headline
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return "headline:\(normalizedHeadline)"
    }

    private static func score(_ article: NewsArticle, activeTopics: [String: Int], now: Date) -> Double {
        let urgencyScore: Double
        switch article.urgency {
        case .routine: urgencyScore = 0
        case .notable: urgencyScore = 20
        case .breaking: urgencyScore = 50
        case .critical: urgencyScore = 80
        }

        let topicScore = article.topics.reduce(0.0) { partial, topic in
            partial + Double(activeTopics[topic] ?? 0) * 0.4
        }
        let reliabilityScore = article.source.reliabilityScore * 20
        let ageHours = max(0, now.timeIntervalSince(article.publishedAt) / 3600)
        let freshnessScore = max(0, 24 - ageHours)
        return urgencyScore + topicScore + reliabilityScore + freshnessScore
    }
}

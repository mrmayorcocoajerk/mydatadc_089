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
        let muted = Set(subscriptions.filter(\.isMuted).map(\.normalizedName))
        return deduplicated(articles)
            .filter { topics(for: $0).isDisjoint(with: muted) }
            .sorted { lhs, rhs in
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
        if let breaking = selected.first(where: { urgency(for: $0) >= .breaking }) {
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
        deduplicated(articles).filter { urgency(for: $0) >= .breaking }
    }

    public static func matches(_ article: NewsArticle, query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return true }
        if article.headline.lowercased().contains(needle) { return true }
        if article.summary.lowercased().contains(needle) { return true }
        if article.source.name.lowercased().contains(needle) { return true }
        return topics(for: article).contains { $0.contains(needle) }
    }

    public static func topics(for article: NewsArticle) -> Set<String> {
        var topics = article.topics
        topics.insert(article.scope.displayName.lowercased())

        let words = (article.headline + " " + article.summary)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let searchable = " \(words) "
        let rules: [(topic: String, keywords: [String])] = [
            ("business", ["business", "economy", "market", "finance", "company"]),
            ("technology", ["technology", "tech", "ai", "software", "cyber", "digital"]),
            ("science", ["science", "research", "space", "climate", "nasa"]),
            ("health", ["health", "medical", "medicine", "hospital"]),
            ("culture", ["culture", "film", "music", "art", "arts"]),
            ("sports", ["sports", "sport", "game", "tournament"]),
            ("politics", ["politics", "election", "government", "president", "parliament"])
        ]
        for rule in rules where rule.keywords.contains(where: { searchable.contains(" \($0) ") }) {
            topics.insert(rule.topic)
        }
        return topics
    }

    public static func urgency(for article: NewsArticle) -> NewsUrgency {
        let words = (article.headline + " " + article.summary)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let searchable = " \(words) "
        let inferred: NewsUrgency
        if ["emergency", "evacuation", "catastrophic"].contains(where: { searchable.contains(" \($0) ") }) {
            inferred = .critical
        } else if ["breaking", "alert", "warning"].contains(where: { searchable.contains(" \($0) ") }) {
            inferred = .breaking
        } else if ["developing", "live"].contains(where: { searchable.contains(" \($0) ") }) {
            inferred = .notable
        } else {
            inferred = .routine
        }
        return max(article.urgency, inferred)
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
        switch urgency(for: article) {
        case .routine: urgencyScore = 0
        case .notable: urgencyScore = 20
        case .breaking: urgencyScore = 50
        case .critical: urgencyScore = 80
        }

        let topicScore = topics(for: article).reduce(0.0) { partial, topic in
            partial + Double(activeTopics[topic] ?? 0) * 0.4
        }
        let reliabilityScore = article.source.reliabilityScore * 20
        let ageHours = max(0, now.timeIntervalSince(article.publishedAt) / 3600)
        let freshnessScore = max(0, 24 - ageHours)
        return urgencyScore + topicScore + reliabilityScore + freshnessScore
    }
}

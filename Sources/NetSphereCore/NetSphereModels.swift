import Foundation

public enum NewsScope: String, Codable, CaseIterable, Sendable {
    case world, unitedStates, local, business, technology, science, health, culture, sports, politics
}

public enum NewsUrgency: String, Codable, CaseIterable, Sendable, Comparable {
    case routine, notable, breaking, critical

    private var rank: Int {
        switch self {
        case .routine: 0
        case .notable: 1
        case .breaking: 2
        case .critical: 3
        }
    }

    public static func < (lhs: NewsUrgency, rhs: NewsUrgency) -> Bool {
        lhs.rank < rhs.rank
    }
}

public struct NewsSource: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var domain: String
    public var reliabilityScore: Double

    public init(id: UUID = UUID(), name: String, domain: String, reliabilityScore: Double) {
        self.id = id
        self.name = name
        self.domain = domain
        self.reliabilityScore = min(1, max(0, reliabilityScore))
    }
}

public struct NewsArticle: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var headline: String
    public var summary: String
    public var scope: NewsScope
    public var urgency: NewsUrgency
    public var source: NewsSource
    public var publishedAt: Date
    public var canonicalURL: URL?
    public var topics: Set<String>

    public init(
        id: UUID = UUID(),
        headline: String,
        summary: String,
        scope: NewsScope,
        urgency: NewsUrgency = .routine,
        source: NewsSource,
        publishedAt: Date,
        canonicalURL: URL? = nil,
        topics: Set<String> = []
    ) {
        self.id = id
        self.headline = headline
        self.summary = summary
        self.scope = scope
        self.urgency = urgency
        self.source = source
        self.publishedAt = publishedAt
        self.canonicalURL = canonicalURL
        self.topics = Set(topics.map { Self.normalizeTopic($0) }.filter { !$0.isEmpty })
    }

    private static func normalizeTopic(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public struct TopicSubscription: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var isMuted: Bool
    public var priority: Int

    public init(id: UUID = UUID(), name: String, isMuted: Bool = false, priority: Int = 50) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isMuted = isMuted
        self.priority = min(100, max(0, priority))
    }

    public var normalizedName: String { name.lowercased() }
}

public struct WeatherBrief: Codable, Hashable, Sendable {
    public var temperatureFahrenheit: Int
    public var feelsLikeFahrenheit: Int
    public var condition: String
    public var severeAlert: String?

    public init(
        temperatureFahrenheit: Int,
        feelsLikeFahrenheit: Int,
        condition: String,
        severeAlert: String? = nil
    ) {
        self.temperatureFahrenheit = temperatureFahrenheit
        self.feelsLikeFahrenheit = feelsLikeFahrenheit
        self.condition = condition
        self.severeAlert = severeAlert
    }
}

public struct MarketBrief: Codable, Hashable, Sendable {
    public var label: String
    public var changePercent: Double

    public init(label: String, changePercent: Double) {
        self.label = label
        self.changePercent = changePercent
    }
}

public struct DailyBriefing: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var generatedAt: Date
    public var articles: [NewsArticle]
    public var weather: WeatherBrief?
    public var markets: [MarketBrief]
    public var highlights: [String]

    public init(
        id: UUID = UUID(),
        generatedAt: Date,
        articles: [NewsArticle],
        weather: WeatherBrief? = nil,
        markets: [MarketBrief] = [],
        highlights: [String] = []
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.articles = articles
        self.weather = weather
        self.markets = markets
        self.highlights = highlights
    }
}

public struct NetSphereSnapshot: Codable, Equatable, Sendable {
    public var articles: [NewsArticle]
    public var subscriptions: [TopicSubscription]
    public var savedArticleIDs: Set<UUID>
    public var lastBriefing: DailyBriefing?

    public init(
        articles: [NewsArticle] = [],
        subscriptions: [TopicSubscription] = [],
        savedArticleIDs: Set<UUID> = [],
        lastBriefing: DailyBriefing? = nil
    ) {
        self.articles = articles
        self.subscriptions = subscriptions
        self.savedArticleIDs = savedArticleIDs
        self.lastBriefing = lastBriefing
    }
}

import Foundation
import Testing
@testable import NetSphereCore

private let source = NewsSource(name: "NewsDesk Wire", domain: "example.com", reliabilityScore: 0.9)

private func article(
    id: UUID = UUID(),
    headline: String,
    urgency: NewsUrgency = .routine,
    publishedAt: Date = Date(),
    url: String? = nil,
    topics: Set<String> = []
) -> NewsArticle {
    NewsArticle(
        id: id,
        headline: headline,
        summary: "Summary for \(headline)",
        scope: .world,
        urgency: urgency,
        source: source,
        publishedAt: publishedAt,
        canonicalURL: url.flatMap(URL.init(string:)),
        topics: topics
    )
}

@Test func clampsSourceReliabilityAndSubscriptionPriority() {
    #expect(NewsSource(name: "A", domain: "a.com", reliabilityScore: 2).reliabilityScore == 1)
    #expect(TopicSubscription(name: "AI", priority: -4).priority == 0)
}

@Test func deduplicatesTrackingURLs() {
    let first = article(headline: "Same", url: "https://example.com/story?utm_source=a")
    let second = article(headline: "Different headline", url: "https://example.com/story?utm_source=b")
    #expect(NetSphereEngine.deduplicated([first, second]).count == 1)
}

@Test func deduplicatesNormalizedHeadlinesWithoutURL() {
    let first = article(headline: "Apple launches a new device!")
    let second = article(headline: "Apple launches a new device")
    #expect(NetSphereEngine.deduplicated([first, second]).count == 1)
}

@Test func rankingRespectsBreakingUrgencyAndTopics() {
    let now = Date(timeIntervalSince1970: 10_000)
    let routine = article(headline: "Routine AI", publishedAt: now, topics: ["AI"])
    let breaking = article(headline: "Breaking weather", urgency: .breaking, publishedAt: now.addingTimeInterval(-3600), topics: ["weather"])
    let ranked = NetSphereEngine.ranked([routine, breaking], subscriptions: [.init(name: "AI", priority: 100)], now: now)
    #expect(ranked.first?.id == breaking.id)
}

@Test func briefingIncludesFeelsLikeAndAlerts() {
    let now = Date(timeIntervalSince1970: 20_000)
    let breaking = article(headline: "Storm warning", urgency: .critical, publishedAt: now)
    let weather = WeatherBrief(temperatureFahrenheit: 72, feelsLikeFahrenheit: 81, condition: "Humid", severeAlert: "Flash flood warning")
    let briefing = NetSphereEngine.briefing(from: [breaking], subscriptions: [], weather: weather, now: now)
    #expect(briefing.weather?.feelsLikeFahrenheit == 81)
    #expect(briefing.highlights.contains { $0.contains("Flash flood") })
    #expect(briefing.highlights.contains { $0.contains("Storm warning") })
}

@Test func searchMatchesTopicsAndSource() {
    let item = article(headline: "New telescope", topics: ["space"])
    #expect(NetSphereEngine.matches(item, query: "space"))
    #expect(NetSphereEngine.matches(item, query: "NewsDesk"))
    #expect(!NetSphereEngine.matches(item, query: "football"))
}

@Test func storeIngestsDeduplicatedArticles() async {
    let store = NetSphereStore()
    let first = article(headline: "One")
    let second = article(headline: "One!")
    await store.ingest([first, second])
    let snapshot = await store.currentSnapshot()
    #expect(snapshot.articles.count == 1)
}

@Test func persistenceRoundTripPreservesDates() async throws {
    let timestamp = Date(timeIntervalSince1970: 1_234.567)
    let item = article(headline: "Persisted", publishedAt: timestamp)
    let store = NetSphereStore(snapshot: .init(articles: [item]))
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try await store.save(to: url)
    let restored = NetSphereStore()
    try await restored.load(from: url)
    let snapshot = await restored.currentSnapshot()
    #expect(snapshot.articles.first?.publishedAt == timestamp)
}

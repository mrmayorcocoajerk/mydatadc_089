import Foundation
import Testing
@testable import ChrysanthemumCore

@Test
func ruleMatchesSourcePriorityAndSubject() {
    let rule = ChrysanthemumRule(
        name: "Interview",
        eventKind: .attentionRequired,
        source: .productivity,
        subjectPrefix: "career.interview",
        minimumPriority: 60,
        actions: [.activateScene(identifier: "prep")]
    )
    let event = ChrysanthemumEvent(
        kind: .attentionRequired,
        source: .productivity,
        subject: "career.interview.tomorrow",
        priority: 80
    )
    #expect(rule.matches(event))
}

@Test
func ruleRejectsLowPriorityEvent() {
    let rule = ChrysanthemumRule(
        name: "Urgent",
        eventKind: .attentionRequired,
        minimumPriority: 80,
        actions: [.openDistrict(.grandHall)]
    )
    let event = ChrysanthemumEvent(kind: .attentionRequired, source: .commerce, subject: "return", priority: 40)
    #expect(!rule.matches(event))
}

@Test
func routerProducesActionsInRuleOrder() async throws {
    let low = ChrysanthemumRule(
        name: "B",
        eventKind: .dataChanged,
        minimumPriority: 10,
        actions: [.refreshPanel(identifier: "low")]
    )
    let high = ChrysanthemumRule(
        name: "A",
        eventKind: .dataChanged,
        minimumPriority: 80,
        actions: [.refreshPanel(identifier: "high")]
    )
    let router = ChrysanthemumRouter(rules: [low, high])
    let event = ChrysanthemumEvent(kind: .dataChanged, source: .netSphere, subject: "weather", priority: 90)
    let actions = try await router.publish(event)
    #expect(actions.map(\.action) == [.refreshPanel(identifier: "high"), .refreshPanel(identifier: "low")])
}

@Test
func routerRejectsDuplicateEvent() async throws {
    let router = ChrysanthemumRouter()
    let event = ChrysanthemumEvent(kind: .dataChanged, source: .apple, subject: "music")
    _ = try await router.publish(event)
    await #expect(throws: ChrysanthemumError.duplicateEvent) {
        _ = try await router.publish(event)
    }
}

@Test
func routerSupportsRuleLifecycle() async throws {
    let router = ChrysanthemumRouter()
    var rule = ChrysanthemumRule(name: "Rule", eventKind: .dataChanged, actions: [.openDistrict(.apple)])
    try await router.register(rule)
    #expect(await router.allRules().count == 1)
    rule.isEnabled = false
    try await router.update(rule)
    let event = ChrysanthemumEvent(kind: .dataChanged, source: .apple, subject: "library")
    #expect(try await router.publish(event).isEmpty)
    try await router.removeRule(id: rule.id)
    #expect(await router.allRules().isEmpty)
}

@Test
func routerFiltersJournalByDistrict() async throws {
    let router = ChrysanthemumRouter()
    _ = try await router.publish(ChrysanthemumEvent(kind: .dataChanged, source: .apple, subject: "photos"))
    _ = try await router.publish(ChrysanthemumEvent(kind: .dataChanged, source: .commerce, destination: .finance, subject: "receipt"))
    let finance = await router.recentEvents(district: .finance)
    #expect(finance.count == 1)
    #expect(finance.first?.subject == "receipt")
}

@Test
func dayOneWeatherRuleRefreshesGrandHallPanel() async throws {
    let router = ChrysanthemumRouter(rules: ChrysanthemumTemplates.dayOneRules())
    let event = ChrysanthemumEvent(kind: .dataChanged, source: .netSphere, subject: "weather.current", priority: 25)
    let actions = try await router.publish(event)
    #expect(actions.contains { $0.action == .refreshPanel(identifier: "grandHall.weather") })
}

@Test
func prioritiesAreClamped() {
    let event = ChrysanthemumEvent(kind: .dataChanged, source: .digiSphere, subject: "sync", priority: 900)
    let rule = ChrysanthemumRule(name: "Clamp", eventKind: .dataChanged, minimumPriority: -20, actions: [])
    #expect(event.priority == 100)
    #expect(rule.minimumPriority == 0)
}

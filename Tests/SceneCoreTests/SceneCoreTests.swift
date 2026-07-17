import Foundation
import Testing
@testable import SceneCore

private func date(hour: Int) -> Date {
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = 2026
    components.month = 7
    components.day = 16
    components.hour = hour
    return components.date!
}

@Test func workFocusOutranksMorningTime() {
    let engine = SceneEngine()
    let scenes = [SceneTemplate.morning.makeScene(), SceneTemplate.work.makeScene()]
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let match = engine.bestMatch(in: scenes, context: .init(date: date(hour: 8), focusModeName: "work"), calendar: calendar)
    #expect(match?.scene.kind == .work)
    #expect(match?.score == 100)
}

@Test func overnightSleepRangeMatchesAfterMidnight() {
    let engine = SceneEngine()
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let scene = SceneTemplate.sleep.makeScene()
    let match = engine.match(scene: scene, context: .init(date: date(hour: 2)), calendar: calendar)
    #expect(match?.scene.kind == .sleep)
}

@Test func manualOnlySceneDoesNotAutoActivate() {
    let engine = SceneEngine()
    let scene = ManorScene(name: "Custom", kind: .custom, gallery: .init(name: "Custom"))
    #expect(engine.match(scene: scene, context: .init()) == nil)
}

@Test func templatesHaveUniqueNames() {
    let names = SceneTemplate.allCases.map { $0.makeScene().name }
    #expect(Set(names).count == names.count)
}

@Test func sceneStoreRoundTripsExactDates() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("scenes.json")
    let timestamp = Date(timeIntervalSince1970: 1_789_000_000.125)
    let scene = SceneTemplate.studio.makeScene(now: timestamp)
    let store = SceneStore(fileURL: url)
    try await store.upsert(scene)
    let loaded = try await store.load()
    #expect(loaded == [scene])
}

@Test func duplicateSceneNamesAreRejected() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = SceneStore(fileURL: directory.appendingPathComponent("scenes.json"))
    try await store.upsert(SceneTemplate.work.makeScene())
    await #expect(throws: SceneEngineError.duplicateScene) {
        try await store.upsert(SceneTemplate.work.makeScene())
    }
}

@Test func removingUnknownSceneFails() async {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = SceneStore(fileURL: directory.appendingPathComponent("scenes.json"))
    await #expect(throws: SceneEngineError.sceneNotFound) {
        try await store.remove(id: UUID())
    }
}

@Test func activationHistoryRecordsEvents() async {
    let history = SceneActivationHistory()
    let sceneID = UUID()
    let timestamp = Date(timeIntervalSince1970: 100)
    await history.record(sceneID: sceneID, reason: "focus", at: timestamp)
    let values = await history.all()
    #expect(values.count == 1)
    #expect(values.first?.sceneID == sceneID)
    #expect(values.first?.activatedAt == timestamp)
    #expect(values.first?.reason == "focus")
}

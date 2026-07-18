import Foundation
import Testing
@testable import VitalsCore

@Test func sevenDaySummaryCountsOnlyRecentEntries() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let now = Date(timeIntervalSince1970: 1_735_689_600)
    let entries = [
        VitalsEntry(date: now, sleepHours: 8, waterGlasses: 6, activeMinutes: 30),
        VitalsEntry(date: now.addingTimeInterval(3_600), sleepHours: 7, waterGlasses: 2, activeMinutes: 10),
        VitalsEntry(date: now.addingTimeInterval(-2 * 86_400), sleepHours: 6, waterGlasses: 8, activeMinutes: 50),
        VitalsEntry(date: now.addingTimeInterval(-8 * 86_400), sleepHours: 20, waterGlasses: 20, activeMinutes: 500)
    ]

    let summary = VitalsEngine.sevenDaySummary(in: VitalsSnapshot(entries: entries), now: now, calendar: calendar)

    #expect(summary.daysLogged == 2)
    #expect(summary.averageSleepHours == 7)
    #expect(summary.totalWaterGlasses == 16)
    #expect(summary.totalActiveMinutes == 90)
}

@Test func storeValidatesUpdatesAndDeletesEntries() async throws {
    let id = UUID()
    let store = VitalsStore()
    try await store.upsert(VitalsEntry(id: id, sleepHours: 7, waterGlasses: 5, activeMinutes: 20))
    try await store.upsert(VitalsEntry(id: id, sleepHours: 8, waterGlasses: 6, activeMinutes: 30, note: "Good day"))
    var snapshot = await store.currentSnapshot()
    #expect(snapshot.entries.count == 1)
    #expect(snapshot.entries.first?.note == "Good day")

    await #expect(throws: VitalsError.invalidSleepHours) {
        try await store.upsert(VitalsEntry(sleepHours: 25, waterGlasses: 5, activeMinutes: 20))
    }

    await store.delete(id: id)
    snapshot = await store.currentSnapshot()
    #expect(snapshot.entries.isEmpty)
}

@Test func storePersistsAndRestoresJournal() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("VitalsStudio.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    let entry = VitalsEntry(date: Date(timeIntervalSince1970: 1_735_689_600), sleepHours: 7.5, waterGlasses: 9, activeMinutes: 45, note: "Steady")
    let source = VitalsStore(snapshot: VitalsSnapshot(entries: [entry]))

    try await source.save(to: url)
    let restored = VitalsStore()
    try await restored.load(from: url)

    let restoredSnapshot = await restored.currentSnapshot()
    let sourceSnapshot = await source.currentSnapshot()
    #expect(restoredSnapshot == sourceSnapshot)
}

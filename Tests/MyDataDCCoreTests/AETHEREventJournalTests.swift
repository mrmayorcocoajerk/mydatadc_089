import Foundation
import Testing
@testable import MyDataDCCore

@Test
func eventJournalPersistsRestoresAndContinuesSequence() async throws {
    let store = InMemoryAETHEREventJournalStore()
    let first = AETHEREventJournal(store: store)

    let firstRecord = try await first.append(
        .workspaceOpened("career"),
        at: Date(timeIntervalSince1970: 100)
    )
    #expect(firstRecord?.sequence == 1)

    let restored = AETHEREventJournal(store: store)
    try await restored.restore()
    let secondRecord = try await restored.append(
        .objectUpdated("resume"),
        at: Date(timeIntervalSince1970: 200)
    )

    #expect(secondRecord?.sequence == 2)
    #expect(await restored.events() == [
        .workspaceOpened("career"),
        .objectUpdated("resume")
    ])
}

@Test
func eventJournalCapacityRetainsNewestRecords() async throws {
    let journal = AETHEREventJournal(capacity: 2)

    try await journal.append(.workspaceOpened("career"))
    try await journal.append(.workspaceOpened("money"))
    try await journal.append(.workspaceClosed("career"))

    let records = await journal.snapshot()
    #expect(records.map(\.sequence) == [2, 3])
    #expect(records.map(\.event) == [
        .workspaceOpened("money"),
        .workspaceClosed("career")
    ])
}

@Test
func eventJournalSubscriptionPersistsPublishedEventsUntilStopped() async throws {
    let bus = AETHEREventBus()
    let journal = AETHEREventJournal()
    let subscription = AETHEREventJournalSubscription(bus: bus, journal: journal)

    await subscription.start()
    await bus.publish(.workspaceOpened("career"))
    await subscription.stop()
    await bus.publish(.workspaceClosed("career"))

    #expect(await journal.events() == [.workspaceOpened("career")])
    #expect(!(await subscription.isActive()))
}

@Test
func eventJournalReplaysInSequenceOrder() async throws {
    let journal = AETHEREventJournal()
    try await journal.append(.workspaceOpened("career"))
    try await journal.append(.objectUpdated("resume"))

    let bus = AETHEREventBus()
    let history = AETHEREventHistory()
    let bridge = AETHEREventHistorySubscription(bus: bus, history: history)
    await bridge.start()

    await journal.replay(into: bus)

    #expect(await history.snapshot() == [
        .workspaceOpened("career"),
        .objectUpdated("resume")
    ])
}

@Test
func jsonEventJournalStoreCreatesParentDirectoryAndRoundTrips() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = root.appendingPathComponent("AETHER/events.json")
    let store = JSONFileAETHEREventJournalStore(url: url)
    let journal = AETHEREventJournal(store: store)

    try await journal.append(.workspaceOpened("career"))

    let restored = AETHEREventJournal(store: JSONFileAETHEREventJournalStore(url: url))
    try await restored.restore()

    #expect(await restored.events() == [.workspaceOpened("career")])
    #expect(FileManager.default.fileExists(atPath: url.path))
}

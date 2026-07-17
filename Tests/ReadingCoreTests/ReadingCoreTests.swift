import Foundation
import Testing
@testable import ReadingCore

@Test func providersIncludeAudibleAndAppleBooks() {
    #expect(ReadingProvider.allCases.contains(.audible))
    #expect(ReadingProvider.allCases.contains(.appleBooks))
}

@Test func progressIsClampedAndRemainingTimeCalculated() {
    let progress = ReadingProgress(
        fractionCompleted: 1.3,
        positionSeconds: 3_000,
        durationSeconds: 7_200
    )
    #expect(progress.fractionCompleted == 1)
    #expect(progress.remainingSeconds == 4_200)
}

@Test func duplicateProviderIdentifiersAreRejected() async throws {
    let coordinator = ReadingCoordinator()
    try await coordinator.addItem(.init(
        provider: .audible,
        format: .audiobook,
        title: "Book One",
        author: "Author",
        externalIdentifier: "ASIN-1"
    ))
    await #expect(throws: ReadingError.duplicateExternalIdentifier("asin-1")) {
        try await coordinator.addItem(.init(
            provider: .audible,
            format: .audiobook,
            title: "Duplicate",
            author: "Author",
            externalIdentifier: "asin-1"
        ))
    }
}

@Test func sameIdentifierAcrossProvidersIsAllowed() async throws {
    let coordinator = ReadingCoordinator()
    try await coordinator.addItem(.init(provider: .audible, format: .audiobook, title: "Audio", author: "A", externalIdentifier: "1"))
    try await coordinator.addItem(.init(provider: .appleBooks, format: .ebook, title: "Book", author: "A", externalIdentifier: "1"))
    #expect(await coordinator.itemList().count == 2)
}

@Test func latestActiveItemIsSuggested() async throws {
    let coordinator = ReadingCoordinator()
    let old = ReadingItem(
        provider: .audible,
        format: .audiobook,
        title: "Old",
        author: "A",
        status: .inProgress,
        progress: .init(fractionCompleted: 0.4, updatedAt: Date(timeIntervalSince1970: 100))
    )
    let current = ReadingItem(
        provider: .kindle,
        format: .ebook,
        title: "Current",
        author: "B",
        status: .paused,
        progress: .init(fractionCompleted: 0.2, updatedAt: Date(timeIntervalSince1970: 200))
    )
    try await coordinator.addItem(old)
    try await coordinator.addItem(current)
    #expect(await coordinator.continueReading()?.id == current.id)
}

@Test func bookmarkRequiresKnownItem() async {
    let coordinator = ReadingCoordinator()
    let bookmark = ReadingBookmark(itemID: UUID(), location: "Chapter 4")
    await #expect(throws: ReadingError.unknownItem(bookmark.itemID)) {
        try await coordinator.addBookmark(bookmark)
    }
}

@Test func summaryIncludesSessionMinutes() async throws {
    let coordinator = ReadingCoordinator()
    let item = ReadingItem(provider: .audible, format: .audiobook, title: "Listen", author: "A", status: .inProgress)
    try await coordinator.addItem(item)
    try await coordinator.recordSession(.init(
        itemID: item.id,
        startedAt: Date(timeIntervalSince1970: 0),
        endedAt: Date(timeIntervalSince1970: 1_800),
        progressDelta: 0.1
    ))
    let summary = await coordinator.summary()
    #expect(summary.inProgressCount == 1)
    #expect(summary.totalSessionMinutes == 30)
    #expect(summary.currentItem?.id == item.id)
}

@Test func searchMatchesTagsAndAuthors() async throws {
    let coordinator = ReadingCoordinator()
    try await coordinator.addItem(.init(provider: .pdf, format: .document, title: "Architecture Notes", author: "Ada", tags: ["MyDataDC"]))
    #expect(await coordinator.search("ada").count == 1)
    #expect(await coordinator.search("mydatadc").count == 1)
}

@Test func persistenceRoundTripPreservesDates() async throws {
    let date = Date(timeIntervalSince1970: 1_234.567)
    let item = ReadingItem(
        provider: .audible,
        format: .audiobook,
        title: "Night Book",
        author: "Author",
        status: .inProgress,
        progress: .init(fractionCompleted: 0.5, updatedAt: date)
    )
    let snapshot = ReadingSnapshot(items: [item])
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("reading.json")
    let store = ReadingStore(url: url)
    try await store.save(snapshot)
    #expect(try await store.load() == snapshot)
}

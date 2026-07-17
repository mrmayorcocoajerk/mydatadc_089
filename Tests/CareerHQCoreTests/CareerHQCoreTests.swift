import Foundation
import Testing
@testable import CareerHQCore

private func sample(
    employer: String = "Publicis Sapient",
    role: String = "Global Mobility Director",
    status: ApplicationStatus = .applied,
    favorite: Bool = false,
    updated: Date = .now
) -> CareerApplication {
    .init(
        employer: employer,
        role: role,
        location: "New York, NY",
        workArrangement: .hybrid,
        status: status,
        lastUpdated: updated,
        notes: "Global immigration and mobility leadership",
        isFavorite: favorite
    )
}

@Test func storeAddsAndNormalizesApplications() async throws {
    let store = CareerHQStore()
    let added = try await store.add(sample(employer: "  Meta  ", role: " Program Manager "))
    #expect(added.employer == "Meta")
    #expect(added.role == "Program Manager")
    #expect(await store.allApplications().count == 1)
}

@Test func storeRejectsMissingRequiredFields() async {
    let store = CareerHQStore()
    await #expect(throws: CareerHQStoreError.invalidEmployer) {
        try await store.add(sample(employer: "   "))
    }
    await #expect(throws: CareerHQStoreError.invalidRole) {
        try await store.add(sample(role: ""))
    }
}

@Test func manualStatusOverrideUpdatesApplication() async throws {
    let application = sample(status: .saved)
    let store = CareerHQStore(applications: [application])
    try await store.setStatus(.interview, for: application.id)
    let updated = await store.allApplications().first
    #expect(updated?.status == .interview)
}

@Test func filterSearchesSortsAndHonorsFavorites() {
    let older = sample(employer: "Meta", role: "Mobility Manager", favorite: true, updated: Date(timeIntervalSince1970: 100))
    let newer = sample(employer: "Apple", role: "People Operations", status: .interview, updated: Date(timeIntervalSince1970: 200))
    let applications = [older, newer]

    var filter = CareerHQFilter(searchText: "Meta")
    #expect(filter.apply(to: applications).map(\.employer) == ["Meta"])

    filter = CareerHQFilter(statuses: [.interview])
    #expect(filter.apply(to: applications).map(\.employer) == ["Apple"])

    filter = CareerHQFilter(favoritesOnly: true)
    #expect(filter.apply(to: applications).map(\.employer) == ["Meta"])
}

@Test func summaryCountsPipelineStages() {
    let applications = [
        sample(status: .applied),
        sample(status: .interview),
        sample(status: .finalInterview),
        sample(status: .offer),
        sample(status: .accepted),
        sample(status: .rejected)
    ]
    let summary = CareerHQSummary(applications: applications)
    #expect(summary.total == 6)
    #expect(summary.active == 4)
    #expect(summary.interviews == 2)
    #expect(summary.offers == 1)
    #expect(summary.accepted == 1)
}

@Test func persistenceRoundTripPreservesApplications() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("career-hq.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    let fixedDate = Date(timeIntervalSince1970: 1_000)
    let original = CareerApplication(employer: "Red Bull", role: "Global Mobility Lead", location: "New York, NY", workArrangement: .hybrid, status: .applied, dateAdded: fixedDate, lastUpdated: fixedDate, notes: "Global immigration and mobility leadership", isFavorite: true)
    let writer = CareerHQStore(persistenceURL: url)
    let stored = try await writer.add(original)

    let reader = CareerHQStore(persistenceURL: url)
    try await reader.load()
    let restored = await reader.allApplications()
    #expect(restored == [stored])
}

@Test func analyticsCalculatesRatesAndOverdueFollowUps() {
    let now = Date(timeIntervalSince1970: 10_000)
    let applications = [
        CareerApplication(employer: "A", role: "One", status: .applied, followUpDate: Date(timeIntervalSince1970: 9_000)),
        CareerApplication(employer: "B", role: "Two", status: .interview),
        CareerApplication(employer: "C", role: "Three", status: .offer),
        CareerApplication(employer: "D", role: "Four", status: .saved)
    ]
    let analytics = CareerHQAnalytics(applications: applications, now: now)
    #expect(analytics.total == 4)
    #expect(analytics.responseRate == 2.0 / 3.0)
    #expect(analytics.interviewRate == 2.0 / 3.0)
    #expect(analytics.offerRate == 0.5)
    #expect(analytics.overdueFollowUps == 1)
}

@Test func csvRoundTripPreservesPortableFields() throws {
    let fixed = Date(timeIntervalSince1970: 1_700_000_000)
    let original = CareerApplication(employer: "Acme, Inc.", role: "Director \"People\"", location: "New York", workArrangement: .remote, status: .interview, dateAdded: fixed, dateApplied: fixed, lastUpdated: fixed, followUpDate: fixed, sourceURL: URL(string: "https://example.com/job"), notes: "Line one\nLine two", isFavorite: true)
    let csv = CareerHQCSV.export([original])
    let restored = try CareerHQCSV.importApplications(from: csv, now: fixed)
    #expect(restored.count == 1)
    #expect(restored[0].employer == original.employer)
    #expect(restored[0].role == original.role)
    #expect(restored[0].notes == original.notes)
    #expect(restored[0].followUpDate == original.followUpDate)
}

@Test func statusAndFollowUpCreateActivityHistory() async throws {
    let application = sample(status: .saved)
    let store = CareerHQStore(applications: [application])
    try await store.setStatus(.applied, for: application.id)
    try await store.scheduleFollowUp(on: Date(timeIntervalSince1970: 2_000), for: application.id)
    let updated = try #require(await store.allApplications().first)
    #expect(updated.activities.count == 2)
    #expect(updated.activities[0].kind == .statusChanged)
    #expect(updated.activities[1].kind == .followUpScheduled)
}

@Test func legacyJSONWithoutMilestoneFourFieldsStillLoads() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("career-hq.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let id = UUID()
    let json = """
    [{"id":"\(id.uuidString)","employer":"Legacy Co","role":"Legacy Role","location":"","workArrangement":"Hybrid","status":"Saved","compensation":{"currencyCode":"USD"},"dateAdded":1000000,"lastUpdated":1000000,"notes":"","documentReferences":[],"isFavorite":false}]
    """
    try Data(json.utf8).write(to: url)
    let store = CareerHQStore(persistenceURL: url)
    try await store.load()
    let loaded = try #require(await store.allApplications().first)
    #expect(loaded.followUpDate == nil)
    #expect(loaded.activities.isEmpty)
}

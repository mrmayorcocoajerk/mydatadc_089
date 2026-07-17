import Foundation
import Testing
import GalleryCore
import LivingEnvironmentCore
@testable import LivingPanelsCore

@Test func refreshesRegisteredPanel() async throws {
    let panel = GalleryPanel(kind: .custom, title: "Status", origin: .init(column: 0, row: 0), size: .small)
    let coordinator = LivingPanelCoordinator()
    try await coordinator.register(.init(panel: panel, policy: .interval(60)))
    await coordinator.install(ClosurePanelProvider(supportedKind: .custom) { panel, date in
        PanelSnapshot(panelID: panel.id, title: "Ready", updatedAt: date)
    })

    let result = try await coordinator.refresh(panelID: panel.id, at: Date(timeIntervalSince1970: 10))
    #expect(result.title == "Ready")
}

@Test func rejectsDuplicateRegistration() async throws {
    let panel = GalleryPanel(kind: .custom, title: "Status", origin: .init(column: 0, row: 0), size: .small)
    let coordinator = LivingPanelCoordinator()
    try await coordinator.register(.init(panel: panel, policy: .manual))
    await #expect(throws: PanelRuntimeError.duplicateRegistration) {
        try await coordinator.register(.init(panel: panel, policy: .manual))
    }
}

@Test func refreshesOnlyDueIntervalPanels() async throws {
    let date = Date(timeIntervalSince1970: 1_000)
    let due = GalleryPanel(kind: .career, title: "Career", origin: .init(column: 0, row: 0), size: .small)
    let manual = GalleryPanel(kind: .finance, title: "Finance", origin: .init(column: 1, row: 0), size: .small)
    let coordinator = LivingPanelCoordinator()

    try await coordinator.register(.init(panel: due, policy: .interval(30)))
    try await coordinator.register(.init(panel: manual, policy: .manual))
    await coordinator.install(ClosurePanelProvider(supportedKind: .career) { panel, now in
        PanelSnapshot(panelID: panel.id, title: "Career", updatedAt: now)
    })
    await coordinator.install(ClosurePanelProvider(supportedKind: .finance) { panel, now in
        PanelSnapshot(panelID: panel.id, title: "Finance", updatedAt: now)
    })

    let values = await coordinator.refreshDuePanels(at: date)
    #expect(values.map(\.panelID) == [due.id])
}

@Test func staleSnapshotIsDerivedWithoutMutatingStoredValue() async throws {
    let panel = GalleryPanel(kind: .custom, title: "Status", origin: .init(column: 0, row: 0), size: .small)
    let coordinator = LivingPanelCoordinator()
    try await coordinator.register(.init(panel: panel, policy: .manual))
    await coordinator.install(ClosurePanelProvider(supportedKind: .custom) { panel, date in
        PanelSnapshot(panelID: panel.id, title: "Fresh", updatedAt: date, expiresAt: date.addingTimeInterval(10))
    })
    let start = Date(timeIntervalSince1970: 100)
    _ = try await coordinator.refresh(panelID: panel.id, at: start)

    let stale = await coordinator.snapshot(for: panel.id, at: start.addingTimeInterval(11))
    let fresh = await coordinator.snapshot(for: panel.id, at: start.addingTimeInterval(5))
    #expect(stale?.health == .stale)
    #expect(fresh?.health == .nominal)
}

@Test func weatherPanelPromotesFeelsLikeAndAlerts() async throws {
    let panel = GalleryPanel(kind: .weather, title: "Weather", origin: .init(column: 0, row: 0), size: .large, priority: 5)
    let provider = WeatherPanelProvider {
        WeatherSnapshot(
            locationName: "New York",
            temperatureFahrenheit: 72,
            feelsLikeFahrenheit: 88,
            highFahrenheit: 91,
            lowFahrenheit: 69,
            condition: .extremeHeat,
            humidityPercent: 71,
            windMilesPerHour: 12,
            precipitationChancePercent: 20,
            uvIndex: 9
        )
    }

    let snapshot = try await provider.snapshot(for: panel, at: Date(timeIntervalSince1970: 1))
    #expect(snapshot.subtitle?.contains("Feels like 88°") == true)
    #expect(snapshot.health == .degraded)
    #expect(snapshot.priority == 100)
}

@Test func snapshotsSortByPriorityThenRecency() async throws {
    let low = GalleryPanel(kind: .career, title: "Career", origin: .init(column: 0, row: 0), size: .small)
    let high = GalleryPanel(kind: .finance, title: "Finance", origin: .init(column: 1, row: 0), size: .small)
    let coordinator = LivingPanelCoordinator()
    try await coordinator.register(.init(panel: low, policy: .interval(1)))
    try await coordinator.register(.init(panel: high, policy: .interval(1)))
    await coordinator.install(ClosurePanelProvider(supportedKind: .career) { panel, date in
        PanelSnapshot(panelID: panel.id, title: "Career", priority: 1, updatedAt: date)
    })
    await coordinator.install(ClosurePanelProvider(supportedKind: .finance) { panel, date in
        PanelSnapshot(panelID: panel.id, title: "Finance", priority: 10, updatedAt: date)
    })

    let values = await coordinator.refreshDuePanels(at: Date(timeIntervalSince1970: 1))
    #expect(values.map(\.panelID) == [high.id, low.id])
}

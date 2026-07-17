import Foundation
import GalleryCore

public actor LivingPanelCoordinator {
    private var registrations: [UUID: PanelRegistration] = [:]
    private var providers: [PanelKind: any PanelSnapshotProvider] = [:]
    private var snapshots: [UUID: PanelSnapshot] = [:]

    public init() {}

    public func register(_ registration: PanelRegistration) throws {
        guard registrations[registration.id] == nil else {
            throw PanelRuntimeError.duplicateRegistration
        }
        registrations[registration.id] = registration
    }

    public func unregister(panelID: UUID) {
        registrations[panelID] = nil
        snapshots[panelID] = nil
    }

    public func install(_ provider: any PanelSnapshotProvider) {
        providers[provider.supportedKind] = provider
    }

    public func refresh(panelID: UUID, at date: Date = .now) async throws -> PanelSnapshot {
        guard let registration = registrations[panelID] else {
            throw PanelRuntimeError.unknownPanel
        }
        guard let provider = providers[registration.panel.kind] else {
            throw PanelRuntimeError.noProvider
        }

        let snapshot = try await provider.snapshot(for: registration.panel, at: date)
        snapshots[panelID] = snapshot
        return snapshot
    }

    public func refreshDuePanels(at date: Date = .now) async -> [PanelSnapshot] {
        var refreshed: [PanelSnapshot] = []

        for registration in registrations.values {
            guard isDue(registration, at: date) else { continue }
            guard let snapshot = try? await refresh(panelID: registration.id, at: date) else { continue }
            refreshed.append(snapshot)
        }

        return refreshed.sorted(by: Self.snapshotOrder)
    }

    public func currentSnapshots(at date: Date = .now) -> [PanelSnapshot] {
        snapshots.values
            .map { $0.evaluated(at: date) }
            .sorted(by: Self.snapshotOrder)
    }

    public func snapshot(for panelID: UUID, at date: Date = .now) -> PanelSnapshot? {
        snapshots[panelID]?.evaluated(at: date)
    }

    private func isDue(_ registration: PanelRegistration, at date: Date) -> Bool {
        switch registration.policy {
        case .manual, .eventDriven:
            return false
        case .interval(let interval):
            guard let existing = snapshots[registration.id] else { return true }
            return date.timeIntervalSince(existing.updatedAt) >= max(1, interval)
        }
    }

    private static func snapshotOrder(_ lhs: PanelSnapshot, _ rhs: PanelSnapshot) -> Bool {
        if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
        return lhs.updatedAt > rhs.updatedAt
    }
}

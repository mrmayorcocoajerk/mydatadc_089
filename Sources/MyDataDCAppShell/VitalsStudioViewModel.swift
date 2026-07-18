import Foundation
import VitalsCore

#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class VitalsStudioViewModel: ObservableObject {
    @Published public private(set) var snapshot = VitalsSnapshot()
    @Published public private(set) var errorMessage: String?

    public let store: VitalsStore
    private let persistenceURL: URL?

    public init(
        store: VitalsStore = VitalsStore(),
        persistenceURL: URL? = VitalsStudioViewModel.defaultPersistenceURL
    ) {
        self.store = store
        self.persistenceURL = persistenceURL
    }

    public static var defaultPersistenceURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MyDataDC", isDirectory: true)
            .appendingPathComponent("VitalsStudio.json")
    }

    public var summary: VitalsSummary { VitalsEngine.sevenDaySummary(in: snapshot) }
    public var recentEntries: [VitalsEntry] { VitalsEngine.recentEntries(in: snapshot) }

    public func load() async {
        do {
            if let persistenceURL { try await store.load(from: persistenceURL) }
            snapshot = await store.currentSnapshot()
            errorMessage = nil
        } catch {
            errorMessage = "Vitals Studio could not load its private journal."
        }
    }

    public func saveEntry(
        id: UUID? = nil,
        date: Date,
        sleepHours: Double,
        waterGlasses: Int,
        activeMinutes: Int,
        note: String
    ) async throws {
        try await store.upsert(VitalsEntry(
            id: id ?? UUID(),
            date: date,
            sleepHours: sleepHours,
            waterGlasses: waterGlasses,
            activeMinutes: activeMinutes,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        try await synchronizeAndSave()
    }

    public func deleteEntry(id: UUID) async throws {
        await store.delete(id: id)
        try await synchronizeAndSave()
    }

    private func synchronizeAndSave() async throws {
        if let persistenceURL { try await store.save(to: persistenceURL) }
        snapshot = await store.currentSnapshot()
        errorMessage = nil
    }
}
#endif

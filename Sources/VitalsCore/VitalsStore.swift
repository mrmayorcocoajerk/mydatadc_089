import Foundation

public actor VitalsStore {
    private var snapshot: VitalsSnapshot

    public init(snapshot: VitalsSnapshot = VitalsSnapshot()) {
        self.snapshot = snapshot
    }

    public func currentSnapshot() -> VitalsSnapshot { snapshot }

    public func upsert(_ entry: VitalsEntry) throws {
        guard entry.sleepHours.isFinite, (0...24).contains(entry.sleepHours) else { throw VitalsError.invalidSleepHours }
        guard (0...100).contains(entry.waterGlasses) else { throw VitalsError.invalidWaterGlasses }
        guard (0...1_440).contains(entry.activeMinutes) else { throw VitalsError.invalidActiveMinutes }
        if let index = snapshot.entries.firstIndex(where: { $0.id == entry.id }) {
            snapshot.entries[index] = entry
        } else {
            snapshot.entries.append(entry)
        }
    }

    public func delete(id: UUID) {
        snapshot.entries.removeAll { $0.id == id }
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        snapshot = try decoder.decode(VitalsSnapshot.self, from: Data(contentsOf: url))
    }
}

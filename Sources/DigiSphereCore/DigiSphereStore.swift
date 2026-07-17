import Foundation

public actor DigiSphereStore {
    private var snapshot: DigiSphereSnapshot

    public init(snapshot: DigiSphereSnapshot = .init()) {
        self.snapshot = snapshot
    }

    public func currentSnapshot() -> DigiSphereSnapshot { snapshot }

    public func upsert(device: DeviceRecord) {
        if let index = snapshot.devices.firstIndex(where: { $0.id == device.id }) {
            snapshot.devices[index] = device
        } else {
            snapshot.devices.append(device)
        }
    }

    public func removeDevice(id: UUID) {
        snapshot.devices.removeAll { $0.id == id }
        snapshot.backups.removeAll { $0.deviceID == id }
        snapshot.continuitySessions.removeAll {
            $0.sourceDeviceID == id || $0.destinationDeviceID == id
        }
    }

    public func record(backup: BackupRecord) {
        snapshot.backups.append(backup)
    }

    public func begin(session: ContinuitySession) {
        snapshot.continuitySessions.removeAll {
            $0.completedAt == nil && $0.activityID == session.activityID
        }
        snapshot.continuitySessions.append(session)
    }

    public func completeSession(id: UUID, at date: Date = Date()) {
        guard let index = snapshot.continuitySessions.firstIndex(where: { $0.id == id }) else { return }
        snapshot.continuitySessions[index].completedAt = date
    }

    public func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        snapshot = try decoder.decode(DigiSphereSnapshot.self, from: Data(contentsOf: url))
    }
}

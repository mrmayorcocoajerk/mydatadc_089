import Foundation
import Testing
@testable import DigiSphereCore

private func device(
    id: UUID = UUID(),
    kind: DeviceKind = .mac,
    connection: ConnectionState = .online,
    battery: Int? = 80,
    charging: Bool = false,
    total: Int64 = 1_000,
    available: Int64 = 500,
    lastSeen: Date = Date()
) -> DeviceRecord {
    .init(
        id: id,
        name: "Test Device",
        kind: kind,
        operatingSystem: "26.0",
        connection: connection,
        batteryPercent: battery,
        isCharging: charging,
        totalStorageBytes: total,
        availableStorageBytes: available,
        lastSeen: lastSeen
    )
}

@Test func clampsBatteryAndStorage() {
    let record = device(battery: 140, total: 100, available: 120)
    #expect(record.batteryPercent == 100)
    #expect(record.availableStorageBytes == 100)
    #expect(record.storageUtilization == 0)
}

@Test func emitsBatteryStorageAndBackupAlerts() {
    let now = Date(timeIntervalSince1970: 10_000)
    let record = device(battery: 10, total: 100, available: 5, lastSeen: now)
    let snapshot = DigiSphereSnapshot(devices: [record])
    let alerts = DigiSphereEngine.alerts(snapshot: snapshot, now: now)
    #expect(alerts.contains { $0.kind == .lowBattery })
    #expect(alerts.contains { $0.kind == .storagePressure })
    #expect(alerts.contains { $0.kind == .staleBackup })
}

@Test func chargingSuppressesLowBatteryAlert() {
    let now = Date(timeIntervalSince1970: 10_000)
    let record = device(battery: 5, charging: true, lastSeen: now)
    let alerts = DigiSphereEngine.alerts(snapshot: .init(devices: [record]), now: now)
    #expect(!alerts.contains { $0.kind == .lowBattery })
}

@Test func failedBackupRaisesSyncFailure() {
    let now = Date(timeIntervalSince1970: 10_000)
    let record = device(lastSeen: now)
    let backup = BackupRecord(deviceID: record.id, completedAt: now, health: .failed, destination: "FornixNūbium™")
    let alerts = DigiSphereEngine.alerts(snapshot: .init(devices: [record], backups: [backup]), now: now)
    #expect(alerts.contains { $0.kind == .syncFailure })
    #expect(!alerts.contains { $0.kind == .staleBackup })
}

@Test func aggregateHealthReturnsWorstState() {
    let id = UUID()
    let backups = [
        BackupRecord(deviceID: id, completedAt: Date(), health: .healthy, destination: "Local"),
        BackupRecord(deviceID: id, completedAt: Date(), health: .delayed, destination: "Cloud")
    ]
    #expect(DigiSphereEngine.aggregateSyncHealth(backups: backups) == .delayed)
}

@Test func continuityPrefersMacForCode() {
    let source = device(kind: .iPhone)
    let mac = device(kind: .mac)
    let iPad = device(kind: .iPad)
    let chosen = DigiSphereEngine.preferredContinuationDevice(
        for: "code editing",
        excluding: source.id,
        devices: [source, iPad, mac]
    )
    #expect(chosen?.id == mac.id)
}

@Test func removingDeviceCascadesRelatedRecords() async {
    let record = device()
    let other = device(kind: .iPad)
    let store = DigiSphereStore(snapshot: .init(
        devices: [record, other],
        backups: [.init(deviceID: record.id, completedAt: Date(), health: .healthy, destination: "Cloud")],
        continuitySessions: [.init(sourceDeviceID: record.id, destinationDeviceID: other.id, activityType: "photo", activityID: "A")]
    ))
    await store.removeDevice(id: record.id)
    let snapshot = await store.currentSnapshot()
    #expect(snapshot.devices.count == 1)
    #expect(snapshot.backups.isEmpty)
    #expect(snapshot.continuitySessions.isEmpty)
}

@Test func persistenceRoundTripPreservesDates() async throws {
    let timestamp = Date(timeIntervalSince1970: 1_234.567)
    let record = device(lastSeen: timestamp)
    let store = DigiSphereStore(snapshot: .init(devices: [record]))
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try await store.save(to: url)
    let restored = DigiSphereStore()
    try await restored.load(from: url)
    let loaded = await restored.currentSnapshot()
    #expect(loaded.devices.first?.lastSeen == timestamp)
}

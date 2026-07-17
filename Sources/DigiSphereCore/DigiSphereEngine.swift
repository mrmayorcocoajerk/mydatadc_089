import Foundation

public struct DigiSpherePolicy: Sendable {
    public var lowBatteryThreshold: Int
    public var storagePressureThreshold: Double
    public var staleBackupInterval: TimeInterval
    public var offlineWarningInterval: TimeInterval

    public init(
        lowBatteryThreshold: Int = 20,
        storagePressureThreshold: Double = 0.90,
        staleBackupInterval: TimeInterval = 7 * 24 * 60 * 60,
        offlineWarningInterval: TimeInterval = 24 * 60 * 60
    ) {
        self.lowBatteryThreshold = min(100, max(0, lowBatteryThreshold))
        self.storagePressureThreshold = min(1, max(0, storagePressureThreshold))
        self.staleBackupInterval = max(0, staleBackupInterval)
        self.offlineWarningInterval = max(0, offlineWarningInterval)
    }
}

public enum DigiSphereEngine {
    public static func alerts(
        snapshot: DigiSphereSnapshot,
        now: Date = Date(),
        policy: DigiSpherePolicy = .init()
    ) -> [DigiSphereAlert] {
        var output: [DigiSphereAlert] = []
        let backupsByDevice = Dictionary(grouping: snapshot.backups, by: \.deviceID)

        for device in snapshot.devices {
            if let battery = device.batteryPercent,
               battery <= policy.lowBatteryThreshold,
               !device.isCharging {
                output.append(.init(
                    deviceID: device.id,
                    kind: .lowBattery,
                    title: "Low battery",
                    detail: "\(device.name) is at \(battery)% battery.",
                    createdAt: now
                ))
            }

            if device.storageUtilization >= policy.storagePressureThreshold {
                let percent = Int((device.storageUtilization * 100).rounded())
                output.append(.init(
                    deviceID: device.id,
                    kind: .storagePressure,
                    title: "Storage pressure",
                    detail: "\(device.name) storage is \(percent)% full.",
                    createdAt: now
                ))
            }

            if device.connection == .offline,
               now.timeIntervalSince(device.lastSeen) >= policy.offlineWarningInterval {
                output.append(.init(
                    deviceID: device.id,
                    kind: .deviceOffline,
                    title: "Device offline",
                    detail: "\(device.name) has not checked in recently.",
                    createdAt: now
                ))
            }

            let backups = backupsByDevice[device.id, default: []]
            if backups.contains(where: { $0.health == .failed }) {
                output.append(.init(
                    deviceID: device.id,
                    kind: .syncFailure,
                    title: "Backup failed",
                    detail: "A backup for \(device.name) requires attention.",
                    createdAt: now
                ))
            }

            let latestBackup = backups.compactMap(\.completedAt).max()
            if latestBackup == nil || now.timeIntervalSince(latestBackup!) >= policy.staleBackupInterval {
                output.append(.init(
                    deviceID: device.id,
                    kind: .staleBackup,
                    title: "Backup overdue",
                    detail: "\(device.name) does not have a recent backup.",
                    createdAt: now
                ))
            }
        }

        return output.sorted {
            if $0.kind == $1.kind { return $0.title < $1.title }
            return severity($0.kind) > severity($1.kind)
        }
    }

    public static func aggregateSyncHealth(backups: [BackupRecord]) -> SyncHealth {
        backups.map(\.health).max() ?? .paused
    }

    public static func preferredContinuationDevice(
        for activityType: String,
        excluding sourceDeviceID: UUID,
        devices: [DeviceRecord]
    ) -> DeviceRecord? {
        devices
            .filter { $0.id != sourceDeviceID && $0.connection == .online }
            .sorted {
                score($0, activityType: activityType) > score($1, activityType: activityType)
            }
            .first
    }

    private static func severity(_ kind: DigiSphereAlertKind) -> Int {
        switch kind {
        case .syncFailure: 5
        case .storagePressure: 4
        case .staleBackup: 3
        case .deviceOffline: 2
        case .lowBattery: 1
        }
    }

    private static func score(_ device: DeviceRecord, activityType: String) -> Int {
        var value = 0
        switch (activityType.lowercased(), device.kind) {
        case (let activity, .mac) where activity.contains("video") || activity.contains("audio") || activity.contains("code"):
            value += 50
        case (let activity, .iPad) where activity.contains("photo") || activity.contains("draw") || activity.contains("read"):
            value += 45
        case (let activity, .iPhone) where activity.contains("message") || activity.contains("call") || activity.contains("capture"):
            value += 40
        default:
            value += 10
        }
        value += Int((1 - device.storageUtilization) * 20)
        value += device.batteryPercent.map { $0 / 10 } ?? 5
        if device.isCharging { value += 5 }
        return value
    }
}

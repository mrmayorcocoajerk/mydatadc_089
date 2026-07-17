import Foundation

public enum DeviceKind: String, Codable, CaseIterable, Sendable {
    case mac, iPhone, iPad, appleWatch, airPods, appleTV, homePod, other
}

public enum ConnectionState: String, Codable, Sendable {
    case online, offline, sleeping, unknown
}

public enum SyncHealth: String, Codable, Sendable, Comparable {
    case healthy, delayed, paused, failed

    private var rank: Int {
        switch self {
        case .healthy: 0
        case .delayed: 1
        case .paused: 2
        case .failed: 3
        }
    }

    public static func < (lhs: SyncHealth, rhs: SyncHealth) -> Bool {
        lhs.rank < rhs.rank
    }
}

public struct DeviceRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: DeviceKind
    public var operatingSystem: String
    public var connection: ConnectionState
    public var batteryPercent: Int?
    public var isCharging: Bool
    public var totalStorageBytes: Int64
    public var availableStorageBytes: Int64
    public var lastSeen: Date

    public init(
        id: UUID = UUID(),
        name: String,
        kind: DeviceKind,
        operatingSystem: String,
        connection: ConnectionState,
        batteryPercent: Int? = nil,
        isCharging: Bool = false,
        totalStorageBytes: Int64,
        availableStorageBytes: Int64,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.operatingSystem = operatingSystem
        self.connection = connection
        self.batteryPercent = batteryPercent.map { min(100, max(0, $0)) }
        self.isCharging = isCharging
        self.totalStorageBytes = max(0, totalStorageBytes)
        self.availableStorageBytes = min(max(0, availableStorageBytes), self.totalStorageBytes)
        self.lastSeen = lastSeen
    }

    public var usedStorageBytes: Int64 { totalStorageBytes - availableStorageBytes }
    public var storageUtilization: Double {
        guard totalStorageBytes > 0 else { return 0 }
        return Double(usedStorageBytes) / Double(totalStorageBytes)
    }
}

public struct BackupRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let deviceID: UUID
    public var completedAt: Date?
    public var health: SyncHealth
    public var destination: String

    public init(
        id: UUID = UUID(),
        deviceID: UUID,
        completedAt: Date?,
        health: SyncHealth,
        destination: String
    ) {
        self.id = id
        self.deviceID = deviceID
        self.completedAt = completedAt
        self.health = health
        self.destination = destination
    }
}

public struct ContinuitySession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let sourceDeviceID: UUID
    public let destinationDeviceID: UUID
    public var activityType: String
    public var activityID: String
    public var startedAt: Date
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        sourceDeviceID: UUID,
        destinationDeviceID: UUID,
        activityType: String,
        activityID: String,
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.sourceDeviceID = sourceDeviceID
        self.destinationDeviceID = destinationDeviceID
        self.activityType = activityType
        self.activityID = activityID
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

public enum DigiSphereAlertKind: String, Codable, Sendable {
    case lowBattery, storagePressure, staleBackup, syncFailure, deviceOffline
}

public struct DigiSphereAlert: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let deviceID: UUID?
    public let kind: DigiSphereAlertKind
    public let title: String
    public let detail: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        deviceID: UUID?,
        kind: DigiSphereAlertKind,
        title: String,
        detail: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.deviceID = deviceID
        self.kind = kind
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
    }
}

public struct DigiSphereSnapshot: Codable, Equatable, Sendable {
    public var devices: [DeviceRecord]
    public var backups: [BackupRecord]
    public var continuitySessions: [ContinuitySession]

    public init(
        devices: [DeviceRecord] = [],
        backups: [BackupRecord] = [],
        continuitySessions: [ContinuitySession] = []
    ) {
        self.devices = devices
        self.backups = backups
        self.continuitySessions = continuitySessions
    }
}

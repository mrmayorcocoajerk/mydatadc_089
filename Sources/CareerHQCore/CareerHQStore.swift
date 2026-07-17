import Foundation

public enum CareerHQStoreError: Error, Equatable {
    case applicationNotFound(UUID)
    case invalidEmployer
    case invalidRole
}

public actor CareerHQStore {
    private var applications: [UUID: CareerApplication]
    private let persistenceURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(applications: [CareerApplication] = [], persistenceURL: URL? = nil) {
        self.applications = Dictionary(uniqueKeysWithValues: applications.map { ($0.id, $0) })
        self.persistenceURL = persistenceURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .millisecondsSince1970
        self.decoder.dateDecodingStrategy = .millisecondsSince1970
    }

    public func allApplications() -> [CareerApplication] {
        applications.values.sorted { $0.lastUpdated > $1.lastUpdated }
    }

    @discardableResult
    public func add(_ application: CareerApplication) async throws -> CareerApplication {
        let normalized = try validate(application)
        var recorded = normalized
        if recorded.activities.isEmpty { recorded.activities.append(.init(date: recorded.dateAdded, kind: .created, detail: "Application added")) }
        applications[recorded.id] = recorded
        try persistIfNeeded()
        return recorded
    }

    @discardableResult
    public func update(_ application: CareerApplication) async throws -> CareerApplication {
        guard applications[application.id] != nil else {
            throw CareerHQStoreError.applicationNotFound(application.id)
        }
        var normalized = try validate(application)
        normalized.lastUpdated = .now
        normalized.activities.append(.init(kind: .updated, detail: "Application updated"))
        applications[normalized.id] = normalized
        try persistIfNeeded()
        return normalized
    }

    public func setStatus(_ status: ApplicationStatus, for id: UUID) async throws {
        guard var application = applications[id] else {
            throw CareerHQStoreError.applicationNotFound(id)
        }
        let previousStatus = application.status
        application.status = status
        application.lastUpdated = .now
        application.activities.append(.init(kind: .statusChanged, detail: "Status changed from \(previousStatus.rawValue) to \(status.rawValue)"))
        if status == .applied && application.dateApplied == nil {
            application.dateApplied = .now
        }
        applications[id] = application
        try persistIfNeeded()
    }

    public func toggleFavorite(for id: UUID) async throws {
        guard var application = applications[id] else {
            throw CareerHQStoreError.applicationNotFound(id)
        }
        application.isFavorite.toggle()
        application.lastUpdated = .now
        applications[id] = application
        try persistIfNeeded()
    }

    public func scheduleFollowUp(on date: Date?, for id: UUID) async throws {
        guard var application = applications[id] else {
            throw CareerHQStoreError.applicationNotFound(id)
        }
        application.followUpDate = date
        application.lastUpdated = .now
        let detail = date == nil ? "Follow-up cleared" : "Follow-up scheduled"
        application.activities.append(.init(kind: .followUpScheduled, detail: detail))
        applications[id] = application
        try persistIfNeeded()
    }

    public func importCSV(_ csv: String) async throws -> Int {
        let imported = try CareerHQCSV.importApplications(from: csv)
        for application in imported {
            let normalized = try validate(application)
            applications[normalized.id] = normalized
        }
        try persistIfNeeded()
        return imported.count
    }

    public func exportCSV() -> String {
        CareerHQCSV.export(allApplications())
    }

    public func delete(_ id: UUID) async throws {
        guard applications.removeValue(forKey: id) != nil else {
            throw CareerHQStoreError.applicationNotFound(id)
        }
        try persistIfNeeded()
    }

    public func load() throws {
        guard let persistenceURL, FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
        let data = try Data(contentsOf: persistenceURL)
        let decoded = try decoder.decode([CareerApplication].self, from: data)
        applications = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }

    public func save() throws {
        try persistIfNeeded()
    }

    private func validate(_ application: CareerApplication) throws -> CareerApplication {
        var normalized = application
        normalized.employer = normalized.employer.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.role = normalized.role.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.location = normalized.location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.employer.isEmpty else { throw CareerHQStoreError.invalidEmployer }
        guard !normalized.role.isEmpty else { throw CareerHQStoreError.invalidRole }
        return normalized
    }

    private func persistIfNeeded() throws {
        guard let persistenceURL else { return }
        let directory = persistenceURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let payload = applications.values.sorted { $0.dateAdded < $1.dateAdded }
        let data = try encoder.encode(payload)
        try data.write(to: persistenceURL, options: .atomic)
    }
}

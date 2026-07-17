import Foundation

public enum ApplicationStatus: String, CaseIterable, Codable, Sendable, Identifiable {
    case saved = "Saved"
    case applied = "Applied"
    case recruiterScreen = "Recruiter Screen"
    case interview = "Interview"
    case finalInterview = "Final Interview"
    case offer = "Offer"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case withdrawn = "Withdrawn"

    public var id: String { rawValue }

    public var isActive: Bool {
        switch self {
        case .saved, .applied, .recruiterScreen, .interview, .finalInterview, .offer: true
        case .accepted, .rejected, .withdrawn: false
        }
    }
}

public enum WorkArrangement: String, CaseIterable, Codable, Sendable, Identifiable {
    case onsite = "On-site"
    case hybrid = "Hybrid"
    case remote = "Remote"
    public var id: String { rawValue }
}

public struct CompensationRange: Codable, Equatable, Sendable {
    public var minimum: Decimal?
    public var maximum: Decimal?
    public var currencyCode: String

    public init(minimum: Decimal? = nil, maximum: Decimal? = nil, currencyCode: String = "USD") {
        self.minimum = minimum
        self.maximum = maximum
        self.currencyCode = currencyCode
    }
}

public struct ApplicationActivity: Identifiable, Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case created, statusChanged, note, followUpScheduled, updated }
    public var id: UUID
    public var date: Date
    public var kind: Kind
    public var detail: String

    public init(id: UUID = UUID(), date: Date = .now, kind: Kind, detail: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.detail = detail
    }
}

public struct CareerApplication: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var employer: String
    public var role: String
    public var location: String
    public var workArrangement: WorkArrangement
    public var status: ApplicationStatus
    public var compensation: CompensationRange
    public var dateAdded: Date
    public var dateApplied: Date?
    public var lastUpdated: Date
    public var followUpDate: Date?
    public var sourceURL: URL?
    public var notes: String
    public var documentReferences: [String]
    public var isFavorite: Bool
    public var activities: [ApplicationActivity]

    public init(
        id: UUID = UUID(), employer: String, role: String, location: String = "",
        workArrangement: WorkArrangement = .hybrid, status: ApplicationStatus = .saved,
        compensation: CompensationRange = .init(), dateAdded: Date = .now,
        dateApplied: Date? = nil, lastUpdated: Date = .now, followUpDate: Date? = nil,
        sourceURL: URL? = nil, notes: String = "", documentReferences: [String] = [],
        isFavorite: Bool = false, activities: [ApplicationActivity] = []
    ) {
        self.id = id; self.employer = employer; self.role = role; self.location = location
        self.workArrangement = workArrangement; self.status = status; self.compensation = compensation
        self.dateAdded = dateAdded; self.dateApplied = dateApplied; self.lastUpdated = lastUpdated
        self.followUpDate = followUpDate; self.sourceURL = sourceURL; self.notes = notes
        self.documentReferences = documentReferences; self.isFavorite = isFavorite
        self.activities = activities
    }

    private enum CodingKeys: String, CodingKey {
        case id, employer, role, location, workArrangement, status, compensation, dateAdded,
             dateApplied, lastUpdated, followUpDate, sourceURL, notes, documentReferences,
             isFavorite, activities
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        employer = try c.decode(String.self, forKey: .employer)
        role = try c.decode(String.self, forKey: .role)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        workArrangement = try c.decodeIfPresent(WorkArrangement.self, forKey: .workArrangement) ?? .hybrid
        status = try c.decodeIfPresent(ApplicationStatus.self, forKey: .status) ?? .saved
        compensation = try c.decodeIfPresent(CompensationRange.self, forKey: .compensation) ?? .init()
        dateAdded = try c.decodeIfPresent(Date.self, forKey: .dateAdded) ?? .now
        dateApplied = try c.decodeIfPresent(Date.self, forKey: .dateApplied)
        lastUpdated = try c.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? dateAdded
        followUpDate = try c.decodeIfPresent(Date.self, forKey: .followUpDate)
        sourceURL = try c.decodeIfPresent(URL.self, forKey: .sourceURL)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        documentReferences = try c.decodeIfPresent([String].self, forKey: .documentReferences) ?? []
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        activities = try c.decodeIfPresent([ApplicationActivity].self, forKey: .activities) ?? []
    }
}

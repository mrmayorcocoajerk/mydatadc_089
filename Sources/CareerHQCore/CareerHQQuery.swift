import Foundation

public enum CareerSort: String, CaseIterable, Sendable, Identifiable {
    case recentlyUpdated = "Recently Updated"
    case employer = "Employer"
    case role = "Role"
    case status = "Status"

    public var id: String { rawValue }
}

public struct CareerHQFilter: Equatable, Sendable {
    public var searchText: String
    public var statuses: Set<ApplicationStatus>
    public var favoritesOnly: Bool
    public var sort: CareerSort

    public init(
        searchText: String = "",
        statuses: Set<ApplicationStatus> = [],
        favoritesOnly: Bool = false,
        sort: CareerSort = .recentlyUpdated
    ) {
        self.searchText = searchText
        self.statuses = statuses
        self.favoritesOnly = favoritesOnly
        self.sort = sort
    }

    public func apply(to applications: [CareerApplication]) -> [CareerApplication] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = applications.filter { application in
            let matchesSearch = query.isEmpty
                || application.employer.localizedCaseInsensitiveContains(query)
                || application.role.localizedCaseInsensitiveContains(query)
                || application.location.localizedCaseInsensitiveContains(query)
                || application.notes.localizedCaseInsensitiveContains(query)
            let matchesStatus = statuses.isEmpty || statuses.contains(application.status)
            let matchesFavorite = !favoritesOnly || application.isFavorite
            return matchesSearch && matchesStatus && matchesFavorite
        }

        return filtered.sorted { lhs, rhs in
            switch sort {
            case .recentlyUpdated:
                lhs.lastUpdated > rhs.lastUpdated
            case .employer:
                lhs.employer.localizedCaseInsensitiveCompare(rhs.employer) == .orderedAscending
            case .role:
                lhs.role.localizedCaseInsensitiveCompare(rhs.role) == .orderedAscending
            case .status:
                lhs.status.rawValue.localizedCaseInsensitiveCompare(rhs.status.rawValue) == .orderedAscending
            }
        }
    }
}

public struct CareerHQSummary: Equatable, Sendable {
    public let total: Int
    public let active: Int
    public let interviews: Int
    public let offers: Int
    public let accepted: Int

    public init(applications: [CareerApplication]) {
        total = applications.count
        active = applications.filter { $0.status.isActive }.count
        interviews = applications.filter { [.interview, .finalInterview].contains($0.status) }.count
        offers = applications.filter { $0.status == .offer }.count
        accepted = applications.filter { $0.status == .accepted }.count
    }
}

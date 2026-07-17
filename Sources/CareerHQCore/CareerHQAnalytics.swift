import Foundation

public struct PipelineStageMetric: Equatable, Sendable, Identifiable {
    public let status: ApplicationStatus
    public let count: Int
    public var id: String { status.id }
}

public struct CareerHQAnalytics: Equatable, Sendable {
    public let total: Int
    public let active: Int
    public let responseRate: Double
    public let interviewRate: Double
    public let offerRate: Double
    public let overdueFollowUps: Int
    public let pipeline: [PipelineStageMetric]

    public init(applications: [CareerApplication], now: Date = .now) {
        total = applications.count
        active = applications.filter { $0.status.isActive }.count
        let applied = applications.filter { $0.status != .saved }.count
        let responded = applications.filter { ![.saved, .applied].contains($0.status) }.count
        let interviewed = applications.filter { [.interview, .finalInterview, .offer, .accepted].contains($0.status) }.count
        let offers = applications.filter { [.offer, .accepted].contains($0.status) }.count
        responseRate = applied == 0 ? 0 : Double(responded) / Double(applied)
        interviewRate = applied == 0 ? 0 : Double(interviewed) / Double(applied)
        offerRate = interviewed == 0 ? 0 : Double(offers) / Double(interviewed)
        overdueFollowUps = applications.filter { $0.status.isActive && ($0.followUpDate.map { $0 < now } ?? false) }.count
        pipeline = ApplicationStatus.allCases.map { status in
            PipelineStageMetric(status: status, count: applications.filter { $0.status == status }.count)
        }
    }
}

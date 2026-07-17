import Foundation

public actor ChrysanthemumRouter {
    private var rules: [UUID: ChrysanthemumRule]
    private var processedEventIDs: Set<UUID>
    private var eventJournal: [ChrysanthemumEvent]
    private var actionJournal: [RoutedAction]
    private let journalLimit: Int

    public init(rules: [ChrysanthemumRule] = [], journalLimit: Int = 1_000) {
        self.rules = Dictionary(uniqueKeysWithValues: rules.map { ($0.id, $0) })
        self.processedEventIDs = []
        self.eventJournal = []
        self.actionJournal = []
        self.journalLimit = max(10, journalLimit)
    }

    public func register(_ rule: ChrysanthemumRule) throws {
        guard rules[rule.id] == nil else { throw ChrysanthemumError.duplicateRule }
        rules[rule.id] = rule
    }

    public func update(_ rule: ChrysanthemumRule) throws {
        guard rules[rule.id] != nil else { throw ChrysanthemumError.unknownRule }
        rules[rule.id] = rule
    }

    public func removeRule(id: UUID) throws {
        guard rules.removeValue(forKey: id) != nil else { throw ChrysanthemumError.unknownRule }
    }

    public func allRules() -> [ChrysanthemumRule] {
        rules.values.sorted { lhs, rhs in
            if lhs.minimumPriority == rhs.minimumPriority { return lhs.name < rhs.name }
            return lhs.minimumPriority > rhs.minimumPriority
        }
    }

    @discardableResult
    public func publish(_ event: ChrysanthemumEvent) throws -> [RoutedAction] {
        guard !processedEventIDs.contains(event.id) else { throw ChrysanthemumError.duplicateEvent }
        processedEventIDs.insert(event.id)
        eventJournal.append(event)

        let matchedRules = rules.values
            .filter { $0.matches(event) }
            .sorted { lhs, rhs in
                if lhs.minimumPriority == rhs.minimumPriority { return lhs.name < rhs.name }
                return lhs.minimumPriority > rhs.minimumPriority
            }

        let routed = matchedRules.flatMap { rule in
            rule.actions.map {
                RoutedAction(eventID: event.id, ruleID: rule.id, action: $0, createdAt: event.occurredAt)
            }
        }
        actionJournal.append(contentsOf: routed)
        trimJournalsIfNeeded()
        return routed
    }

    public func recentEvents(limit: Int = 50, district: DistrictID? = nil) -> [ChrysanthemumEvent] {
        let filtered = district.map { district in
            eventJournal.filter { $0.source == district || $0.destination == district }
        } ?? eventJournal
        return Array(filtered.suffix(max(0, limit)).reversed())
    }

    public func recentActions(limit: Int = 50) -> [RoutedAction] {
        Array(actionJournal.suffix(max(0, limit)).reversed())
    }

    public func clearHistory() {
        processedEventIDs.removeAll(keepingCapacity: true)
        eventJournal.removeAll(keepingCapacity: true)
        actionJournal.removeAll(keepingCapacity: true)
    }

    private func trimJournalsIfNeeded() {
        if eventJournal.count > journalLimit {
            eventJournal.removeFirst(eventJournal.count - journalLimit)
        }
        if actionJournal.count > journalLimit {
            actionJournal.removeFirst(actionJournal.count - journalLimit)
        }
    }
}

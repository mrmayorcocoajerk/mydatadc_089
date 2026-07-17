import Foundation

public actor AETHEREventHistory {
    private let capacity: Int?
    private var events: [AETHEREvent] = []

    public init(capacity: Int? = nil) {
        if let capacity {
            self.capacity = max(0, capacity)
        } else {
            self.capacity = nil
        }
    }

    public func record(_ event: AETHEREvent) {
        guard capacity != 0 else { return }

        events.append(event)

        if let capacity, events.count > capacity {
            events.removeFirst(events.count - capacity)
        }
    }

    public func snapshot() -> [AETHEREvent] {
        events
    }

    public func clear() {
        events.removeAll(keepingCapacity: true)
    }

    public func count() -> Int {
        events.count
    }

    public func events(matching predicate: @Sendable (AETHEREvent) -> Bool) -> [AETHEREvent] {
        events.filter(predicate)
    }

    public func latest(_ limit: Int) -> [AETHEREvent] {
        guard limit > 0 else { return [] }
        return Array(events.suffix(limit))
    }

    @discardableResult
    public func removeFirst() -> AETHEREvent? {
        guard !events.isEmpty else { return nil }
        return events.removeFirst()
    }
}

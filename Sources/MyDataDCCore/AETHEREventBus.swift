import Foundation

public struct AETHEREventSubscription: Hashable, Sendable {
    fileprivate let id: UUID

    fileprivate init(id: UUID = UUID()) {
        self.id = id
    }
}

public actor AETHEREventBus {
    public typealias Handler = @Sendable (AETHEREvent) async -> Void

    private var handlers: [AETHEREventSubscription: Handler] = [:]

    public init() {}

    @discardableResult
    public func subscribe(_ handler: @escaping Handler) -> AETHEREventSubscription {
        let subscription = AETHEREventSubscription()
        handlers[subscription] = handler
        return subscription
    }

    public func unsubscribe(_ subscription: AETHEREventSubscription) {
        handlers.removeValue(forKey: subscription)
    }

    public func subscriberCount() -> Int {
        handlers.count
    }

    public func publish(_ event: AETHEREvent) async {
        for handler in handlers.values {
            await handler(event)
        }
    }
}

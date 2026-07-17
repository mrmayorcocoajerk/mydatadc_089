import Foundation

public actor AETHEREventHistorySubscription {
    private let bus: AETHEREventBus
    private let history: AETHEREventHistory
    private var subscription: AETHEREventSubscription?

    public init(bus: AETHEREventBus, history: AETHEREventHistory) {
        self.bus = bus
        self.history = history
    }

    public func start() async {
        guard subscription == nil else { return }
        subscription = await bus.subscribe { [history] event in
            await history.record(event)
        }
    }

    public func stop() async {
        guard let subscription else { return }
        await bus.unsubscribe(subscription)
        self.subscription = nil
    }

    public func isActive() -> Bool {
        subscription != nil
    }
}

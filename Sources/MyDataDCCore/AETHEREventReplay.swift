import Foundation

public actor AETHEREventReplayer {
    public init() {}
    public func replay(history: AETHEREventHistory, into bus: AETHEREventBus) async {
        for event in await history.snapshot() {
            await bus.publish(event)
        }
    }
}

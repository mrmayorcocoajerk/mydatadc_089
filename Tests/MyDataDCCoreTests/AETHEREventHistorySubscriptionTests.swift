import Testing
@testable import MyDataDCCore

@Test
func eventHistorySubscriptionRecordsUntilStopped() async {
    let bus = AETHEREventBus()
    let history = AETHEREventHistory()
    let bridge = AETHEREventHistorySubscription(bus: bus, history: history)

    await bridge.start()
    await bus.publish(.workspaceOpened("career"))
    #expect(await history.snapshot() == [.workspaceOpened("career")])
    #expect(await bridge.isActive())

    await bridge.stop()
    await bus.publish(.workspaceClosed("career"))

    #expect(await history.snapshot() == [.workspaceOpened("career")])
    #expect(!(await bridge.isActive()))
}

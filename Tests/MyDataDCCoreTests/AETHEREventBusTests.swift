import Testing
@testable import MyDataDCCore

private actor EventRecorder {
    private var events: [AETHEREvent] = []
    func append(_ event: AETHEREvent) { events.append(event) }
    func snapshot() -> [AETHEREvent] { events }
}

@Test
func eventBusPublishesTypedEvents() async {
    let bus = AETHEREventBus()
    let recorder = EventRecorder()
    let expected = AETHEREvent.workspaceOpened("career")

    _ = await bus.subscribe { event in
        await recorder.append(event)
    }

    await bus.publish(expected)

    #expect(await recorder.snapshot() == [expected])
}

@Test
func eventBusStopsDeliveryAfterUnsubscribe() async {
    let bus = AETHEREventBus()
    let recorder = EventRecorder()

    let token = await bus.subscribe { event in
        await recorder.append(event)
    }

    await bus.unsubscribe(token)
    await bus.publish(.workspaceClosed("career"))

    #expect(await recorder.snapshot().isEmpty)
}


@Test
func eventBusTracksTypedSubscriptions() async {
    let bus = AETHEREventBus()

    let first = await bus.subscribe { _ in }
    let second = await bus.subscribe { _ in }

    #expect(await bus.subscriberCount() == 2)

    await bus.unsubscribe(first)
    #expect(await bus.subscriberCount() == 1)

    await bus.unsubscribe(second)
    #expect(await bus.subscriberCount() == 0)
}

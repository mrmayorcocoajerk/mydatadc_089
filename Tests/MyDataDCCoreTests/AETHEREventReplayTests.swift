import Testing
@testable import MyDataDCCore

private actor ReplayRecorder {
    var events:[AETHEREvent]=[]
    func append(_ e:AETHEREvent){ events.append(e) }
    func snapshot()->[AETHEREvent]{ events }
}

@Test
func replayPublishesRecordedEvents() async {
    let history=AETHEREventHistory()
    await history.record(.workspaceOpened("career"))
    await history.record(.workspaceClosed("career"))
    let bus=AETHEREventBus()
    let recorder=ReplayRecorder()
    _ = await bus.subscribe { await recorder.append($0) }
    await AETHEREventReplayer().replay(history: history, into: bus)
    #expect(await recorder.snapshot().count == 2)
}

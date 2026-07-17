import Testing
@testable import MyDataDCCore

@Test
func eventHistoryRecordsAndClears() async {
    let h=AETHEREventHistory()
    await h.record(.workspaceOpened("career"))
    #expect(await h.snapshot().count==1)
    await h.clear()
    #expect(await h.snapshot().isEmpty)
}


@Test
func eventHistoryHonorsCapacity() async {
    let history = AETHEREventHistory(capacity: 2)

    await history.record(.workspaceOpened("career"))
    await history.record(.workspaceOpened("money"))
    await history.record(.workspaceClosed("career"))

    #expect(await history.snapshot() == [
        .workspaceOpened("money"),
        .workspaceClosed("career")
    ])
    #expect(await history.count() == 2)
}

@Test
func zeroCapacityEventHistoryDropsEvents() async {
    let history = AETHEREventHistory(capacity: 0)

    await history.record(.objectUpdated("one"))

    #expect(await history.snapshot().isEmpty)
}


@Test
func eventHistoryQueriesMatchingEvents() async {
    let history = AETHEREventHistory()

    await history.record(.workspaceOpened("career"))
    await history.record(.objectUpdated("resume"))
    await history.record(.workspaceClosed("career"))

    let workspaceEvents = await history.events { event in
        switch event {
        case .workspaceOpened, .workspaceClosed:
            return true
        case .objectUpdated:
            return false
        }
    }

    #expect(workspaceEvents == [
        .workspaceOpened("career"),
        .workspaceClosed("career")
    ])
}

@Test
func eventHistoryReturnsLatestEventsInOrder() async {
    let history = AETHEREventHistory()

    await history.record(.workspaceOpened("career"))
    await history.record(.workspaceOpened("money"))
    await history.record(.workspaceClosed("career"))

    #expect(await history.latest(2) == [
        .workspaceOpened("money"),
        .workspaceClosed("career")
    ])
    #expect(await history.latest(0).isEmpty)
}


@Test
func removeFirstReturnsOldestEvent() async {
 let h=AETHEREventHistory()
 await h.record(.workspaceOpened("a"))
 await h.record(.workspaceOpened("b"))
 #expect((await h.removeFirst()) == .workspaceOpened("a"))
 #expect((await h.snapshot()) == [.workspaceOpened("b")])
}

import Foundation
import Testing
@testable import TimeCore

@Test func stopwatchStartsPausesAndResumes() {
    let start = Date(timeIntervalSince1970: 1_000)
    var stopwatch = StopwatchState()
    stopwatch.start(at: start)
    #expect(stopwatch.elapsed(at: start.addingTimeInterval(12)) == 12)
    stopwatch.pause(at: start.addingTimeInterval(12))
    #expect(stopwatch.elapsed(at: start.addingTimeInterval(30)) == 12)
    stopwatch.start(at: start.addingTimeInterval(30))
    #expect(stopwatch.elapsed(at: start.addingTimeInterval(35)) == 17)
}

@Test func stopwatchRecordsAndResetsLaps() {
    let start = Date(timeIntervalSince1970: 2_000)
    var stopwatch = StopwatchState()
    stopwatch.start(at: start)
    #expect(stopwatch.recordLap(at: start.addingTimeInterval(8)) == 8)
    #expect(stopwatch.laps == [8])
    stopwatch.reset()
    #expect(stopwatch.elapsed(at: start) == 0)
    #expect(stopwatch.laps.isEmpty)
}

@Test func countdownPausesAndResets() {
    let start = Date(timeIntervalSince1970: 3_000)
    var countdown = CountdownState(duration: 60)
    countdown.start(at: start)
    #expect(countdown.remaining(at: start.addingTimeInterval(15)) == 45)
    countdown.pause(at: start.addingTimeInterval(15))
    #expect(countdown.remaining(at: start.addingTimeInterval(50)) == 45)
    countdown.reset()
    #expect(countdown.remaining(at: start) == 60)
}

@Test func formatterProducesClockValues() {
    #expect(TimeDisplayFormatter.clock(65) == "01:05")
    #expect(TimeDisplayFormatter.clock(3_661) == "01:01:01")
}

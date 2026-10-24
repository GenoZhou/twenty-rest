import Testing
@testable import twenty_rest

@Suite("RestCycle")
struct RestCycleTests {
    @Test("starts in Work Interval with default remaining duration")
    func startsInWorkInterval() {
        let cycle = RestCycle()

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(20 * 60))
        #expect(cycle.canReturn == false)
    }

    @Test("Work Interval reaching zero enters Rest minimum and requests panel")
    func workIntervalElapsingEntersRest() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )

        cycle.tick(by: .seconds(60))

        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(20))
        #expect(cycle.shouldPresentRestPanel == true)
        #expect(cycle.canReturn == false)
    }

    @Test("Rest minimum elapsing enables Return without ending Rest")
    func restMinimumElapsingAwaitsReturn() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()

        cycle.tick(by: .seconds(20))

        #expect(cycle.phase == .restAwaitingReturn)
        #expect(cycle.canReturn == true)
        #expect(cycle.remaining == .zero)
    }

    @Test("Return after minimum starts the next Work Interval")
    func returnStartsNextWorkInterval() {
        var cycle = restingCycleReadyToReturn()

        cycle.markReturn()

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(60))
        #expect(cycle.shouldPresentRestPanel == false)
    }

    @Test("Return before minimum has no effect")
    func returnBeforeMinimumDoesNothing() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(60))

        cycle.markReturn()

        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(20))
    }

    @Test("Skip during Rest starts the next Work Interval immediately")
    func skipEndsRestImmediately() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(60))

        cycle.skip()

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(60))
        #expect(cycle.shouldPresentRestPanel == false)
    }

    @Test("Snooze defers Rest by the snooze duration")
    func snoozeDefersRest() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(60))

        cycle.snooze()

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(300))
        #expect(cycle.shouldPresentRestPanel == false)
    }

    @Test("Pause freezes Work Interval; resume continues remaining time")
    func pauseAndResume() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(10))
        cycle.pause()
        cycle.tick(by: .seconds(30))

        #expect(cycle.phase == .paused)
        #expect(cycle.remaining == .seconds(50))

        cycle.resume()
        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(50))
    }

    @Test("Session lock pauses Work Interval accumulation")
    func lockPausesWorkInterval() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(10))
        cycle.handleSessionLocked()
        cycle.tick(by: .seconds(30))

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(50))

        cycle.handleSessionUnlocked()
        cycle.tick(by: .seconds(5))
        #expect(cycle.remaining == .seconds(45))
    }

    @Test("While locked, ticker does not advance Rest; unlock applies wall time and re-presents panel")
    func lockDuringRestDefersProgressUntilUnlock() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()
        cycle.handleSessionLocked()

        cycle.tick(by: .seconds(20))
        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(20))

        cycle.tick(by: .seconds(20)) // still locked — ignored
        cycle.handleSessionUnlocked()
        // Controller applies wall elapsed via tick after unlock; simulate that here:
        cycle.tick(by: .seconds(20))

        #expect(cycle.phase == .restAwaitingReturn)
        #expect(cycle.canReturn == true)
        #expect(cycle.shouldPresentRestPanel == true)
    }

    @Test("Status Title shows countdown and awaiting-return label")
    func statusTitleReflectsPhase() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(125),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        #expect(cycle.statusTitle == "2:05")

        cycle.tick(by: .seconds(125))
        #expect(cycle.statusTitle == "0:20")

        cycle.tick(by: .seconds(20))
        #expect(cycle.statusTitle == "休息好了")
    }

    private func restingCycleReadyToReturn() -> RestCycle {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20),
                snoozeDuration: .seconds(300)
            )
        )
        cycle.tick(by: .seconds(60))
        cycle.tick(by: .seconds(20))
        return cycle
    }
}

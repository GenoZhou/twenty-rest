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
        var cycle = makeCycle()

        cycle.tick(by: .seconds(60))

        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(20))
        #expect(cycle.shouldPresentRestPanel == true)
        #expect(cycle.canReturn == false)
    }

    @Test("Rest minimum elapsing enables Return and starts overtime at zero")
    func restMinimumElapsingAwaitsReturn() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()

        cycle.tick(by: .seconds(20))

        #expect(cycle.phase == .restAwaitingReturn)
        #expect(cycle.canReturn == true)
        #expect(cycle.remaining == .zero)
        #expect(cycle.statusTitle == "超过 0:00")
    }

    @Test("Rest overtime counts up past the minimum")
    func restOvertimeCountsUp() {
        var cycle = restingCycleReadyToReturn()

        cycle.tick(by: .seconds(5))

        #expect(cycle.phase == .restAwaitingReturn)
        #expect(cycle.remaining == .seconds(5))
        #expect(cycle.statusTitle == "超过 0:05")
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
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))

        cycle.markReturn()

        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(20))
    }

    @Test("Session lock freezes Work Interval accumulation")
    func lockFreezesWorkInterval() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(10))
        cycle.handleSessionLocked()
        cycle.tick(by: .seconds(30))

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(50))

        cycle.handleSessionUnlocked()
        cycle.tick(by: .seconds(5))
        #expect(cycle.remaining == .seconds(45))
    }

    @Test("While locked, ticker does not advance Rest")
    func tickerIgnoredWhileLockedDuringRest() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()
        cycle.handleSessionLocked()

        cycle.tick(by: .seconds(20))
        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(20))
    }

    @Test("Unlock covering Rest minimum Resets from Rest without panel")
    func unlockResetsFromRest() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()
        cycle.handleSessionLocked()

        cycle.handleSessionUnlocked(wallTimeElapsedWhileLocked: .seconds(20))

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(60))
        #expect(cycle.shouldPresentRestPanel == false)
    }

    @Test("Unlock covering Rest minimum Resets from Work Interval")
    func unlockResetsFromWorkInterval() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(10))
        cycle.handleSessionLocked()

        cycle.handleSessionUnlocked(wallTimeElapsedWhileLocked: .seconds(20))

        #expect(cycle.phase == .workInterval)
        #expect(cycle.remaining == .seconds(60))
        #expect(cycle.shouldPresentRestPanel == false)
    }

    @Test("Short Rest unlock credits wall time and re-presents the panel")
    func shortRestUnlockCreditsAndPresentsPanel() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()
        cycle.handleSessionLocked()

        cycle.handleSessionUnlocked(wallTimeElapsedWhileLocked: .seconds(5))

        #expect(cycle.phase == .restMinimum)
        #expect(cycle.remaining == .seconds(15))
        #expect(cycle.shouldPresentRestPanel == true)
    }

    @Test("Short unlock into overtime keeps Rest and re-presents panel")
    func shortUnlockIntoOvertimeKeepsRest() {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))
        cycle.acknowledgeRestPanelPresentation()
        cycle.tick(by: .seconds(10))
        cycle.handleSessionLocked()

        cycle.handleSessionUnlocked(wallTimeElapsedWhileLocked: .seconds(15))

        #expect(cycle.phase == .restAwaitingReturn)
        #expect(cycle.remaining == .seconds(5))
        #expect(cycle.canReturn == true)
        #expect(cycle.shouldPresentRestPanel == true)
        #expect(cycle.statusTitle == "超过 0:05")
    }

    @Test("Short unlock while already awaiting Return keeps Rest and re-presents panel")
    func shortUnlockWhileAwaitingKeepsRest() {
        var cycle = restingCycleReadyToReturn()
        cycle.acknowledgeRestPanelPresentation()
        cycle.handleSessionLocked()

        cycle.handleSessionUnlocked(wallTimeElapsedWhileLocked: .seconds(5))

        #expect(cycle.phase == .restAwaitingReturn)
        #expect(cycle.remaining == .seconds(5))
        #expect(cycle.shouldPresentRestPanel == true)
        #expect(cycle.canReturn == true)
    }

    @Test("Status Title shows Work countdown then Rest countdown then overtime")
    func statusTitleReflectsPhase() {
        var cycle = RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(125),
                restMinimum: .seconds(20)
            )
        )
        #expect(cycle.statusTitle == "2:05")

        cycle.tick(by: .seconds(125))
        #expect(cycle.statusTitle == "0:20")

        cycle.tick(by: .seconds(20))
        #expect(cycle.statusTitle == "超过 0:00")

        cycle.tick(by: .seconds(3))
        #expect(cycle.statusTitle == "超过 0:03")
    }

    private func makeCycle() -> RestCycle {
        RestCycle(
            configuration: RestCycleConfiguration(
                workInterval: .seconds(60),
                restMinimum: .seconds(20)
            )
        )
    }

    private func restingCycleReadyToReturn() -> RestCycle {
        var cycle = makeCycle()
        cycle.tick(by: .seconds(60))
        cycle.tick(by: .seconds(20))
        return cycle
    }
}

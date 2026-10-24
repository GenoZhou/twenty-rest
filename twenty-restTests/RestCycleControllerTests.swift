import Foundation
import Testing
@testable import twenty_rest

@Suite("RestCycleController")
@MainActor
struct RestCycleControllerTests {
    @Test("unlock that covers Rest minimum Resets and dismisses the Rest panel")
    func unlockResetDismissesPanel() {
        let controller = makeController(suite: "RestCycleControllerTests.reset")

        controller.advanceTime(by: .seconds(60))
        #expect(controller.isInRest)
        #expect(controller.isRestPanelPresented)

        controller.beginSessionLockForTesting()
        controller.applySessionUnlock(wallTimeElapsed: .seconds(20))

        #expect(controller.isInRest == false)
        #expect(controller.phase == .workInterval)
        #expect(controller.isRestPanelPresented == false)
    }

    @Test("unlock before Rest minimum keeps Rest and re-presents the panel")
    func unlockBeforeMinimumKeepsRest() {
        let controller = makeController(suite: "RestCycleControllerTests.beforeMinimum")

        controller.advanceTime(by: .seconds(60))
        controller.isRestPanelPresented = false
        controller.beginSessionLockForTesting()
        controller.applySessionUnlock(wallTimeElapsed: .seconds(5))

        #expect(controller.isInRest)
        #expect(controller.isRestPanelPresented)
    }

    @Test("unlock from Work Interval covering Rest minimum Resets remaining")
    func unlockFromWorkResets() {
        let controller = makeController(suite: "RestCycleControllerTests.workReset")

        controller.advanceTime(by: .seconds(10))
        controller.beginSessionLockForTesting()
        controller.applySessionUnlock(wallTimeElapsed: .seconds(20))

        #expect(controller.phase == .workInterval)
        #expect(controller.remaining == .seconds(60))
        #expect(controller.isRestPanelPresented == false)
    }

    private func makeController(suite: String) -> RestCycleController {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(60, forKey: "workIntervalSeconds")
        defaults.set(20, forKey: "restMinimumSeconds")
        return RestCycleController(
            settings: RestCycleSettings(defaults: defaults),
            enablesRuntime: false
        )
    }
}

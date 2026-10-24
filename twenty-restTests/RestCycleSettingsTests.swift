import Foundation
import Testing
@testable import twenty_rest

@Suite("RestCycleSettings")
struct RestCycleSettingsTests {
    @Test("defaults match classic 20-20-20 and five-minute Snooze")
    func defaults() {
        let defaults = UserDefaults(suiteName: "RestCycleSettingsTests.defaults")!
        defaults.removePersistentDomain(forName: "RestCycleSettingsTests.defaults")
        let settings = RestCycleSettings(defaults: defaults)

        #expect(settings.workIntervalSeconds == 20 * 60)
        #expect(settings.restMinimumSeconds == 20)
        #expect(settings.snoozeSeconds == 5 * 60)
        #expect(settings.configuration.workInterval == .seconds(20 * 60))
    }

    @Test("persists custom durations")
    func persistsCustomDurations() {
        let suiteName = "RestCycleSettingsTests.persist"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var settings = RestCycleSettings(defaults: defaults)
        settings.workIntervalSeconds = 15 * 60
        settings.restMinimumSeconds = 30
        settings.snoozeSeconds = 2 * 60

        let reloaded = RestCycleSettings(defaults: defaults)
        #expect(reloaded.workIntervalSeconds == 15 * 60)
        #expect(reloaded.restMinimumSeconds == 30)
        #expect(reloaded.snoozeSeconds == 2 * 60)
    }
}

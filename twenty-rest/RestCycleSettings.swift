import Foundation

nonisolated struct RestCycleSettings {
    private let defaults: UserDefaults

    private enum Key {
        static let workIntervalSeconds = "workIntervalSeconds"
        static let restMinimumSeconds = "restMinimumSeconds"
        static let snoozeSeconds = "snoozeSeconds"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var workIntervalSeconds: Int {
        get { intValue(for: Key.workIntervalSeconds, default: 20 * 60) }
        set { defaults.set(max(1, newValue), forKey: Key.workIntervalSeconds) }
    }

    var restMinimumSeconds: Int {
        get { intValue(for: Key.restMinimumSeconds, default: 20) }
        set { defaults.set(max(1, newValue), forKey: Key.restMinimumSeconds) }
    }

    var snoozeSeconds: Int {
        get { intValue(for: Key.snoozeSeconds, default: 5 * 60) }
        set { defaults.set(max(1, newValue), forKey: Key.snoozeSeconds) }
    }

    var configuration: RestCycleConfiguration {
        RestCycleConfiguration(
            workInterval: .seconds(workIntervalSeconds),
            restMinimum: .seconds(restMinimumSeconds),
            snoozeDuration: .seconds(snoozeSeconds)
        )
    }

    private func intValue(for key: String, default defaultValue: Int) -> Int {
        if defaults.object(forKey: key) == nil {
            return defaultValue
        }
        return defaults.integer(forKey: key)
    }
}

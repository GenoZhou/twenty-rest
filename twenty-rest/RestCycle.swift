import Foundation

nonisolated struct RestCycleConfiguration: Equatable, Sendable {
    var workInterval: Duration = .seconds(20 * 60)
    var restMinimum: Duration = .seconds(20)
}

nonisolated enum RestCyclePhase: Equatable, Sendable {
    case workInterval
    case restMinimum
    case restAwaitingReturn
}

nonisolated struct RestCycle: Equatable, Sendable {
    var configuration: RestCycleConfiguration
    private(set) var phase: RestCyclePhase
    /// Work Interval / Rest minimum: time left. Rest awaiting Return: overtime past the minimum.
    private(set) var remaining: Duration
    /// True when the Rest panel should be (re)presented.
    private(set) var shouldPresentRestPanel: Bool
    private var isSessionLocked: Bool

    init(configuration: RestCycleConfiguration = RestCycleConfiguration()) {
        self.configuration = configuration
        self.phase = .workInterval
        self.remaining = configuration.workInterval
        self.shouldPresentRestPanel = false
        self.isSessionLocked = false
    }

    var canReturn: Bool {
        phase == .restAwaitingReturn
    }

    var isInRest: Bool {
        phase == .restMinimum || phase == .restAwaitingReturn
    }

    mutating func acknowledgeRestPanelPresentation() {
        shouldPresentRestPanel = false
    }

    mutating func tick(by elapsed: Duration) {
        guard elapsed > .zero else { return }
        // While locked/asleep, the controller applies wall-clock elapsed once on unlock for Rest.
        // Do not also advance from the 1s ticker or Rest would double-count.
        guard !isSessionLocked else { return }

        switch phase {
        case .workInterval:
            remaining -= elapsed
            if remaining <= .zero {
                enterRest()
            }
        case .restMinimum:
            if elapsed >= remaining {
                let overtime = elapsed - remaining
                phase = .restAwaitingReturn
                remaining = overtime
            } else {
                remaining -= elapsed
            }
        case .restAwaitingReturn:
            remaining += elapsed
        }
    }

    mutating func markReturn() {
        guard canReturn else { return }
        beginWorkInterval()
    }

    /// Work Interval stops accumulating while locked; Rest wall-clock is applied on unlock.
    mutating func handleSessionLocked() {
        isSessionLocked = true
    }

    /// Clears the lock. Wall time ≥ Rest minimum → Reset (fresh Work Interval).
    /// Shorter locks: Work Interval resumes; Rest credits wall time and re-presents the panel.
    mutating func handleSessionUnlocked(wallTimeElapsedWhileLocked: Duration = .zero) {
        isSessionLocked = false

        if wallTimeElapsedWhileLocked >= configuration.restMinimum {
            beginWorkInterval()
            return
        }

        guard isInRest else { return }

        if wallTimeElapsedWhileLocked > .zero {
            tick(by: wallTimeElapsedWhileLocked)
        }
        shouldPresentRestPanel = true
    }

    var statusTitle: String {
        switch phase {
        case .workInterval, .restMinimum:
            return Self.formatCountdown(remaining)
        case .restAwaitingReturn:
            return "超过 \(Self.formatCountdown(remaining))"
        }
    }

    private mutating func enterRest() {
        phase = .restMinimum
        remaining = configuration.restMinimum
        shouldPresentRestPanel = true
    }

    private mutating func beginWorkInterval() {
        phase = .workInterval
        remaining = configuration.workInterval
        shouldPresentRestPanel = false
    }

    private static func formatCountdown(_ duration: Duration) -> String {
        let totalSeconds = max(0, Int(duration.components.seconds))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

import Foundation

struct RestCycleConfiguration: Equatable, Sendable {
    var workInterval: Duration = .seconds(20 * 60)
    var restMinimum: Duration = .seconds(20)
    var snoozeDuration: Duration = .seconds(5 * 60)
}

enum RestCyclePhase: Equatable, Sendable {
    case workInterval
    case restMinimum
    case restAwaitingReturn
    case paused
}

struct RestCycle: Equatable, Sendable {
    var configuration: RestCycleConfiguration
    private(set) var phase: RestCyclePhase
    private(set) var remaining: Duration
    /// True when the Rest panel should be (re)presented.
    private(set) var shouldPresentRestPanel: Bool
    private var phaseBeforePause: RestCyclePhase?
    private var remainingBeforePause: Duration?
    private var isSessionLocked: Bool

    init(configuration: RestCycleConfiguration = RestCycleConfiguration()) {
        self.configuration = configuration
        self.phase = .workInterval
        self.remaining = configuration.workInterval
        self.shouldPresentRestPanel = false
        self.phaseBeforePause = nil
        self.remainingBeforePause = nil
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
            remaining -= elapsed
            if remaining <= .zero {
                remaining = .zero
                phase = .restAwaitingReturn
            }
        case .restAwaitingReturn, .paused:
            break
        }
    }

    mutating func skip() {
        guard isInRest else { return }
        beginWorkInterval()
    }

    mutating func snooze() {
        guard isInRest else { return }
        phase = .workInterval
        remaining = configuration.snoozeDuration
        shouldPresentRestPanel = false
    }

    mutating func markReturn() {
        guard canReturn else { return }
        beginWorkInterval()
    }

    mutating func pause() {
        guard phase == .workInterval else { return }
        phaseBeforePause = phase
        remainingBeforePause = remaining
        phase = .paused
    }

    mutating func resume() {
        guard phase == .paused else { return }
        phase = phaseBeforePause ?? .workInterval
        remaining = remainingBeforePause ?? remaining
        phaseBeforePause = nil
        remainingBeforePause = nil
    }

    /// Work Interval stops accumulating while locked; Rest wall-clock is applied on unlock.
    mutating func handleSessionLocked() {
        isSessionLocked = true
    }

    /// Clears the lock. If still in Rest, applies wall time away; when that satisfies the
    /// Rest minimum, auto-Returns (no panel). Otherwise re-presents the Rest panel.
    mutating func handleSessionUnlocked(wallTimeElapsedWhileLocked: Duration = .zero) {
        isSessionLocked = false
        guard isInRest else { return }

        if wallTimeElapsedWhileLocked > .zero {
            tick(by: wallTimeElapsedWhileLocked)
        }

        if canReturn {
            markReturn()
        } else {
            shouldPresentRestPanel = true
        }
    }

    var statusTitle: String {
        switch phase {
        case .workInterval:
            return Self.formatCountdown(remaining)
        case .restMinimum:
            return Self.formatCountdown(remaining)
        case .restAwaitingReturn:
            return "休息好了"
        case .paused:
            return "⏸ \(Self.formatCountdown(remaining))"
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

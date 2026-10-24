import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class RestCycleController {
    private(set) var cycle: RestCycle
    private var settings: RestCycleSettings
    private var timer: Timer?
    private var lockStartedAt: Date?
    private var sessionObservers: [NSObjectProtocol] = []

    var isRestPanelPresented: Bool = false
    /// Stored so MenuBarExtra's label can observe second-by-second changes.
    private(set) var statusTitle: String = ""

    /// - Parameter enablesRuntime: Pass `false` in unit tests to skip Timer and lock observers.
    init(settings: RestCycleSettings = RestCycleSettings(), enablesRuntime: Bool = true) {
        self.settings = settings
        self.cycle = RestCycle(configuration: settings.configuration)
        self.statusTitle = cycle.statusTitle
        guard enablesRuntime else { return }
        startTicker()
        startSessionObservers()
    }

    var phase: RestCyclePhase { cycle.phase }
    var canReturn: Bool { cycle.canReturn }
    var isInRest: Bool { cycle.isInRest }
    var remaining: Duration { cycle.remaining }

    var workIntervalMinutes: Int {
        get { settings.workIntervalSeconds / 60 }
        set {
            settings.workIntervalSeconds = max(1, newValue) * 60
            updateStoredConfiguration()
        }
    }

    var restMinimumSeconds: Int {
        get { settings.restMinimumSeconds }
        set {
            settings.restMinimumSeconds = max(1, newValue)
            updateStoredConfiguration()
        }
    }

    func markReturn() {
        mutate { $0.markReturn() }
        dismissRestPanel()
    }

    /// Locks the Mac; RestCycle updates only via session lock observers.
    func lockScreen() {
        SystemScreenLock.lock()
    }

    func stopTicker() {
        timer?.invalidate()
        timer = nil
        for observer in sessionObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        sessionObservers = []
    }

    /// Advances the cycle clock (tests and future debug tooling).
    func advanceTime(by duration: Duration) {
        mutate { $0.tick(by: duration) }
        presentRestPanelIfNeeded()
    }

    /// Test seam for lock (mirrors `handleLocked` without recording a wall clock start).
    func beginSessionLockForTesting() {
        mutate { $0.handleSessionLocked() }
    }

    /// Applies unlock wall-clock catch-up (same path as real unlock / wake).
    func applySessionUnlock(wallTimeElapsed: Duration) {
        mutate { $0.handleSessionUnlocked(wallTimeElapsedWhileLocked: wallTimeElapsed) }
        if !cycle.isInRest {
            dismissRestPanel()
        }
        presentRestPanelIfNeeded()
    }

    private func dismissRestPanel() {
        isRestPanelPresented = false
    }

    private func mutate(_ body: (inout RestCycle) -> Void) {
        var copy = cycle
        body(&copy)
        cycle = copy
        statusTitle = copy.statusTitle
    }

    private func updateStoredConfiguration() {
        mutate { $0.configuration = settings.configuration }
    }

    private func startTicker() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tickOneSecond()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tickOneSecond() {
        advanceTime(by: .seconds(1))
    }

    private func presentRestPanelIfNeeded() {
        guard cycle.shouldPresentRestPanel else { return }
        isRestPanelPresented = true
        mutate { $0.acknowledgeRestPanelPresentation() }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func startSessionObservers() {
        let distributed = DistributedNotificationCenter.default()
        let locked = distributed.addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.handleLocked() }
        }
        let unlocked = distributed.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.handleUnlocked() }
        }

        let workspace = NSWorkspace.shared.notificationCenter
        let willSleep = workspace.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.handleLocked() }
        }
        let didWake = workspace.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.handleUnlocked() }
        }

        sessionObservers = [locked, unlocked, willSleep, didWake]
    }

    private func handleLocked() {
        if lockStartedAt == nil {
            lockStartedAt = Date()
        }
        mutate { $0.handleSessionLocked() }
    }

    private func handleUnlocked() {
        let elapsed: Duration
        if let started = lockStartedAt {
            let seconds = max(0, Int(Date().timeIntervalSince(started)))
            elapsed = .seconds(seconds)
            lockStartedAt = nil
        } else {
            elapsed = .zero
        }
        applySessionUnlock(wallTimeElapsed: elapsed)
    }
}

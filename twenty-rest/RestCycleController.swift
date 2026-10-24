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

    init(settings: RestCycleSettings = RestCycleSettings()) {
        self.settings = settings
        self.cycle = RestCycle(configuration: settings.configuration)
        startTicker()
        startSessionObservers()
    }

    var statusTitle: String { cycle.statusTitle }
    var phase: RestCyclePhase { cycle.phase }
    var canReturn: Bool { cycle.canReturn }
    var isInRest: Bool { cycle.isInRest }
    var isPaused: Bool { cycle.phase == .paused }
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

    var snoozeMinutes: Int {
        get { max(1, settings.snoozeSeconds / 60) }
        set {
            settings.snoozeSeconds = max(1, newValue) * 60
            updateStoredConfiguration()
        }
    }

    func skip() {
        mutate { $0.skip() }
        isRestPanelPresented = false
    }

    func snooze() {
        mutate { $0.snooze() }
        isRestPanelPresented = false
    }

    func markReturn() {
        mutate { $0.markReturn() }
        isRestPanelPresented = false
    }

    func pause() {
        mutate { $0.pause() }
    }

    func resume() {
        mutate { $0.resume() }
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

    private func mutate(_ body: (inout RestCycle) -> Void) {
        var copy = cycle
        body(&copy)
        cycle = copy
    }

    private func updateStoredConfiguration() {
        mutate { $0.configuration = settings.configuration }
    }

    private func startTicker() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickOneSecond()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tickOneSecond() {
        mutate { $0.tick(by: .seconds(1)) }
        presentRestPanelIfNeeded()
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
            Task { @MainActor in self?.handleLocked() }
        }
        let unlocked = distributed.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleUnlocked() }
        }

        let workspace = NSWorkspace.shared.notificationCenter
        let willSleep = workspace.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleLocked() }
        }
        let didWake = workspace.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleUnlocked() }
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
        let wasInRest = cycle.isInRest
        let elapsed: TimeInterval
        if let started = lockStartedAt {
            elapsed = Date().timeIntervalSince(started)
            lockStartedAt = nil
        } else {
            elapsed = 0
        }
        // Clear lock first so Rest wall-clock catch-up ticks are accepted.
        mutate { $0.handleSessionUnlocked() }
        if wasInRest, elapsed > 0 {
            mutate { $0.tick(by: .seconds(Int(elapsed))) }
        }
        presentRestPanelIfNeeded()
    }
}

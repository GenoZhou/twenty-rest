# Mac coarse signal for Continuity Rest Cycle clock

Research for [issue #3](https://github.com/GenoZhou/twenty-rest/issues/3). Resolves: what local legal coarse signal Mac should contribute when Continuity folds Mac into the same iCloud shared Rest Cycle clock, given no Mac DeviceActivity monitoring pipeline.

## Verdict

**Recommend:** Mac contributes the same coarse signal Mac v1 already uses for pacing — **session unlocked and machine awake** counts as screen-use time; **lock or sleep** stops Work Interval accumulation and applies ADR 0007 Reset / Rest wall-clock rules.

That is the only candidate that is (a) legally usable from public AppKit / Foundation APIs plus the lock names Mac v1 already observes, (b) semantically aligned with GLOSSARY “屏幕使用” as device-side screen availability (not eyes), and (c) alignable with iOS DeviceActivity’s screen-on / device-activity meaning without reopening ADR 0008 / 0009.

There is **no** Mac-side DeviceActivity monitor/threshold pipeline for third-party apps. Continuity must treat Mac as a **peer coarse contributor**, not as a Screen Time client.

## Domain anchors (repo)

| Term / rule | Source | Bearing on Mac signal |
| --- | --- | --- |
| Work Interval = stretch of **screen use** between rests | `GLOSSARY.md` | Positive clock advances only while local “screen use” is true |
| lock/sleep wall time ≥ Rest minimum → **Reset**; shorter lock freezes Work Interval | ADR 0007 | Lock/sleep is the **leave-screen** signal, not a separate product |
| Do **not** use keyboard/mouse idle | ADR 0008 | Idle is illegal for Continuity contribution |
| Do **not** use camera/Vision; Screen Time measures device/app activity, not eyes | ADR 0009 | Align Mac to device activity, not gaze |
| Menu-bar-only (`LSUIElement`) | ADR 0001 | “App in foreground” is the wrong presence proxy for this app |

Mac v1 wiring (`RestCycleController.startSessionObservers`):

- `DistributedNotificationCenter` names `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked`
- `NSWorkspace.willSleepNotification` / `NSWorkspace.didWakeNotification`
- While locked/asleep: ticker does not advance Work Interval; unlock applies wall time per ADR 0007 (`RestCycle.handleSessionLocked` / `handleSessionUnlocked`)

## iOS DeviceActivity meaning (alignment target)

Device Activity is a privacy-preserving way to monitor application and website activity on schedules/thresholds ([Device Activity](https://developer.apple.com/documentation/deviceactivity)).

Relevant coarse facts from Apple docs:

- Activity interval callbacks fire when the **device is in use** ([`intervalDidEnd(for:)`](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/intervaldidend(for:)); [`DeviceActivityCenter`](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter) overview).
- Report segment `totalActivityDuration` is **time the device’s screen remained on** ([`totalActivityDuration`](https://developer.apple.com/documentation/deviceactivity/deviceactivitydata/activitysegment/totalactivityduration)).
- Report extensions run in a **sandbox that forbids network / moving sensitive content out of the extension** ([`DeviceActivityReport`](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport)) — so Continuity cannot ship Screen Time Report data cross-device; each device must emit self-built Rest Cycle state (product constraint in map #1).

**Alignment rule:** shared clock “screen use” = **device screen-available / in-use coarse presence**, not gaze. Mac’s unlocked+awake interval is the same *kind* of coarse proxy as iOS screen-on / DeviceActivity “device in use.”

## Mac has no DeviceActivity monitoring pipeline

The macOS SDK ships a `DeviceActivity.framework`, but the monitoring types are marked unavailable on macOS (SDK `arm64e-apple-macos.swiftinterface`):

- `DeviceActivityCenter`, `DeviceActivityMonitor`, `DeviceActivitySchedule`, `DeviceActivityEvent`: `@available(macOS, unavailable)` (iOS 15+).
- `DeviceActivityAuthorization` is available `iOS 17.0, macOS 14.0` — authorization check only, not a monitor/threshold pipeline.

**Implication:** Mac cannot mirror iOS threshold extensions. Continuity must accept Mac’s coarser local session/display signal and sync Rest Cycle via app-owned storage (e.g. CloudKit), not system cross-device Screen Time reports.

## Candidate signals

### 1. Recommended — unlocked ∧ awake (Mac v1)

| Aspect | Assessment |
| --- | --- |
| **What** | Positive: wall clock while session unlocked and not asleep. Leave: lock or sleep → freeze / Rest credit / Reset (ADR 0007). |
| **Legal** | **Yes for sleep/wake:** documented `NSWorkspace.willSleepNotification` / `didWakeNotification` ([NSWorkspace environment notifications](https://developer.apple.com/documentation/appkit/nsworkspace#Responding-to-Environment-Notifications)). **Lock names:** observed via public `DistributedNotificationCenter` API ([DistributedNotificationCenter](https://developer.apple.com/documentation/foundation/distributednotificationcenter)); the strings `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked` are **not** listed as named constants in Apple Developer Documentation — same undocumented-name risk Mac v1 already accepts. |
| **Semantics vs 看屏** | Proxy for “display session available / Mac in interactive use,” not eyes. Matches ADR 0009’s device-activity framing and GLOSSARY screen use as paced by lock/sleep. Honest gap (ADR 0008): unlocked desk time without looking still counts. |
| **vs iOS DeviceActivity** | Same coarse layer as screen-on / “device in use.” Not app-category thresholds; Continuity should merge **intervals**, not Screen Time category tallies. |

**Optional documented supplements (same leave-screen family):**

- `NSWorkspace.screensDidSleepNotification` / `screensDidWakeNotification` ([docs](https://developer.apple.com/documentation/appkit/nsworkspace/screensdidsleepnotification)) — display sleep without full system sleep.
- `CGDisplayIsAsleep` ([docs](https://developer.apple.com/documentation/coregraphics/cgdisplayisasleep(_:))) — poll whether a display’s framebuffer is in reduced power mode.

Use as hardening of “awake,” not as a second product meaning.

### 2. Reject — “menu-bar / RestCycle app is frontmost”

| Aspect | Assessment |
| --- | --- |
| **Legal** | `NSRunningApplication.isActive` / `NSWorkspace.frontmostApplication` are public ([isActive](https://developer.apple.com/documentation/appkit/nsrunningapplication/isactive)). |
| **Semantics** | Wrong. ADR 0001 menu-bar app is rarely frontmost; frontmost tracks key-event focus, not screen use. Freezing when another app is frontmost would under-count reading/video — same failure mode ADR 0008 rejects for idle. |

### 3. Reject — keyboard/mouse idle

Standing ADR 0008. Not a Continuity candidate.

### 4. Reject — camera / Vision

Standing ADR 0009. Not a Continuity candidate.

### 5. Not recommended as primary — undocumented session lock dictionary keys

`CGSessionCopyCurrentDictionary` is public ([CGSession.h](https://developer.apple.com/documentation/coregraphics) / SDK header) and documents keys such as `kCGSessionOnConsoleKey` / `kCGSessionLoginDoneKey`. It does **not** document a screen-locked key. Relying on undocumented dictionary keys for lock state is weaker than the notification names Mac v1 already uses; do not promote as the Continuity legal signal.

### 6. Unavailable — DeviceActivity monitor on Mac

See above. Authorization-only on macOS does not substitute for coarse pacing.

## How to align to one shared clock

Conceptual merge (design guidance only; no CloudKit schema here):

1. **Local contribution bit (Mac):** `contributing = unlocked && !asleep` (and RestCycle app process alive).
2. **Local contribution bit (iOS):** DeviceActivity / screen-on style “device in use” coarse presence (product maps thresholds to Rest Cycle; details belong to iOS research / to-spec).
3. **Shared Work Interval:** advance while **any** Continuity device reports contributing (product intent: multi-device screen use = one eye-use period). Deduplicate overlapping intervals by wall clock, not by summing device minutes.
4. **Leave / Reset:** each device applies ADR 0007 locally for its own lock/sleep. Map-level open question remains how short leave on one device interacts with global Reset (issue #1 “Not yet specified”) — Mac signal choice does not resolve that policy.
5. **Never** export DeviceActivity Report contents off-device; sync only Rest Cycle state the apps own.

## Boundaries and degradation

| Boundary | Meaning |
| --- | --- |
| **Not eyes** | Signal is device screen-session availability. Unlocked idle desk time still counts (ADR 0008 honesty). |
| **Lock notification names undocumented** | Prefer keep parity with Mac v1; if names break, degrade to **sleep/wake + screensDidSleep/Wake / CGDisplayIsAsleep** only — lock-without-sleep may stop freezing until a documented lock API appears. |
| **App not running** | Mac contributes nothing; Continuity clock continues from other devices (or stalls if Mac-only). |
| **No Mac DeviceActivity** | Do not block Continuity on FamilyControls entitlement for Mac monitoring; Mac stays on session/display observers. |
| **Report sandbox** | iOS Report data cannot feed the shared clock; Mac has nothing analogous to contribute from Screen Time reports. |
| **Private login lock** | `SACLockScreenImmediate` (used by `SystemScreenLock`) is private; Continuity should **observe** lock/sleep, not depend on private lock APIs for the clock. |

## Sources

### Repo

- `GLOSSARY.md` — Work Interval / Rest / Return / Reset / Rest Cycle
- `docs/adr/0001-menu-bar-only.md`, `0007-unified-lock-reset-and-simpler-rest-exits.md`, `0008-no-idle-as-screen-use.md`, `0009-no-vision-as-screen-use.md`
- `twenty-rest/RestCycleController.swift` — session observers
- `twenty-rest/RestCycle.swift` — lock freeze / unlock Reset

### Apple Developer Documentation / SDK

- [Device Activity](https://developer.apple.com/documentation/deviceactivity)
- [DeviceActivityCenter](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter)
- [DeviceActivityMonitor.intervalDidEnd(for:)](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/intervaldidend(for:))
- [DeviceActivityData.ActivitySegment.totalActivityDuration](https://developer.apple.com/documentation/deviceactivity/deviceactivitydata/activitysegment/totalactivityduration)
- [DeviceActivityReport](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport) (sandbox: no network / no sensitive egress)
- [NSWorkspace willSleepNotification](https://developer.apple.com/documentation/appkit/nsworkspace/willsleepnotification), [didWakeNotification](https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification), [screensDidSleepNotification](https://developer.apple.com/documentation/appkit/nsworkspace/screensdidsleepnotification)
- [DistributedNotificationCenter](https://developer.apple.com/documentation/foundation/distributednotificationcenter)
- [CGDisplayIsAsleep](https://developer.apple.com/documentation/coregraphics/cgdisplayisasleep(_:))
- [NSRunningApplication.isActive](https://developer.apple.com/documentation/appkit/nsrunningapplication/isactive)
- macOS SDK `DeviceActivity.swiftmodule` (`arm64e-apple-macos.swiftinterface`): monitoring types `@available(macOS, unavailable)`; `DeviceActivityAuthorization` available macOS 14.0+
- macOS SDK `CoreGraphics/CGSession.h`: `CGSessionCopyCurrentDictionary` documented keys (no lock key)

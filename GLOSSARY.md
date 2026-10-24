# Twenty Rest

A personal macOS menu-bar tool that paces screen work with the 20-20-20 eye-rest rhythm to ease dry-eye and accommodative fatigue.

## Language

**Work Interval**:
The stretch of screen use between rests. Default length is 20 minutes.
_Avoid_: Session, focus block, pomodoro

**Rest**:
The distant-gaze pause after a Work Interval. The cue is to look about 20 feet / 6 metres away. Default **minimum** length is 20 seconds; Rest may run longer until the user returns.
_Avoid_: Break, pause, alarm (too generic or implies audio-only)

**Return**:
Ending a Rest after its minimum has elapsed and starting the next Work Interval. In v1 this is always a manual confirmation.
_Avoid_: Resume, dismiss, unlock (ambiguous with system lock)

**Rest Cycle**:
One Work Interval followed by one Rest. The app’s core rhythm is repeating Rest Cycles.
_Avoid_: Round, loop, timer cycle

**Skip**:
Ending the current Rest immediately and starting the next Work Interval.
_Avoid_: Dismiss, cancel

**Pause**:
Temporarily stopping Work Interval accumulation so a Rest will not become due until the user continues. Distinct from system lock/sleep pausing, but same idea: time in Pause does not count as screen work.
_Avoid_: Stop, disable (those imply turning the app off)

**Status Title**:
The compact text (and optional symbol) shown in the menu bar itself — primarily the countdown for the current Work Interval or Rest phase — so glanceability does not require opening the menu.
_Avoid_: Label, badge (unless referring to a numeric badge API specifically)

**Snooze**:
Leaving the current Rest without completing it, and scheduling the next Rest prompt after a short delay (default 5 minutes). The Work Interval effectively continues for that delay.
_Avoid_: Postpone, delay (unless talking about the delay length itself)

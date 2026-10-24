# Twenty Rest

A personal macOS menu-bar tool that paces screen work with the 20-20-20 eye-rest rhythm to ease dry-eye and accommodative fatigue.

## Language

**Work Interval**:
The stretch of screen use between rests. Default length is 20 minutes.
_Avoid_: Session, focus block, pomodoro

**Rest**:
The distant-gaze pause after a Work Interval. The cue is to look about 20 feet / 6 metres away. It has a configured **minimum**; before that minimum the UI counts down, and after it the UI counts up how long Rest has continued past the minimum (`超过 m:ss`) until Return or Reset.
_Avoid_: Break, pause, alarm (too generic or implies audio-only)

**Return**:
The user's confirmation that Rest is done (after its minimum), which starts the next Work Interval. In the UI this is the 「休息好了」 action — not lock/sleep.
_Avoid_: Resume, dismiss, Reset, 回来了

**Reset**:
Starting a fresh Work Interval because lock/sleep wall time met or exceeded the configured Rest minimum, regardless of the phase before the lock. Distinct from Return (user confirmation).
_Avoid_: Return, restart, clear

**Rest Cycle**:
One Work Interval followed by one Rest. The app’s core rhythm is repeating Rest Cycles.
_Avoid_: Round, loop, timer cycle

**Status Title**:
The compact text shown in the menu bar — Work Interval countdown, Rest minimum countdown, or Rest overtime (`超过 m:ss`) — so glanceability does not require opening the menu.
_Avoid_: Label, badge (unless referring to a numeric badge API specifically)

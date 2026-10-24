# ADR 0003: Rest is a minimum; Work Interval starts on Return

## Status

Accepted (amended by [ADR 0007](0007-unified-lock-reset-and-simpler-rest-exits.md))

## Context

Classic 20-20-20 asks for at least 20 seconds of distant gaze, but people often stand up, walk, or look away longer. Ending Rest when a 20-second timer hits zero would start the next Work Interval while the user is still away from the screen. Keyboard/mouse “back at computer” detection needs Accessibility permission and is planned as a later signal.

## Decision

- Treat the Rest duration as a **minimum** (default 20 seconds), not an exact slot.
- After the minimum elapses, stay in Rest until the user **Returns** (manual confirmation, UI: 「休息好了」), or until lock/sleep wall time meets the Rest minimum and **Resets** (ADR 0007).
- Do not use keyboard/mouse activity to end Rest in v1.
- Do not send system notifications for Rest due; the auto-presented Rest panel is the interrupt when Return is still required.

## Consequences

- Rest UI shows countdown through the minimum, then overtime (`超过 m:ss`) until Return or Reset.
- Work Interval time only accumulates while the user is actually in a Work Interval, not during an over-long Rest.
- Skip was removed (ADR 0007); it is no longer an exit from Rest.

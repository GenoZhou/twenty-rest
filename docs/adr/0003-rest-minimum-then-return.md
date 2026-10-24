# ADR 0003: Rest is a minimum; Work Interval starts on Return

## Status

Accepted

## Context

Classic 20-20-20 asks for at least 20 seconds of distant gaze, but people often stand up, walk, or look away longer. Ending Rest when a 20-second timer hits zero would start the next Work Interval while the user is still away from the screen. Keyboard/mouse “back at computer” detection needs Accessibility permission and is planned as a later signal.

## Decision

- Treat the Rest duration as a **minimum** (default 20 seconds), not an exact slot.
- After the minimum elapses, stay in Rest until the user **Returns** (manual confirmation in v1).
- Do not use keyboard/mouse activity to end Rest in v1.
- Skip still ends Rest immediately and starts the next Work Interval.
- Do not send system notifications for Rest due; the auto-presented Rest panel is the interrupt.

## Consequences

- Rest UI must show two phases: counting down the minimum, then “ready — Return when you’re back.”
- Work Interval time only accumulates while the user is actually in a Work Interval, not during an over-long Rest.
- A later release may treat input activity as an automatic Return after the minimum; that complements this decision.

# ADR 0008: Do not treat keyboard/mouse idle as leaving the screen

## Status

Accepted

## Context

ADR 0002 / 0005 left keyboard/mouse idle as a later signal for pausing the Work Interval without lock/sleep. That proxy fails for Twenty Rest’s meaning of screen use: reading, watching video, or staring at the display without touching input still strains the eyes. Freezing the Work Interval then would silently stretch cadence and under-count real near work.

## Decision

Do **not** use keyboard/mouse idle (or lack of input) to pause, freeze, or Reset a Work Interval, or to end Rest. Leaving the screen remains lock/sleep (and any future signal that is actually about eyes / presence at the display), not hand activity.

This strengthens ADR 0005’s v1 exclusion into a standing product rule, not a temporary deferral.

## Consequences

- Time at the desk without locking still counts as Work Interval time (unchanged from ADR 0002’s honest gap).
- Accessibility-based idle detection is not on the roadmap for pacing.
- Camera / Vision signals, if ever revisited, must be judged on their own (eyes / person), not as a replacement for idle.

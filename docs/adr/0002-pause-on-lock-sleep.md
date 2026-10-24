# ADR 0002: Pause the Work Interval on lock/sleep (v1)

## Status

Superseded by [ADR 0007](0007-unified-lock-reset-and-simpler-rest-exits.md)

## Context

A Work Interval should reflect time spent looking at the screen, not wall-clock time while the Mac is locked or asleep. Idle detection via keyboard/mouse (Accessibility) is planned later and needs extra permissions. Screen lock and sleep are available without that.

## Decision

In v1, pause the Work Interval when the Mac locks or sleeps; resume the same interval when the session unlocks / wakes. Do not require Accessibility for idle pause in v1.

## Consequences

- Lock/sleep handling is part of the core timer, not an optional enhancement.
- Time away from the desk without locking still counts as Work Interval time until a later idle signal exists.
- A future “pause when idle” feature complements this decision; it does not replace lock/sleep pausing.

## Supersession note

ADR 0007 keeps short-lock freeze of Work Interval accumulation, but unlock after wall time ≥ Rest minimum **Resets** to a fresh Work Interval instead of always resuming the prior remaining. Manual Pause was removed.

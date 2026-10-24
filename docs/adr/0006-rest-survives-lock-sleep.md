# ADR 0006: Rest survives lock/sleep; auto-Return when lock covers the minimum

## Status

Superseded by [ADR 0007](0007-unified-lock-reset-and-simpler-rest-exits.md)

## Context

Users may lock or sleep the Mac as part of resting (stand up, look away). Work Interval already pauses on lock/sleep, so a Rest generally will not become newly due while locked. The important case is a Rest that was already due or in progress when lock/sleep happens.

Requiring a manual Return after a long lock feels like busywork when the lock itself already exceeded the Rest minimum. Auto-Return on every unlock would be wrong when the user unlocks before the minimum is met.

## Decision

- Lock/sleep does not cancel an in-progress Rest.
- Rest minimum duration uses wall-clock time applied once on unlock (the 1s ticker does not advance while locked).
- On unlock/wake during Rest:
  - If wall time away satisfies the Rest minimum (Return would be allowed) → **auto-Return** into the next Work Interval; do not present the Rest panel.
  - Otherwise → keep Rest, automatically re-present the Rest panel; user still Returns, Skips, or Snoozes.
- Do not use system notifications.

## Consequences

- Lock-away longer than the remaining Rest minimum is a first-class “I rested by leaving” path.
- Brief unlocks before the minimum still show the panel.
- Work Interval lock/pause behavior is unchanged (ADR 0002).

## Supersession note

ADR 0007 replaces auto-Return with **Reset** when wall time ≥ the **configured** Rest minimum (any phase, not only Rest), drops Skip/Snooze from the short-unlock path, and keeps short Rest unlocks on the panel until Return.

# ADR 0006: Rest survives lock/sleep; re-present panel on wake

## Status

Accepted

## Context

Users may lock or sleep the Mac as part of resting (stand up, look away). Work Interval already pauses on lock/sleep, so a Rest generally will not become newly due while locked. The important case is a Rest that was already due or in progress when lock/sleep happens.

Auto-Return on wake would start the next Work Interval before the user has confirmed they are back at the screen. System notifications for this were rejected in v1.

## Decision

- Lock/sleep does not cancel an in-progress Rest.
- Rest minimum duration uses wall-clock time (time asleep counts toward the minimum).
- On unlock/wake, if still in Rest, automatically re-present the Rest panel.
- Do not auto-Return and do not notify; the user still Returns, Skips, or Snoozes.

## Consequences

- Lock-to-rest is a first-class path: sleep five minutes, wake, panel shows Return-ready.
- Rest panel presentation must be re-triggerable from session unlock/wake observers, not only from the original due transition.

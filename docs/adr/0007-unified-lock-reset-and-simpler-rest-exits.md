# ADR 0007: Unified lock Reset and simpler Rest exits

## Status

Accepted

## Context

In-app copy promised “lock longer than Rest minimum → reset,” but unlock behavior branched by phase (Work froze; Rest could auto-Return). Skip, Snooze, and manual Pause also gave several ways to leave Rest without locking, which fought the simpler rule: looking at the screen counts; leaving means lock or close the lid.

## Decision

- Wall time locked/asleep ≥ configured Rest minimum → **Reset** to a fresh Work Interval from any phase; no Rest panel.
- Shorter locks: Work Interval resumes remaining (time away does not count as screen use); Rest credits wall time toward the minimum / overtime and re-presents the panel; never auto-Return on short unlock.
- Rest exits are only **Return** (UI: 「休息好了」) or **Reset**. Remove Skip, Snooze, and manual Pause.
- After the Rest minimum, Status Title counts up (`超过 m:ss`) until Return or Reset.
- Rest panel may offer a system lock control; locking itself does not mutate the cycle beyond the normal lock observers.

## Consequences

- Supersedes ADR 0002’s “always resume the same Work Interval,” ADR 0006’s auto-Return-on-sufficient-lock, and the Skip/Snooze/Pause surface in ADR 0003 / 0005.
- Short lock freeze for Work Interval remains (implementation of “don’t count closed-lid time”), but long lock Resets instead of continuing the old countdown.

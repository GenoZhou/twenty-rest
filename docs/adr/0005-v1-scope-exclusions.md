# ADR 0005: v1 scope exclusions

## Status

Accepted (amended by [ADR 0007](0007-unified-lock-reset-and-simpler-rest-exits.md))

## Context

The product vision includes later signals (Vision blink detection, keyboard/mouse activity). Shipping those in v1 would couple the first useful cadence tool to permissions and unverified accuracy.

## Decision

v1 excludes: camera / Vision blink detection; keyboard/mouse idle detection; system notifications for Rest; Live Activities; accounts, sync, and multi-user features.

v1 includes: menu-bar-only pacing; configurable Work Interval / Rest minimum (defaults 20 min / 20 s); Rest panel with Return and optional system lock; lock/sleep freeze of Work Interval and Reset when lock covers the Rest minimum (ADR 0007); launch-at-login (default on); Chinese UI; silent by default.

v1 does **not** include Skip, Snooze, or manual Pause (removed in ADR 0007).

## Consequences

Later features are additive signals around the same Rest Cycle model, not a rewrite of v1’s meaning of Rest and Return.

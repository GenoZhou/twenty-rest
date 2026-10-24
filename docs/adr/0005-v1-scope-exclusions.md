# ADR 0005: v1 scope exclusions

## Status

Accepted

## Context

The product vision includes later signals (Vision blink detection, keyboard/mouse activity). Shipping those in v1 would couple the first useful cadence tool to permissions and unverified accuracy.

## Decision

v1 excludes: camera / Vision blink detection; keyboard/mouse idle detection; system notifications for Rest; Live Activities; accounts, sync, and multi-user features.

v1 includes: menu-bar-only pacing; configurable Work Interval / Rest minimum (defaults 20 min / 20 s); Rest panel with Skip, Snooze, and Return; pause on lock/sleep; manual pause during Work Interval; launch-at-login (default on); Chinese UI; silent by default.

## Consequences

Later features are additive signals around the same Rest Cycle model, not a rewrite of v1’s meaning of Rest and Return.

# ADR 0004: Rest interrupt is an app Rest panel, not Live Activities

## Status

Accepted

## Context

Live Activities can appear in the Mac menu bar, but Apple’s model is ActivityKit from an iPhone/iPad app (with widget extension), including Continuity / iPhone Mirroring onto a paired Mac. Twenty Rest is a native macOS menu-bar tool that must reliably present Rest, Skip, Snooze, and Return under its own control. System notifications were already rejected for Rest due.

## Decision

v1 uses an app-owned Rest panel that auto-presents when a Rest is due. Do not adopt ActivityKit / Live Activities for the Rest interrupt or for Work Interval status.

## Consequences

- UI is `MenuBarExtra` (or equivalent) plus an app-controlled panel/popover.
- Menu bar status remains the glanceable Work Interval / Rest indicator.
- A later cross-device or iOS companion could revisit Live Activities; that would be a different product surface.

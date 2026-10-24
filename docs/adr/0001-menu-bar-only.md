# ADR 0001: Menu-bar-only app (no Dock icon)

## Status

Accepted

## Context

Twenty Rest is a personal, always-on pacing tool. A normal windowed app with a Dock icon competes for attention and feels heavier than a rhythm helper that should stay out of the way until a Rest is due.

## Decision

Ship v1 as a menu-bar-only app (`LSUIElement`): no Dock icon. Status, controls, and the Rest panel all hang off the menu bar extra.

## Consequences

- Settings and Rest UI must work in popovers/panels, not a primary `WindowGroup` document window.
- Activation policy and scene setup differ from the current scaffold (`WindowGroup` hello-world).
- Adding a Dock presence later is possible but would change how users discover and quit the app.

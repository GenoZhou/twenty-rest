# Coding Standards

Read during **review**, not while implementing. For Rest / lock semantics, read [ADR 0007](docs/adr/0007-unified-lock-reset-and-simpler-rest-exits.md) (current). Older ADRs 0002 / 0003 / 0005 / 0006 are superseded or amended — do not enforce their obsolete exits (Skip, Snooze, Pause, unlock auto-Return).

## MenuBarExtra Status Title

Use `Image` + `Text` for the menu bar label. Do not rely on `Label(title, systemImage:)` alone — macOS often renders that as **icon-only**, so the countdown Status Title disappears.

## Rest panel dismissal

Every path that leaves Rest (**Return** or **Reset**) must clear `isRestPanelPresented` the same way. Prefer a test on `RestCycleController` over trusting call-site symmetry.

## Help copy matches unlock rules

Menu help bullets and Rest panel copy must match ADR 0007 / `RestCycle` unlock behavior (Reset when wall time ≥ Rest minimum; short Rest unlock credits time and keeps/re-presents the panel). If copy and code disagree, change one so they agree — prefer the ADR.

## No Divider for empty sections

When a `@ViewBuilder` section is conditional and may render nothing (e.g. Rest-only actions), place any `Divider` **inside** that same condition (or after a confirmed non-empty block). An empty section must not leave a lone divider.

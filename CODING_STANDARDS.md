# Coding Standards

Read during **review**, not while implementing. For Rest / lock semantics, also read ADR 0002, 0003, and 0006.

## MenuBarExtra Status Title

Use `Image` + `Text` for the menu bar label. Do not rely on `Label(title, systemImage:)` alone — macOS often renders that as **icon-only**, so the countdown Status Title disappears.

## Rest panel dismissal

Every path that leaves Rest (Skip, Snooze, Return, and unlock auto-Return) must clear `isRestPanelPresented` the same way. Prefer a test on `RestCycleController` over trusting call-site symmetry.

# ADR 0009: Do not use camera / Vision to infer screen use

## Status

Accepted

## Context

ADR 0005 deferred camera / Vision blink detection. Multi-display use makes “looking at the screen” unmeasurable with a typical Mac camera: Vision sees the person in the camera FOV (face / landmarks / blink proxies), not which display has gaze. Side monitors and head pose create false absences and false presence.

## Decision

Do **not** use camera or Vision (presence, blink, rough gaze) to pause/freeze/Reset a Work Interval or to end Rest. Screen-leaving signals stay lock/sleep (and any future non-camera approach that is actually about display activity, if product scope expands).

## Consequences

- No camera permission for pacing.
- Blink-as-fatigue and presence-as-use-eye remain out of scope.
- iOS Screen Time / DeviceActivity (if ever considered) is a separate question: those APIs measure device/app activity, not eyes.

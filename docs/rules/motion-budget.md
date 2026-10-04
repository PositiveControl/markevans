---
id: motion-budget
title: "Motion only on a state change, 150–300 ms ease-out; the sweep and the remaining-time line are the only continuous motion"
applies_to: ["app/assets/**", "app/javascript/**"]
triggers: ["animation", "transition", "keyframes", "scroll", "reduced motion"]
see_also: ["playback-yields", "every-element-answers", "stimulus"]
modes: [ web ]
tokens: 320
current_state: matches
---

# motion-budget

Motion happens only on a state change, lasts 150 to 300 ms, and eases out. Two things move continuously, and both are the step clock: the sweep, which turns only while playing and is hidden under reduced motion, and the active strip's remaining-time line (design doc, section 6), which freezes when paused.

## Why

Motion here is information: something changed. Ambient motion dilutes that.

## Wrong

```
Strips sliding in as they scroll into view.
```

## Right

```
A strip rolling up when its step completes.
```

## Enforcement

Prose only. The values in use: roll-up 200 ms (`StepBodyComponent`), leader 300 ms (`ScopeComponent`), row dimming 150 ms (`ChartCellComponent`), bay fill 150 ms (`StripBayComponent`), all `ease-out` and `motion-reduce:transition-none` where they move layout.

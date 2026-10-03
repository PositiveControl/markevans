---
id: motion-budget
title: "Motion only on a state change, 150–300 ms ease-out; the sweep is the one continuous motion"
applies_to: ["app/assets/**", "app/javascript/**"]
triggers: ["animation", "transition", "keyframes", "scroll", "reduced motion"]
see_also: ["playback-yields", "every-element-answers", "stimulus"]
modes: [ web ]
tokens: 260
current_state: diverges
---

# motion-budget

Motion happens only on a state change, lasts 150 to 300 ms, and eases out. The sweep is the one continuous motion, and it stops under reduced motion.

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

Prose only.

## Where this app is

The current home page's `reveal` controller slides sections in on scroll, which this rule forbids. Slice 1 removes that page; slice 3 adds the roll-up and sweep under this budget.

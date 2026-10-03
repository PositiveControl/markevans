---
id: never-color-alone
title: "Every state or kind shown by color is also shown by a shape or a word"
applies_to: ["app/components/**"]
triggers: ["state", "status", "kind", "gate", "a11y", "contrast"]
see_also: ["color-means-role", "real-controls", "accessibility"]
modes: [ web ]
tokens: 270
current_state: diverges
---

# never-color-alone

Every state or kind shown by color is also shown by a shape or a word.

## Why

Amber and green are close for many readers, and a strip must still read in greyscale and to a screen reader.

## Wrong

```
A gate distinguished from a command only by its tint.
```

## Right

```
A solid triangle on the chart, the word "hold" or "cleared" on the strip, and the tint.
```

## Enforcement

Partly gated: axe runs on every route in playing, paused and no-script states.

## Where this app is

No strips or chart exist yet, and the axe gate does not exist. Slice 1 renders shapes and words with the static thread; slice 3 adds axe in system tests across playing, paused and no-script states.

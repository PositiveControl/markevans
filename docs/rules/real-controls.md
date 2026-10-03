---
id: real-controls
title: "Anything clickable is a button or link with an accessible name, at least 44 px, with ARIA state"
applies_to: ["app/components/**"]
triggers: ["button", "click", "aria", "focus", "keyboard", "touch target"]
see_also: ["never-color-alone", "accessibility"]
modes: [ web ]
tokens: 240
current_state: diverges
---

# real-controls

Anything clickable is a button or a link with an accessible name, at least 44 px. Pressed and expanded states use ARIA attributes.

## Why

Strips, targets and controls must work by keyboard and be announced correctly.

## Wrong

```
div data-action="click->playback#jump"
```

## Right

```
button type="button" aria-expanded="true" data-action="playback#toggle"
```

## Enforcement

Gated: axe in system tests.

## Where this app is

No thread controls exist yet, and the axe gate does not exist. Slice 3 adds the controls, strips-as-buttons and axe in system tests.

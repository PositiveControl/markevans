---
id: real-controls
title: "Anything clickable is a button or link with an accessible name, at least 44 px, with ARIA state"
applies_to: ["app/components/**"]
triggers: ["button", "click", "aria", "focus", "keyboard", "touch target"]
see_also: ["never-color-alone", "accessibility"]
modes: [ web ]
tokens: 270
current_state: matches
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

Gated: axe in system tests (`assert_accessible` in `test/application_system_test_case.rb`), run in `test/system/home_playback_test.rb` while playing, paused and without scripts, plus a check that every visible control is at least 44 px. System tests run locally (`bin/rails test:system`), not in CI.

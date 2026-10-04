---
id: playback-yields
title: "Reader input always wins: scroll, tab switch or selecting a step pauses, and nothing auto-resumes"
applies_to: ["app/javascript/**"]
triggers: ["autoplay", "scroll", "resume", "pause", "visibility"]
see_also: ["one-playback-state", "motion-budget"]
modes: [ web ]
tokens: 280
current_state: matches
---

# playback-yields

Reader input always wins. Scrolling, leaving the tab or selecting a step pauses. Nothing resumes by itself.

## Why

A page that moves under a reader who has taken over is the fastest way to lose them.

## Wrong

```
Resuming playback after five seconds without input.
```

## Right

```
Staying paused until the reader presses Play.
```

## Enforcement

System tests in `test/system/home_playback_test.rb`: a wheel, a touch scroll, a scroll key, leaving the tab and selecting a step each pause, and nothing resumes after two steps' time. Playback hears the reader's input, not the `scroll` event, so its own follow never counts as one (`docs/system/home-thread-playback.md`, *Follow and yield*).

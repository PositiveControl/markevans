---
id: playback-yields
title: "Reader input always wins: scroll, tab switch or selecting a step pauses, and nothing auto-resumes"
applies_to: ["app/javascript/**"]
triggers: ["autoplay", "scroll", "resume", "pause", "visibility"]
see_also: ["one-playback-state", "motion-budget"]
modes: [ web ]
tokens: 310
current_state: diverges
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

System tests: scroll during play pauses; no timer restarts it.

## Where this app is

Selecting a step (a target, a strip, back or forward) pauses, and leaving the tab pauses with nothing resuming it, both covered in `test/system/home_playback_test.rb` (#16). Playback starts by itself only once, when the thread first scrolls into view, and not after the reader has touched a control. Pause on reader scroll, and the follow that must not count as one, arrive with slice 5 (#18).

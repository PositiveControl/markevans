---
id: no-invented-content
title: "Numbers, quotes and artifacts come from a repo or from Mark; unknowns stay in [brackets]"
applies_to: ["content/**"]
triggers: ["numbers", "metrics", "quotes", "ledger", "placeholder", "TBD"]
see_also: ["content-is-files"]
modes: [ web ]
tokens: 260
current_state: diverges
---

# no-invented-content

Numbers, quotes and artifacts come from a repo or from Mark. Anything unknown stays in square brackets.

## Why

The site is a claim about how carefully work is done. One made-up figure undoes it.

## Wrong

```
added_lines: 842   # looked plausible
```

## Right

```
added_lines: "[n]"   # until read from the PR
```

## Enforcement

Gated: the placeholder gate fails a production build on any square-bracket placeholder or "TBD".

## Where this app is

The placeholder gate does not exist yet, so nothing stops a `[placeholder]` or TBD reaching production. Slice 1 adds it. `home.yml` holds bracket placeholders on purpose until the example feature is chosen.

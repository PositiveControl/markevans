---
id: no-invented-content
title: "Numbers, quotes and artifacts come from a repo or from Mark; unknowns stay in [brackets]"
applies_to: ["content/**"]
triggers: ["numbers", "metrics", "quotes", "ledger", "placeholder", "TBD"]
see_also: ["content-is-files"]
modes: [ web ]
tokens: 260
current_state: matches
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

Gated: `bin/rails content:placeholders` fails a production build (it runs ahead of `assets:precompile` when `RAILS_ENV=production`) on any square-bracket placeholder or "TBD". It does not run on push or in CI, where placeholders are expected while content is written. A bracket followed by `(` is a markdown link.

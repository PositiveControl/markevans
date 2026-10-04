---
id: tokens-only
title: "Color, size, spacing and radius come from the design tokens; no literal values outside the token file"
applies_to: ["app/components/**", "app/views/**", "app/helpers/**", "app/assets/**", "app/javascript/**"]
triggers: ["color", "hex", "rgb", "font-size", "radius", "spacing"]
see_also: ["color-means-role", "tailwind"]
modes: [ web ]
tokens: 290
current_state: matches
---

# tokens-only

Color, size, spacing and radius come from the tokens in `app/assets/tailwind/tokens.css`, which is section 3 of the design doc. No literal value appears outside that file.

## Why

A literal drifts from the palette the first time someone adjusts it, and the palette is the meaning system: each color is a role.

## Wrong

```
div class="text-[#0F7480] rounded-[3px]"
```

## Right

```
div class="text-command rounded-box"
```

## Enforcement

Gated: `bin/gates` (pre-push and CI) fails on a hex value or a CSS color function (`rgb(`, `hsl(`, `oklch(` …) in `app/components`, `app/views`, `app/helpers`, `app/assets` or `app/javascript` outside `app/assets/tailwind/tokens.css`.

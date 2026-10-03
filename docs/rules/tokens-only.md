---
id: tokens-only
title: "Color, size, spacing and radius come from the design tokens; no literal values outside the token file"
applies_to: ["app/components/**", "app/views/**", "app/helpers/**", "app/assets/**", "app/javascript/**"]
triggers: ["color", "hex", "rgb", "font-size", "radius", "spacing"]
see_also: ["color-means-role", "tailwind"]
modes: [ web ]
tokens: 400
current_state: diverges
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

## Where this app is

`app/assets/tailwind/tokens.css` holds the tokens and `bin/gates` fails on a literal color anywhere else, but nothing uses the tokens yet: `application.css` does not import the file, because the old portfolio page's own `@theme` defines `--color-ink` and `--color-rule` for its dark palette. That file is allow-listed in the gate by name. #21 deletes the old page, imports the tokens and removes the allow-list.

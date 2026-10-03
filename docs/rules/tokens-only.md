---
id: tokens-only
title: "Color, size, spacing and radius come from the design tokens; no literal values outside the token file"
applies_to: ["app/components/**", "app/assets/**", "app/javascript/**"]
triggers: ["color", "hex", "rgb", "font-size", "radius", "spacing"]
see_also: ["color-means-role", "tailwind"]
modes: [ web ]
tokens: 300
current_state: diverges
---

# tokens-only

Color, size, spacing and radius come from the tokens in the design doc (section 2). No literal value appears outside the token file.

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

Gated: the literal-color gate greps for hex and rgb( outside the token file.

## Where this app is

There is no token file and no literal-color gate. `app/assets/tailwind/application.css` holds the current page's own hex and rgb values. Slice 1 adds the token file (design doc, section 3), replaces those values, and adds the gate.

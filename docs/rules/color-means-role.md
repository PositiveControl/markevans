---
id: color-means-role
title: "Each color is used only for its role: command, human gate, automated gate"
applies_to: ["app/components/**", "content/**"]
triggers: ["amber", "green", "teal", "accent", "highlight", "emphasis"]
see_also: ["never-color-alone", "tokens-only"]
modes: [ web ]
tokens: 230
current_state: matches
---

# color-means-role

A color is used only for its role. Command color means a command, the feature branch, or a link. Amber means a human gate. Green means an automated gate. Emphasis is done with ink, weight or position.

## Why

The reader learns the legend once. One amber button that is not a gate teaches them the legend is unreliable.

## Wrong

```
An amber "Contact me" button, because it stands out.
```

## Right

```
An ink button. Amber appears only on G1, G2 and G4.
```

## Enforcement

Prose only. Reviewed in /pr_review.

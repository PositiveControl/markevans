---
id: view-code-placement
title: Where view code goes — component, partial, helper, inline
applies_to: ["app/views/**", "app/components/**", "app/helpers/**"]
triggers: ["component or partial", "where does this markup go", "helper", "extract markup", "reuse markup", "jsonld_tag"]
see_also: ["components", "partials", "pattern-budget"]
modes: [ web ]
tokens: 430
current_state: matches
---

# Where view code goes

Four places, in order of preference. Pick the first one that fits.

| | Use for | Test |
|---|---|---|
| **Component** (`app/components/`) | A UI unit with markup + logic + variants, used in >1 place | Unit test, renders in isolation |
| **Partial** (`app/views/**/_x.html.slim`) | Markup reused inside one resource, no logic | Covered by the view's test |
| **Helper** (`app/helpers/`) | Stateless formatting: a date, a currency, a class string | Plain unit test |
| **Inline** | Used once, under ~10 lines | The page test |

**The dividing line between partial and component:** does it take logic? A partial
that starts with three `- if` lines and a class-string calculation is a
[component](components.md) that hasn't been written yet. A component with no logic
and one caller is a [partial](partials.md) with extra ceremony.

**Helpers stay stateless.** A helper that takes a record and returns markup is a
component. A helper that formats a value is a helper.

## Helpers that ship

```slim
= jsonld_tag(schema_hash)
```

See `app/helpers/` for the full signatures. The template's `progress_bar` and
`capacity_bar` were removed here: they built palette class names at runtime,
and this app's tokens clear Tailwind's palette.

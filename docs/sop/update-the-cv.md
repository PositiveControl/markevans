# Update the CV

**Status:** Complete — written for #38; that PR checks it against the cut it lands

How to re-cut `/background`, and the CV-sourced copy on `/contact` and
`/work`, when Mark's master resume changes. Why the site is a cut and not the
whole resume: `docs/plans/2026-10-04-cv-content-design.md`.

---

## The rule

The master resume is a superset. The site selects and reorders its wording
and never adds to it (`docs/rules/no-invented-content.md`). If the resume
does not say it, the site keeps the `[bracket]`.

## What never comes across

- Italic asides in the resume: interview context, attribution rules, lane
  and framing notes. Obey them, but never publish them.
- `[[NEEDS: …]]` markers, and any claim one of them guards.
- The phone number, the clearance, the Navy dates, the references.
- Anything the resume's cut list names.

Attribution rules the cut must keep:
- The card-recognition layer is "contributed to and maintain", never "built".
- Stripe Connect is a system he works inside, not one he built.
- SyberJet avionics is a proof-of-concept.
- kraM: the artifact is the subject and the hardware run is the validation;
  no LOC.
- harness: never finished autonomous delivery.
- No hand-authored code volume.

## Map the resume onto the page schema

`content/pages/background.yml` uses the page schema in
`docs/system/site-pages.md`. A sketch, not the cut itself:

```yaml
sections:
  - heading: Experience
    groups:
      - title: "2020 – 2025 · Nikola Motor"   # a role's dates, or "Military" for the Navy
        rows:
          - k: Testing                       # the area
            v: "The resume's bullet, as written or shortened, never reworded into a new claim."
```

- One group per role or role cluster. Earlier roles share one group.
- One row per area. Keep the strongest bullet for that area. The page has
  room for about one row per area, not every bullet.
- Skills: one row per tier, as the resume tiers them.
- Projects belong in `content/work.yml`, not on Background.

## Check it

```bash
bin/rails content:schema                         # the file loads
bin/test test/integration/other_pages_test.rb    # copy reads back
bin/rails test:system TEST=test/system/other_pages_test.rb  # still one printed page
bin/rails content:placeholders                   # what is still in brackets
```

If the print test reports two pages, cut rows. Don't shrink type or spacing.
The page is a one-page CV by design (`docs/system/site-pages.md`, *Print*).

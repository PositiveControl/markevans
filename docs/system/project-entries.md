# Project entries

**Status:** Current for findings (#43) and the kind filter (#44). The
project's own delivery thread (#45) and findings pinned to its steps (#46) are
added here as they land.

How a `/work/:id` page is assembled beyond its summary and sections. Design:
`docs/plans/2026-10-09-work-entries-design.md`. The page's route, its other
keys and its components are in `docs/system/site-pages.md`.

## Findings

What the project taught, set apart from the narrative so a reader scanning for
judgement finds it. Each project in `content/work.yml` may carry a `findings:`
list. A project without one shows no Findings section.

```yaml
findings:
  - kind: surprise          # learning | surprise | takeaway
    title: "One line"
    body: "A paragraph, in Mark's voice"
    evidence:               # optional
      label: "PR #142"
      url: https://github.com/…
```

`Portfolio` (`app/lib/portfolio.rb`) reads each into a `Portfolio::Finding`,
with `evidence` as a `SitePage::Link` or `nil`. It reports, with the file's
other errors, a kind not in `Portfolio::KINDS`, a missing title or body or one
that is not text (an unquoted `[placeholder]` reads as a list), an
unknown key, and evidence that fails the link rules
(`SitePage.one_link_errors`: `https://` or `mailto:`, or a `[placeholder]`).
`step` is an unknown key until #46 pins a finding to a thread.

### On the page

The findings follow the project's first section, *The project*, and come
before the rest. The view places them by position, never by matching the
heading's text. `FindingsComponent` draws a section under a mono `h2`
"Findings" (a structural label), and a `ul` named by that heading. Each
finding is an `li`:

- `id="finding-<n>"`, counted from 1 in file order, `data-kind`, and
  `data-filter-target="row"`
- its kind as a mono word (`kind`, capitalised) beside its mark
- its title, a serif `h3`, and its body, serif
- its evidence in mono, linked by its label, or shown as label and url in
  quiet text while the url is still a placeholder

### The kind filter

Between the heading and the list, a row of toggles narrows the findings by
kind: All, Learnings, Surprises, Takeaways. The words come from
`Portfolio::KINDS`, pluralised (`FindingsComponent::KIND_LABELS`), not from
template copy. It is the home page's filter, not a second one
(`docs/system/home-thread-playback.md`, *The filter*): the section carries
`data-controller="filter"` keyed on `kind`, and the toggles are a
`FilterComponent` labelled Kind, `aria-pressed` buttons each carrying
`data-kind`.

Picking a kind marks `data-dim` on every finding of another kind. A dimmed
finding's text, its mark included, drops to `text-quiet`; it is never hidden
and keeps its place in the reading order. Its text never fades by opacity,
which would fail axe's contrast check.

Without scripts the toggles stay `hidden` and no finding carries `data-dim`, so
the section reads as a document, every finding at full strength.

### Kinds

A kind is a shape and a word, in ink, never a color. Command teal, human amber
and machine green already have meanings (`docs/rules/color-means-role.md`,
`docs/rules/never-color-alone.md`). `FindingMarkComponent` draws the shape in
an 18 px slot, `aria-hidden`, since the word beside it is what a screen reader
hears.

| Kind | Mark |
|---|---|
| `learning` | Open circle |
| `surprise` | A bar over a dot, an exclamation mark |
| `takeaway` | An arrow, pointing right |

None of them can be taken for the chart's triangles (open, solid, dashed) or
the scope's square and rotated square in greyscale. That was the rule they
were picked by (design doc, *Settled at G1*, item 4). A fourth kind needs a
mark here before `Portfolio::KINDS` accepts it: `FindingMarkComponent` raises
on a kind it cannot draw.

### Content

Findings come from the project's real history, not from the resume, so every
project ships one `[bracketed]` finding of each kind until Mark writes them.
The placeholder gate holds a production build until then
(`docs/rules/no-invented-content.md`).

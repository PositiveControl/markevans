# Home page — the personal site

`GET /` renders a single-page portfolio for Mark Evans. There is no second page,
no CMS, and no database read: the whole page is server-rendered from a registry.

## Where the content lives

`app/lib/portfolio.rb` — a registry of `Data` objects (`Profile`, `Metric`,
`Role`, `Project`, `SkillGroup`), following [registries](../rules/registries.md).
Copy is code here because it changes with a deploy, nobody outside the repo edits
it, and a typo should raise at the call site rather than render blank.

Lookups are `fetch`-based (`Portfolio.project(:harness)` raises `KeyError` on an
unknown key). Collections come back as arrays: `metrics`, `roles`, `projects`,
`skill_groups`. `Portfolio.years_shipping` derives the experience figure from
`Profile#started` so the hero cannot quietly go stale.

Source of the copy: the résumé and profile notes in the private `new-job` repo.
Rules carried over from there and enforced by `test/lib/portfolio_test.rb`:

- Attribution is exact. The card-recognition pipeline entry says *built the
  proof-of-concept … and maintain* — never "built the pipeline".
- Repos that are not presentable are not linked. `spamsandwich`, `myrelay`, and
  `rails-rocket-sheep` link their live site or nothing at all.
- **No em dashes and no ` · ` separators anywhere in registry copy.** Both are
  tells of generated prose; two tests fail if one comes back. Use a period, a
  colon, or a comma.

## Structure

`app/views/home/index.html.slim` sets the title, meta description, and `Person`
JSON-LD (via `jsonld_tag`), wraps the nav and the palette in one Stimulus
controller element, then renders section partials in order:

| Partial | Section id | Content |
|---|---|---|
| `_nav` | — | Fixed header, anchor links, palette trigger |
| `_palette` | — | Command palette dialog (hidden until opened) |
| `_hero` | `#top` | Name, tagline, summary, links, metadata block |
| `_metrics` | `#impact` | Four headline numbers as an aligned table |
| `_work` | `#work` | Numbered role list |
| `_projects` | `#projects` | Six projects in a hairline grid |
| `_skills` | `#skills` | Skill groups |
| `_contact` | `#contact` | Contact rows plus footer |
| `_section_heading` | — | Shared `LABEL ──── n entries` header |

Every partial takes strict locals; none reads an instance variable.

## Design

The page is a systems console, not a landing page: neutral black ground, one
accent, monospace for every label and number, a text face for prose only, square
corners, hairline rules. It replaced an aurora/spotlight/gradient-headline
treatment that read as generic AI-generated chrome.

Rules that keep it that way:

- **One accent for the whole page.** `--color-amber` marks section labels, metric
  values, the current role title, focus rings, and link hovers. Nothing else is
  coloured, and accents never rotate per section.
- **Neutral black, never `slate-*`.** Slate carries a blue cast. The ramp is
  `--color-ink` / `--color-raised` / `--color-rule` / `--color-rule-soft`, with
  text at `--color-fg` / `--color-mid` / `--color-dim`. Every text step clears
  4.5:1 on the ground; `--color-dim` is the floor at 5.4:1.
- **Monospace carries the identity.** IBM Plex Mono for labels, numbers, periods,
  stack lists, and headings. IBM Plex Sans for running prose only.
- **No shell costume.** Monospace metadata and hairline rules, not `$` prompts on
  every section.
- **Structural variety by content type.** Metrics are a table, work is a numbered
  list, projects are a grid. Three shapes, not three sets of the same card.

### Fonts

Five latin-subset woff2 files in `app/assets/fonts/`, ~67KB total. Propshaft picks
that directory up as a load path automatically (Rails globs `app/assets/*`), so
the bare `url("plex-mono-400.woff2")` in the Tailwind source resolves to a
digested path via `Propshaft::Compiler::CssAssetUrls`. The three faces above the
fold are preloaded from the layout.

Nothing is fetched from Google. `test/integration/home_page_test.rb` fails if
`fonts.googleapis.com` or `fonts.gstatic.com` appears in the response.

**A new server process is required after adding a font.** Propshaft computes its
load path at boot, so a dev server started before `app/assets/fonts/` existed
raises `Propshaft::MissingAssetError` until it is restarted.

## Motion

Two Stimulus controllers and one stylesheet:

- `reveal_controller.js` — an `IntersectionObserver` that adds `reveal-in` to its
  `item` targets as they scroll in, then unobserves them. Per-item stagger comes
  from an inline `--reveal-delay` custom property, not from JS.
- `palette_controller.js` — the command palette, below.
- `app/assets/tailwind/application.css` — `@font-face`, the `@theme` tokens, the
  `.reveal` / `.reveal-in` pair, and `.caret`.

Three things about that CSS are load-bearing:

1. **`.reveal` is gated on `.js`**, a class the layout sets from an inline script
   before first paint. Without JavaScript nothing hides itself, so a reader or
   crawler whose script never ran still sees the whole page. Remove the gate and
   a JS failure blanks everything below the nav.
2. **The reveal is short and nearly straight** — 380ms over 0.5rem. The long
   swooping travel it replaced is itself a generated-page tell.
3. **`prefers-reduced-motion: reduce` disables all of it** — reveals resolve
   instantly and the caret stops blinking.

## Command palette

`_palette.html.slim` plus `palette_controller.js`. ⌘K / Ctrl+K toggles it, `/`
opens it when the caret is not already in a field, `Esc` closes and returns focus
to whatever had it. Arrow keys move the highlight, `Enter` activates the row.

- Every row is server-rendered as a real `<a>` (or a `<button>` for "copy email
  address"). The controller only filters and highlights.
- Rows hide with the `hidden` **attribute**, not a utility class: Tailwind's
  preflight declares `[hidden] { display: none !important }`, so it beats the
  row's display utility and no class string has to live in JavaScript.
- The highlight class comes from `data-palette-active-class` on the wrapper, per
  [stimulus](../rules/stimulus.md). The panel sits on `--color-ink` precisely so
  the active row's `bg-raised` is the lighter surface.
- The shortcut is heard through `keydown@window->palette#hotkey`, which is how a
  global hotkey stays inside the controller's own element.
- The dialog ships `hidden`, so a reader without JavaScript never meets a modal
  they cannot close. A test asserts that.

## Theme

The page commits to a single dark treatment rather than supporting both schemes.
That is the one deliberate departure from [tailwind](../rules/tailwind.md)'s
"every surface needs its dark counterpart" rule: there is no light surface to
pair. The layout sets the ground on `body`, so any future page inherits it.

## Tests

- `test/lib/portfolio_test.rb` — registry shape, link hygiene, `fetch` behaviour,
  derived `years_shipping`, and the em-dash / middot copy guards.
- `test/integration/home_page_test.rb` — every metric, project, and role renders;
  project links, contact links, `Person` JSON-LD, landmark `aria-labelledby`, the
  palette's rows and hidden-by-default dialog, self-hosted font preloads, an
  assertion that the personal phone number never reaches the page, and a guard
  that the retired `aurora` / `spotlight` / `gradient-text` / `marquee` /
  `dot-grid` names have not come back.

# Static thread export — design

**Status:** Implemented in #39 (G1 2026-10-07; revised at G2)

## Problem

The home page (`GET /`) is the clearest explanation of the delivery workflow
we have: one feature moving through the chain from `/pick` to merge, played on
the scope one step at a time. Mark wants to show it to his boss and team, who
will not run a Rails app, a Postgres, or `bin/dev` to see it.

What they need is one HTML file that opens from disk (`file://`), an email
attachment, a shared drive or any static host, and shows everything the root
page shows (headline, intro, scope, legend, the fifteen strips with their
bodies and chart cells, and the footer).

**Revised at G2 (2026-10-07):** no playback and no filter. The file will be
stepped through by hand in a meeting on a shared screen, so it is the page's
no-script reading (design doc `2026-10-03-home-thread-design.md`, section 6):
every strip open, in order, and each scope target a plain link to its
`#step`. The presenter scrolls or clicks a target. The parts that exist only
for playback (controls, strip bay, controller filter, log, docked bar, the
footer's key list) are hidden without scripts already, and the export drops
them.

**Revised at review (2026-10-07):** the file is the thread and nothing else.
The site header and footer, the intro and the scope go, and the headline's
place and the tab carry the title "uCollect Dev Workflow". Every strip starts collapsed
and opens or closes on a click, the git graph folding with its row, by one
inline script that writes `data-open` and `aria-expanded` as playback does.
Without scripts the file stays the no-script reading, every strip open. The
sections below are the design as approved; where they say "no script", "the
site name stays" or "each scope target links to its step", this note wins.

## Constraints

- **Not a second copy of the page.** The page is built from
  `content/threads/home.yml` through a dozen components
  (`docs/system/home-page.md`). A hand-ported HTML file would drift on the
  first content edit. The export must be *produced from* the real page, so
  it shows whatever the page shows at the moment it is run.
- **One file, no network.** Everything inline: the compiled stylesheet, the
  four fonts (about 103 kB, `docs/system/home-page.md`, *Budget*). No
  scripts at all. No request to any host, this one included. The
  page's own no-third-party rule already holds today, so nothing needs to be
  swapped for a local copy.
- **No database, at run time or export time.** The file obviously needs
  none. The export should not either. The home page reads a YAML file and
  queries nothing, so the export can run on a machine (or a CI job) with no
  Postgres. To be confirmed in `/task_plan`.
- **No scripts.** The page is built to read as a document without them, and
  that reading is what a presenter steps through. Shipping playback would only
  add a clock that runs on its own and a filter nobody asked for.
- **The page is untouched.** No change to the root page's views, components or
  controllers to make the export work. If one is needed, it is a finding to
  raise, not to slip in.
- **Pattern budget.** No new directory under `app/` (`docs/rules/pattern-budget.md`).
  The export is a build tool, not app code: a rake task in `lib/tasks/` and a
  `bin/` wrapper.

## Approach

A command, `bin/export-thread` (wrapping `bin/rails thread:export`), renders
the root page *through the app* and folds everything it references into the
HTML:

1. **Render.** Boot the app in its current environment and request `/` in
   process (`Rack::MockRequest` against `Rails.application`, or an
   `ActionDispatch::Integration::Session`), so the HTML is the page exactly as
   served: layout, components and the content file.
2. **Build the CSS.** Run the Tailwind build (`tailwindcss:build`) so the
   stylesheet matches the views, then read the compiled `app.css`.
3. **Inline the fonts.** Rewrite each font `url()` in that stylesheet to a
   `data:font/woff2;base64,…` URI, and drop the `<link rel="preload">` tags.
4. **Drop the scripts.** Remove every `script` (the JSON-LD and the importmap
   included) and every `link`, and the elements that only playback reveals
   (`data-playback-target="live"`, `data-filter-target="live"`), along with the
   `data-controller`/`data-action` wiring nothing will read.
5. **Strip what makes no sense off the server.** The CSRF and CSP meta tags,
   the canonical link, the icon links (or inline the SVG icon), and the
   header's links to the site's other pages (see Open questions).
6. **Write and check.** Write `dist/<name>.html` and fail the command if
   the result still names any URL other than a `data:` URI or an in-page
   `#hash`.

Output goes to `dist/`, which is gitignored: the file is regenerated whenever it
is shared, so it never lags the content.

**Tests** (`test/lib/thread_export_test.rb`, `test/tasks/thread_tasks_test.rb`):
the export runs; the file holds the headline, the intro and every step's name
and body from `home.yml`; it references no external URL; it carries no
script. No system test: the no-script page is already
walked under axe by `test/system/home_playback_test.rb`.

**Review:** no QA walkthrough script. The file is served over Tailscale
(`docs/sop/serve-dev-over-tailscale.md`) for the developer to review by hand.

## Rejected alternatives

- **Hand-written static page** (copy the HTML once, maintain it by hand).
  Fastest to produce, but it is a second copy of fifteen steps of content and
  of the components' markup. It drifts on the first edit to `home.yml`, and
  nothing would notice. The export costs about the same once and never drifts.
- **Committing the exported file.** Same drift problem with extra steps: it is
  stale the moment content changes unless a gate regenerates it, and GitHub
  does not render HTML anyway, so a committed copy is not easier to share.
- **Saving the page from a browser ("Save as… complete").** Produces a folder,
  not one file, keeps Turbo and the importmap pointing at `/assets/…`, and
  is a manual step nobody can reproduce exactly.
- **Keeping playback (scripts inlined as `data:` importmap entries).** The
  first G1 proposal. Dropped at G2: the meeting steps through by hand, and an
  auto-playing clock fights a presenter.
- **Static site generator / a second "export" layout in the app.** More moving
  parts than the post-processing above, and it would put export concerns into
  the app's views.

## Open questions

1. **The header's nav links** (Work, Workflow, Background, Contact) would be
   dead links in a standalone file. *Proposed:* keep the site name, drop the
   four links. Alternative: point them at the live site's URLs, if there is
   one to point at.
2. **File name.** *Proposed:* `dist/delivery-thread.html`.
3. **Placeholder content.** `home.yml` still carries `title: "[example TBD]"`.
   `content:check` fails a production build on `[placeholder]`s. *Proposed:*
   the export warns about placeholders but still writes the file, since this is
   a demo, not a deploy.
4. **Does the in-process render need a database connection?** Settled in
   `/task_plan` by running it with `DATABASE_URL` unset; if something on the
   page touches the DB, that is the finding.

## Decomposition

One slice. It fits one PR, so it lands straight on `main`, with no feature branch.

| Slice | What | Forecast |
|---|---|---|
| 1. Export the thread to one HTML file | Rake task + `bin/export-thread`, `dist/` gitignored, test of the file's content and self-containment, docs | ~250–400 added lines, ~9 files |

Acceptance criteria (for the issue):

- `bin/export-thread` writes one HTML file with no database running
- The file contains every word the root page shows from `home.yml`
- The file references no URL other than `data:` URIs and in-page hashes, and carries no script; the command fails otherwise
- Each scope target links to its step's `#key`, every strip is open, and nothing that only playback reveals (controls, bay, filter, log, docked bar, key list) is in the file
- `docs/sop/export-the-thread.md` says how to produce and share it

## Docs impact

- **New** `docs/sop/export-the-thread.md`: how to produce the file, where it
  lands, what to send, what is left out (header links, playback and filter).
- **Update** `docs/system/home-page.md`: one line under *Budget* or a new
  *Export* note saying the page is also exported, so a change that breaks
  inlining (a new font, a new controller, a new external reference) is known
  to have a second consumer.
- **Update** `.llm/README.md`: the plan and the SOP.

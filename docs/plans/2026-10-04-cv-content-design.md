# CV content — design

Status: Approved (G1, 2026-10-04)
Date: 2026-10-04
Slug: cv-content
Issue: #38

Fill the site's placeholder copy from Mark's master resume. The resume is the
source; the site is one *cut* of it (select and reorder, never invent).

## Problem

`/background`, `/contact`, `/work` and the six project pages ship with every
line in `[brackets]` (`docs/plans/2026-10-03-home-thread-design.md`, section 1:
"Background content (CV) … what spamsandwich is" were left open). The
placeholder gate fails a production build on them, so the site cannot ship.
Mark now has a master resume that answers most of them. The readers are the
ones the home-thread design names: hiring managers first, engineers on the
hiring team second.

## Constraints

- **The resume is a superset, not a page.** Every site page is a cut of it.
  Nothing is added that the resume does not say (`docs/rules/no-invented-content.md`).
  Anything the resume does not answer stays in brackets.
- **The resume's italic asides and `[[NEEDS: …]]` markers never reach the
  page.** They are instructions to the cutter: interview-only context (the
  part-time architect, harness's scope note), attribution rules, lane notes,
  framing rules. The cut obeys them:
  - The card-recognition layer is "contributed to and maintain", never
    "built". The GPU host, slab flow, fields/matching overhaul and merge
    contract are his.
  - Stripe Connect is a system he works inside, not one he built.
  - SyberJet avionics is a proof-of-concept, never a shipped aircraft.
  - kraM: the built artifact is the subject, hardware runs are the
    validation, the equivalence checker stays; no LOC, nothing implying months.
  - harness: no claim of finished autonomous end-to-end delivery.
  - No hand-authored code volume anywhere.
  - Spam Sandwich links the site, never the repo.
  - `myrelay.to` is never linked.
  - Datadog, Java and Elixir stay off the skills.
  - The M.S. carries credits and GPA and no status word.
- **`/background` prints to one page.** `test/system/other_pages_test.rb`
  counts the PDF's pages (`docs/system/site-pages.md`, *Print*). The master
  resume runs to four or five pages, so the page has to be a real cut.
- **The schema stays as it is.** `content/pages/<key>.yml` has `title`,
  `description`, `intro`, `links`, and `sections` of `paragraphs` and `groups`
  (`title`, `rows` of `k`/`v`). A resume bullet maps to a row: `k` is the
  area ("Payments", "Security"), `v` is the bullet as written.
- **Copy only.** Site name, nav and structural labels are not content and do not change.

## Approach

One content pass over four files, plus the tests that pinned placeholder
content.

**`content/pages/background.yml`, the one-page cut.**
- **intro:** summary variant A, as written (Settled, 1).
- **links:** GitHub, LinkedIn, email. No phone.
- **Experience:** one group per role, titled with its dates.
  - *Software Engineer, ISSO / Alpine Landing, 2025 – present:* rows by area.
    Leadership, AI/ML, production (the 20–25× card-labeler metric leads),
    payments, security, fulfillment, real-time and SyberJet each get one
    sentence, cut from the resume's strongest bullet in that area.
  - *Nikola Motor, 2020 – 2025:* one group, the four titles as rows with
    their years, or the promotions condensed to one line. Rows carry 40→90%
    coverage, OTA orchestration, pen-test remediation, and 7.8M req/day /
    2.4B rows/day.
  - *Earlier roles:* one group, a row per role (Golden Mean, Red Cross,
    TeamSnap, SmallBIT marked concurrent).
  - *Military:* the Navy row, undated (Settled, 3).
- **Skills:** one group with a row per tier: Primary, Strong, AI/ML,
  Security, Practices. Each tier is cut to what fits.
- **Education:** the four rows as written. The M.S. carries no status word.
- **Projects:** not on this page; `/work` carries them. The page's links
  point there.
- **description:** a cut of the summary, at 155 characters or fewer.

The web page and the print show the same content. If the cut that fits one
printed page reads thin on screen, the fix is the Work pages, not a second
copy.

**`content/pages/contact.yml`:** the email (as `mailto:`), LinkedIn and
GitHub. The intro ("what you are open to") is not in the resume, so it stays
a placeholder unless Mark supplies it.

**`content/work.yml`:** each project's summary, links and *At a glance* rows
(Stack, Status) come from the resume's Projects section. *The project*
paragraphs are cut from its bullets. *How it was built* ("how it moved
through the delivery chain") is not in the resume, so it stays a placeholder.
So does Role, unless Mark confirms a word for it.

**`content/pages/work.yml`:** the intro is cut from the resume's projects
positioning: LLM-assisted by deliberate practice, with claims about design,
architecture, testing and shipping, never volume (Settled, 7).

**Tests.**
- `other_pages_test.rb` "copy not yet written shows as its [placeholder]"
  reads `dopeempire` from the real content. That project is renamed and
  filled, so the test moves to a test-only content file, the way the loader
  tests already do.
- `seo_test.rb` pins `sameAs` to GitHub alone. It is updated to read the
  page's `https` links.
- The one-page print test is the acceptance check for the Background cut.

## Rejected alternatives

- **Print a short cut, show the full resume on screen** (a `print: false`
  flag on sections or groups). It changes the schema, the loader and
  `PageSectionsComponent` for one page. The site would also carry two
  versions of the resume, and the long one is the master Mark explicitly
  says is not for submission. If the one-page cut proves too thin, revisit.
- **Copy the master resume into `content/` whole.** It would leak interview
  notes and break the print, and the resume's own header forbids it.
- **A separate `content/cv.yml` with its own schema** (roles, bullets,
  skills). It would need a new loader, a new component and new tests for
  content that `sections`/`groups` already express. Rejected under the
  pattern budget.
- **Fill the home thread's brackets from the resume.** Those are about the
  example feature and gate notes, not the career. The resume doesn't answer
  them. Out of scope.

## Settled questions

Answered by Mark, 2026-10-04.

1. **Summary variant:** A (product/platform lead), as written, for now. A
   site variant that ties to the positive-control headline is his to write
   later.
2. **dopeempire is IDLEmpire.** The project's key becomes `idlempire`, its
   name `IDLEmpire` (Mark's capitalisation) and its link
   `https://idlempire.com`. The content comes from the resume's Idlempire
   entry.
3. **Header lines:** keep Phoenix, AZ. Keep the Navy, **with no dates**: its
   group is titled "Military", not years, and the row is "Air Traffic
   Controller, AC2 (AW), United States Navy". Leave the clearance off.
4. **Email:** `mailto:msteven.evans@gmail.com`, on Background and Contact.
5. **rails-rocket-sheep:** keep the repository link.
6. **Skills tiers:** as written.
7. **Work intro:** cut from the resume's projects positioning note.

Deferred, still in brackets after this feature: the Contact intro, each
project's *How it was built* and Role, Workflow page copy, and the home
thread's example feature.

## Decomposition

One slice. About 500–700 added lines over roughly eight files, all content,
tests and docs, so it fits one PR straight to `main`. There is no feature
branch.

| Slice | Contents | Forecast |
|---|---|---|
| 1 | Background, Contact, Work list and project pages from the resume; placeholder test moved to test content; `sameAs` test; docs | ~600 lines, ~8 files |

The `dopeempire` → `idlempire` rename rides in this slice. The sitemap and
`/work` follow the file, so no route changes. The old `/work/dopeempire` URL
404s; the site has not launched, so no redirect.

## Docs impact

- `docs/system/site-pages.md`: the *Print* paragraph ("Once the CV is
  written…") becomes current. Note that Background is a cut of the master
  resume, and list which brackets remain.
- `docs/plans/2026-10-03-home-thread-design.md`: in section 1's "Still
  open" list, mark Background and spamsandwich as answered by this doc. In
  section 2, rename dopeempire to IDLEmpire.
- A new SOP, `docs/sop/update-the-cv.md`: how to re-cut Background when the
  master resume changes. It covers what never comes across, how a bullet
  maps to a row, and checking the one-page print. Placeholder created at
  issue time.

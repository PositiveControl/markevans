# Markevans

Rails 8 application built with the Solid Stack architecture.

Generated from [Rails Rocket Sheep](https://github.com/PositiveControl/rails-rocket-sheep)
at commit `7e47077` on 2026-10-03. Everything below,
including `docs/rules/` and `.claude/commands/`, is a snapshot from that commit and
is now this app's own code. Nothing is fetched behind your back, so when a
convention here disagrees with a newer version of it, this app's copy is what
governs this app. To take template changes deliberately, three-way merge them —
`bin/rocket-sheep-update --check`, then
[docs/sop/update-from-the-template.md](docs/sop/update-from-the-template.md).
Leave the commit on the line above intact: it is where the merge starts from.

## Quick Start

```bash
bin/dev              # Start development server with Tailwind watcher
bin/test             # Run tests (single worker on macOS)
bin/rails console    # Rails console
bin/rails db:migrate # Run migrations
bin/rails db:queries # Record the SQL shapes the suite emits; review the new ones
bin/rubocop          # Run linter
bin/brakeman         # Security analysis
bin/flay             # Copied Ruby this branch adds vs origin/main (BASE= for a slice)
```

## Tech Stack

- **Backend:** Rails 8 + PostgreSQL (`postgresql`), uuid primary keys
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS, Slim (not ERB)
- **Components:** ViewComponent (`app/components`, `ApplicationComponent`)
- **Pagination:** Pagy (wired into `ApplicationController`)
- **Solid Stack:** Solid Queue, Solid Cache, Solid Cable — all database-backed, no Redis
- **Auth:** Devise + Petergate
- **Deployment:** Kamal 2 with Docker
- **Quality:** RuboCop (Rails Omakase), Brakeman, Bullet, Slowpoke

## Finding the rule that applies

**Conventions are one rule per file in `docs/rules/`. Do not read them all.**

Start at [`docs/rules/INDEX.md`](docs/rules/INDEX.md). It routes by the file you are
editing: a small set that applies to any edit in that path, then conditional tables
for what you are actually doing. Read what it names and stop.

If it did not answer you — you know the symptom but not the file — the fallback is
[`docs/rules/SYMPTOMS.md`](docs/rules/SYMPTOMS.md), which carries the symptom table
and the full annotated list. It costs about twice the index, so it is second, not
first. `grep -l "<keyword>" docs/rules/*.md` finds a rule by its `triggers` without
loading anything, and a rule id is always `docs/rules/<id>.md`.

Both routers carry read costs, so budget from them rather than guessing. Reading the
whole directory is a mistake, not diligence.

## Non-negotiables

The short list. Each one has a rule file with the reasoning, the worked example,
and the "when not to" — follow the link before you argue with the rule.

- **Tests first.** `bin/test` passes before you claim anything works. `bin/rubocop`
  and `bin/brakeman` clean. Fix flaky tests immediately, even when unrelated to
  your change. Minitest and fixtures, no factories → `docs/rules/testing.md`
- **Form failures render with `status: :unprocessable_content`.** Without it Turbo
  discards the response and the form silently freezes → `docs/rules/turbo-status.md`
- **Controllers stay RESTful** — seven actions, a new verb gets a new controller,
  actions under ~10 lines → `docs/rules/controllers.md`
- **Every index paginates** → `docs/rules/pagination.md`
- **Scope every lookup** (`current_user.orders.find(...)`) and let the miss raise
  → `docs/rules/exception-boundary.md`
- **Business logic goes in `ApplicationService`**, not controllers, not callbacks.
  Transactions live there → `docs/rules/service-objects.md`
- **Multi-model forms use `ApplicationForm`.** Never `accepts_nested_attributes_for`
  → `docs/rules/form-objects.md`
- **Scopes, never class methods** returning relations → `docs/rules/scopes.md`
- **Callbacks touch only their own record** → `docs/rules/callbacks.md`
- **Slim only, never ERB.** Tailwind bracket classes need the `class=""` form
  → `docs/rules/slim-gotchas.md`
- **Deletes are real by default.** Discard is opt-in per table → `docs/rules/deletes.md`
- **Six sanctioned directories under `app/`** — `services`, `forms`, `queries`,
  `policies`, `lib`, `components`. A seventh needs an ADR → `docs/rules/pattern-budget.md`
- **Update `docs/` when behaviour changes**, and `grep` for an existing doc first.

## Development workflow

- **Planning:** non-trivial features get a design doc in `docs/plans/` before code
- **Collaborative:** explain findings and reasoning; stop often for feedback
- **TDD:** write tests before code; commit in functional chunks when green. Stop
  when tests fail to present context and discuss next steps
- **Commits:** small, focused, clear messages
- **Slow tests:** Slowpoke flags anything over 500ms after each run. Fix the cause
  or state why it's inherent — don't let the report become noise
  (`docs/sop/find-slow-tests.md`)

Command-driven lifecycle. Full spec and diagrams in `WORKFLOW.md`.

```
/pick (entry, routes by state) → /feature_plan → /task_plan → /implement → /pr_submit → human merge → automation
```

- `/pick` is the entry door for every session — it surfaces ready work and routes it
- Four gates: design approved (G1), plan approved (G2), suite green (G3), comments resolved (G4)
- Sizing: 200–1,500 added lines and ≤25 files per PR; issue acceptance criteria ≤5
  bullets. Forecast passes 1,500 lines mid-implementation → stop, split, land the
  current slice
- Multi-slice features land on `feature/<slug>`. A slice is reviewed by `/pr_review`
  run from a fresh session, two passes at most, and merged there on that review;
  the feature PR gets the human review. Spec: `WORKFLOW.md`, *Feature branches*;
  why: `docs/adr/0014-slices-merge-on-the-agents-review-features-on-a-humans.md`
- `/segue` is the escape valve — isolate a tangent, merge findings back without
  polluting the workstream
- You invoke the chain. Ten of the twenty-five (`/run_lint`, `/test_fix`,
  `/rails_code_review`, `/qa_walkthrough`, `/diagnose`, `/resolve_conflicts`,
  `/grill`, `/research`, `/domain_model`, `/pr_fix_ci`) read and edit locally, so
  an agent may reach for them when the situation fits; anything that posts, pushes, moves the board,
  or sits at a gate is yours to type. `WORKFLOW.md` has the table and the reason
  per command. No command invokes another one: "next: `/pr_submit`" is an
  instruction to you

Run `/workflow_setup` once before first use — it fills in GitHub org, repo, and board IDs.

## Testing

```bash
bin/test                              # All tests
bin/test test/models/                 # Directory
bin/test test/models/user_test.rb:42  # Specific line
```

System tests are separate: `bin/rails test:system`.

Every branch with a user-facing change ships a reviewer walkthrough (`script/qa/`,
`bin/qa-walkthrough`; `docs/system/qa_walkthrough.md`) unless the developer skips it —
`/task_plan` plans the steps, `/pr_submit` gates on them.

How to write one — layering, fixtures, VCR, assertions — is `docs/rules/testing.md`.

Slowpoke reports any test over 500ms and prints nothing when the suite is clean.
Tuning it, and reading the report, is `docs/sop/find-slow-tests.md`; project
defaults are in `test/support/slowpoke.rb`.

`binding.pry` drops into a debugger anywhere.

## SEO

robots.txt, dynamic `/sitemap.xml`, meta description and canonical URL with
per-page `content_for` overrides, `StructuredDataHelper#jsonld_tag` for JSON-LD,
integration tests in `test/integration/seo_test.rb`, and a weekly Lighthouse CI
workflow. Adding a page: `docs/sop/add-seo-to-a-page.md`.

## Deployment

Kamal 2, to `markevans.io` on the server dopeempire also uses. Fill
`.kamal/secrets` from `.kamal/secrets.example`, then `kamal setup` and
`kamal deploy`. `.kamal/secrets` must define every secret `deploy.yml`
declares, or Kamal stops: `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`,
`DATABASE_URL`, `QUEUE_`/`CABLE_`/`CACHE_DATABASE_URL`, and
`POSTGRES_PASSWORD` (table in `README.md`). The four databases share one
Postgres container but must stay separate databases. Server hardening:
`docs/sop/harden-a-kamal-server.md`.

## Documentation

Docs follow a canon. The workflow commands in `.claude/commands/` read and write
these exact paths — don't rename them.

| Directory | Holds | Written by |
|-----------|-------|------------|
| `docs/rules/` | One convention per file + `INDEX.md` router and `SYMPTOMS.md` fallback | Hand-maintained; see the index's own rules |
| `docs/plans/` | Design docs for features | `/feature_plan` |
| `docs/adr/` | One decision per file, numbered — why a rule exists | `/domain_model` |
| `docs/system/` | Architecture state — how things currently work | `/pr_submit`, `/update_docs` |
| `docs/sop/` | Procedures someone will repeat | `/pr_submit`, `/update_docs` |
| `docs/qa/` | Manual test guides | `/pr_qa` |

`docs/adr/` holds one decision per file, numbered (`0001-<slug>.md`): *why* a rule
exists and what was accepted for it. `docs/system/` holds `models.md` and
`vocabulary.md`. Rules say what to do; ADRs say why it was chosen. Don't merge
them.

`vocabulary.md` defines the words this workflow uses in one place — thread ID,
tracker tier, gate, contract slot, doc canon, pattern budget — with the wording to
avoid where a term has a common near-synonym. Reach for it when a word in
`WORKFLOW.md` or a command reads like jargon; don't restate a definition anywhere
else.

`.llm/README.md` indexes committed docs. Conventions are single-sourced in
`docs/rules/`; task files in `.llm/tasks/` reference them and never restate them.

Two of those properties are checked rather than trusted:

```bash
bin/doc-tokens     # rewrites each rule's `tokens:` figure and the figures derived from it
bin/lint-docs      # rule frontmatter, index routing, read costs, path resolution, quoted counts
```

Run both after editing anything under `docs/rules/` or `.claude/commands/`, or any
doc that quotes a count — `/update_docs` ends on them. A doc that disagrees with the
tree is worse than no doc, because the agent reading it cannot tell.

## Project Structure

```
app/
├── lib/                    # Registries and config modules
├── models/                 # ActiveRecord models
├── services/               # Service objects (inherit ApplicationService)
├── forms/                  # Form objects (inherit ApplicationForm)
├── components/             # ViewComponents (inherit ApplicationComponent)
├── controllers/            # RESTful controllers
├── jobs/                   # Background jobs (Solid Queue)
├── helpers/                # View helpers
├── views/                  # Slim templates
└── javascript/controllers/ # Stimulus controllers

# Created on first use, not shipped empty:
#   app/queries/   Query objects — reads joining ≥2 models
#   app/policies/  Record-level authorization

docs/                       # names are load-bearing
├── rules/                  # One convention per file
│   ├── INDEX.md            #   Router — start here
│   └── SYMPTOMS.md         #   Fallback — by symptom, and the full list
├── plans/                  # Design docs (/feature_plan)
├── adr/                    # One decision per file, numbered
├── system/                 # Architecture state
│   └── models.md           #   Model documentation
├── sop/                    # Procedures / how-tos
└── qa/                     # Manual test guides

.claude/commands/           # 25 workflow slash commands (tracked, shared)
.llm/
├── tasks/                  # Task files — local scratch, gitignored
└── threads/                # Segue threads — local scratch, gitignored
WORKFLOW.md                 # Lifecycle spec + diagrams
```

## Workflow

Chain, sizing and gates are under *Development workflow* above; the doc canon is
under *Documentation*. Conventions live in `docs/rules/`, one per file, and are
referenced, never restated. This repo's settings (full record in
`.claude/workflow.config.md`):

- **Tracker:** `labels` — GitHub Issues with `status:todo`, `status:in-progress`,
  `status:up-for-review`, `status:blocked`, `status:done`. No board; PR bodies
  carry `Closes #<issue>`
- **Branches:** `me/<issue>/<slug>` · **PR titles:** `ME | <issue> | <title>` ·
  **Review label:** `ready for review`
- **CI:** `/pr_submit` polls `scan_ruby`, `scan_js`, `lint`, `gates`; `test` ran
  locally and is not polled

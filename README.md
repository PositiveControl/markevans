# Markevans

The personal site of Mark Evans, Senior Software Engineer.

## Purpose

The site's pitch: web products built with coding agents under *positive
control* (an air traffic term: nothing moves without clearance), so every
change is planned, gated, reviewed, and shipped the same way. The home page
demonstrates it rather than describing it.

`GET /` is the **home thread**: one feature moving through the delivery chain,
told as fifteen flight strips, one per step, each above an explanation of what
the step does and a row of the git graph beside it. Without JavaScript it reads
as a document. With it, the page plays the thread step by step, with controls
that dock at the top, a per-controller filter, a log of what each step
produced, and keyboard shortcuts.

Beside it:

| Route | Shows |
|---|---|
| `/work`, `/work/:id` | The projects, each with its own page |
| `/workflow` | The delivery chain the thread walks through |
| `/background` | The CV, laid out to print on one page |
| `/contact` | Contact routes |

Every word on these pages comes from YAML in `content/`, not a database or
CMS. Files are validated when read, and `bin/rails content:check` fails a
production build on a schema error or a leftover `[placeholder]`. Editing a
step: [docs/sop/edit-the-home-thread.md](docs/sop/edit-the-home-thread.md).

The app also carries Devise authentication with a `User` model, SEO plumbing
(`/sitemap.xml`, canonical URLs, JSON-LD), and the Solid Queue/Cache/Cable
stack.

How it is built: [docs/system/home-page.md](docs/system/home-page.md),
[docs/system/home-thread-playback.md](docs/system/home-thread-playback.md), and
[docs/system/site-pages.md](docs/system/site-pages.md).

## Requirements

- **Ruby 3.4.7** (see `.ruby-version`)
- **PostgreSQL** (production runs 16). Each environment uses four databases:
  primary, queue, cable, and cache.
- **Bundler**
- **Chrome**, for system tests only (Capybara + Selenium)
- **Docker** and **Kamal 2**, for deployment only

No Node.js and no Redis: Tailwind is compiled by `tailwindcss-rails`,
JavaScript is served through importmaps, and jobs, cache, and Action Cable all
run on PostgreSQL.

| Stack | |
|---|---|
| Framework | Rails 8.1, uuid primary keys |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS, Slim templates, ViewComponent |
| Background | Solid Queue, Solid Cache, Solid Cable |
| Auth | Devise + Petergate |
| Quality | RuboCop (Rails Omakase), Brakeman, Bullet, Slowpoke |

## Setup

```bash
git clone git@github.com:PositiveControl/markevans.git
cd markevans
bin/setup              # bundle install, db:prepare, then starts bin/dev
```

`bin/setup` is idempotent; run it again after pulling. Pass `--skip-server` to
stop before the server starts, or `--reset` to rebuild the databases.

### Database connection

`config/database.yml` reads its connection from the environment, with defaults
that suit a local PostgreSQL install:

| Variable | Default |
|---|---|
| `DB_HOST` | `localhost` |
| `DB_USERNAME` | your shell `$USER` |
| `DB_PASSWORD` | none |
| `RAILS_MAX_THREADS` | `5` |

### Day to day

```bash
bin/dev                # Rails server + Tailwind watcher, http://localhost:3000
bin/test               # Unit and integration tests
bin/rails test:system  # System tests (Chrome): playback, narrow screens, axe
bin/rubocop            # Lint
bin/brakeman           # Security scan
bin/gates              # The repo's mechanical convention checks (also a pre-push hook)
bin/rails content:check  # Validate everything under content/
```

Development mail is captured by Letter Opener at `/letter_opener`.

### Deployment

Deployed with Kamal 2. Fill in `config/deploy.yml` (image, server hosts,
domain) and `.kamal/secrets`, then:

```bash
kamal setup            # first deploy: provisions the server and accessories
kamal deploy           # every deploy after that
```

Production needs `RAILS_MASTER_KEY`, `DATABASE_URL`, and `POSTGRES_PASSWORD`.
Kamal checks `/up` for health. Server hardening is in
[docs/sop/harden-a-kamal-server.md](docs/sop/harden-a-kamal-server.md).

### Further reading

- [CLAUDE.md](CLAUDE.md): conventions and commands in brief
- [WORKFLOW.md](WORKFLOW.md): the planning, review, and merge lifecycle
- [docs/rules/INDEX.md](docs/rules/INDEX.md): coding conventions, routed by the file you are editing
- [docs/sop/](docs/sop/): repeatable procedures, including updating from the template

## Changelog

Dates are when the change landed on `main`. Numbers are pull requests.

### 2026-10-04

**Added**
- The home thread feature (#22), landed in slices:
  - Design tokens, the thread loader, and content gates that fail a build on
    a schema error, a placeholder, or a literal color (#23).
  - The static thread at `/`, replacing the portfolio page: flight strips,
    step bodies, the legend, and Newsreader alongside IBM Plex (#26).
  - The git graph drawn beside the strips, from each step's data (#27).
  - Playback: play, pause, and step through the thread from the scope (#28).
  - The strip bay, a per-controller filter, a log of finished steps, and a
    page-weight budget gate (#29).
  - Follow and yield on scroll, a docked control bar, step hashes, and
    keyboard control (#30).
  - Narrow-screen layout (#31).
  - The Work, Workflow, Background, and Contact pages, built from content
    files, with a shared header and footer (#32).
- Accessibility checks with axe, with and without scripts, at 390 px and in
  print.
- Reviewer walkthroughs (`bin/qa-walkthrough`, `script/qa/`).

**Removed**
- The single-page portfolio, its command palette, and its scroll reveals
  (#26).

**Fixed**
- A flaky last-step timer test in playback (#33).

### 2026-10-03

**Added**
- Single-page personal site at `/`: hero, metrics, work history, projects,
  skills, and contact sections, with a ⌘K command palette.
- Devise `User` model.

**Changed**
- Upgraded to Rails 8.1.4 and Brakeman 8.1.0; Solid Cable, Cache, and Queue
  schemas re-stamped for 8.1 (#25).
- Updated the alignment layer to Rails Rocket Sheep `7e47077` (v1.1.1),
  including six new workflow commands mirrored to `.cursor/commands`.
- Claude Code hooks now run from the project root.

**Removed**
- `docs/system/architecture.md`, superseded by `docs/adr/`.
- The redundant `app/lib` autoload path (#25).

**Fixed**
- CI test job now receives the database credentials `database.yml` reads (#25).

### 2026-08-06

- Initial commit, generated from the
  [Rails Rocket Sheep](https://github.com/PositiveControl/rails-rocket-sheep)
  template.

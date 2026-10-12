# Site pages — Work, Workflow, Background, Contact

**Status:** Current through #38.

The pages beside the home thread (design doc,
`docs/plans/2026-10-03-home-thread-design.md`, section 2). They are built from
the same tokens and components as `/`, which is `docs/system/home-page.md`.

| Route | Controller | Content | Shows |
|---|---|---|---|
| `GET /work` | `ProjectsController#index` | `content/pages/work.yml`, `content/work.yml` | Title and intro, then the stack filter (`StackFilterComponent`: All and a link per tag in use; `?tag=` keeps only the projects carrying it, and a tag no project carries is ignored), then a heading per category in `Portfolio::CATEGORIES` order, each over its projects in file order: name (mono) linking to its page, summary, and its tags as chips (`ChipComponent`), to the right from 900 px. An empty category is left out |
| `GET /work/:id` | `ProjectsController#show` | one project in `content/work.yml` | Name (mono `h1`: it is the repository's), summary, links, sections. An unknown key is a 404 |
| `GET /workflow` | `WorkflowsController#show` | `content/pages/workflow.yml`, `content/threads/home.yml` | Title and intro, the chain, the legend, then the page's sections |
| `GET /background` | `BackgroundsController#show` | `content/pages/background.yml` | The CV, a cut of Mark's master resume: title, intro, links, sections. Prints to one page |
| `GET /contact` | `ContactsController#show` | `content/pages/contact.yml` | Title, intro, the contact routes, any sections |

`/work` is not paginated. It lists the projects in a content file, which
change only when someone edits that file, never through use of the site
(`docs/rules/pagination.md`).

## Where the content lives

Every word comes from `content/` (`docs/rules/content-is-files.md`). The only
exceptions are the site name and the structural labels: the nav, "The chain"
and the lists' accessible names. Copy not written yet stays in `[brackets]`
(`docs/rules/no-invented-content.md`). The pages render placeholders as
written, so a gap is visible on the page and is never filled in by a guess.

Background, Contact, the Work intro and each project's summary, links and
first section are cut from Mark's master resume (#38). Re-cutting them is
`docs/sop/update-the-cv.md`. What the resume does not answer is still in
brackets: the Contact intro, each project's Role and *How it was built*,
rails-rocket-sheep's and harness's and kraM's Status, rails-rocket-sheep's
first paragraph, and the Workflow page.

**`content/work.yml`**, read by `Portfolio` (`app/lib/portfolio.rb`):

| Key | Required | Means |
|---|---|---|
| `projects[].key` | yes | The URL segment: lowercase letters, digits and single hyphens; unique |
| `projects[].name` | yes | As the project is written, e.g. `kraM` |
| `projects[].summary` | yes | One line: the list's text, the page's lede, its meta description |
| `projects[].category` | yes | The `/work` heading it sits under: one of `Portfolio::CATEGORIES` (`AI and Tooling`, `Applications`, `Languages and Compilers`) |
| `projects[].tags` | no | The project's language and stack, as chips on `/work`, in order. Each must be a chip in `StackRegistry` (`app/lib/stack_registry.rb`) |
| `projects[].links` | no | A list of `label` and `url` |
| `projects[].sections` | no | A list of sections, as a page's |

**`content/pages/<key>.yml`**, read by `SitePage` (`app/lib/site_page.rb`):

| Key | Required | Means |
|---|---|---|
| `title` | yes | The `h1`, and the start of the `<title>` |
| `description` | yes | The meta description, cut to 155 characters |
| `intro` | yes | The paragraph under the `h1` |
| `links` | no | A list of `label` and `url` |
| `sections` | no | A list of `heading` with `paragraphs` (text) and/or `groups` (`title`, `rows` of `k` and `v`) |

A `url` is `https://…` or `mailto:…`, or a `[placeholder]` until the address
is supplied. `LinkListComponent` shows a placeholder as text, never as a link
to nowhere. Anything else fails the schema. That includes `http://` and
`javascript:`.

Both loaders read with `YAML.safe_load_file` and return frozen `Data` objects.
They report every schema problem in one error and read each file once outside
development. `SitePage.fetch` matches a key only against files that exist, and
never joins it into a path. `bin/rails content:schema` loads all of them, so a
broken edit fails the production build (`docs/sop/edit-the-home-thread.md`
describes the gates). It also fails when a file a route reads is missing:
`content/work.yml`, each page in `SitePage::ROUTED` and each thread in
`DeliveryThread::ROUTED`. A test in `test/tasks/content_tasks_test.rb` holds
both lists to the keys the controllers pass to `fetch`. Write lists one item per line. The placeholder gate reads
a flow list, `[a, b]`, as a placeholder.

### Change a project or a page

1. Edit `content/work.yml` or `content/pages/<key>.yml`. A new project is a new
   entry with a `category`, and it appears on `/work` under that heading, gets
   its page and joins the sitemap with no other change. A new category is a
   code change: add it to `Portfolio::CATEGORIES`, in the order `/work` shows it.
   A new chip is too: add its name under its kind in `StackRegistry::ITEMS`.
   A language chip is ink on a strong rule, every other kind quiet on a
   hairline rule, and no kind gets a role color (`docs/rules/color-means-role.md`).
2. `bin/rails content:schema` checks the file. `bin/test test/integration/other_pages_test.rb`
   reads the copy back.
3. `bin/rails content:placeholders` lists what is still in brackets. It must be
   empty before a production build.

A new page needs a route, a controller, a view, a sitemap entry and its key
in `SitePage::ROUTED`; the test above fails until the key is there. Copy one
of the singular pages (`resource :contact`) and follow
`docs/sop/add-seo-to-a-page.md`.

## The 404

`Portfolio.fetch` raises `Portfolio::NotFound` for an unknown key.
`config/application.rb` adds it to `action_dispatch.rescue_responses` as
`:not_found`, so Rails answers with a 404 just as it does for a missing record.
No controller rescues it (`docs/rules/exception-boundary.md`).

## Components

| Component | Renders | Used by |
|---|---|---|
| `SiteHeaderComponent` | The name, linking to `/`, and Work, Workflow, Background, Contact. The section the path is in (its page, or one beneath it) is `aria-current="page"` and underlined. Rendered by the layout; leaves the print | every page |
| `SiteFooterComponent` | The signature and the line about how the site is built, with any content between them. Leaves the print | every page; the home page puts its key list in it |
| `PageSectionsComponent` | Each section: a mono `h2` label over a hairline, serif paragraphs, then its groups | project, Workflow, Background, Contact |
| `DetailGroupComponent` | A mono `h3`/`h4` label over a `dl` of mono key (260 px) and serif value. A value that would get under 180 px wraps beneath its key | `PageSectionsComponent`, `StepBodyComponent` |
| `LinkListComponent` | A `dl` of mono label and address, inside a `role="group"` that carries the list's name. Each address is shown without its scheme and is a 44 px tall, underlined link, or text if it is still a placeholder | project, Background, Contact |

The Workflow page draws its chain from `DeliveryThread.fetch(:home)`, the
steps the home page plays, so the two pages cannot disagree. Each step shows:
- its number
- its `FixMarkComponent`
- its name in mono, linking to `/#<key>`
- its kind in words (`LegendComponent::SYMBOLS`), its lane and its bay
- its outcome in serif
- for each slash command in its name (`Step#commands`), a link to the file
  that defines it in rails-rocket-sheep, `.claude/commands/<name>.md`, opening
  in a new tab

## SEO

Each view sets `content_for` `:title` ("<title> · Mark Evans"),
`:meta_description` and `:canonical_url`, and puts JSON-LD in `:head` through
`StructuredDataHelper`. The home page reads its title and description from
`page_title` and `description` in `content/threads/home.yml`, which a routed
thread must carry. `PageMetaHelper` gives the layout those three values, with
fallbacks for a page that sets none: the site's name, and the request's URL
without its query string.

### Link cards

The layout renders `og:site_name`, `og:type`, `og:title`, `og:description`,
`og:url`, `og:image` (with its width, height and alt) and `twitter:card`
(`summary_large_image`). The title, description and URL are the page's own,
read through `PageMetaHelper`, so a card always matches the search snippet.
`og:type` is `website` unless the page sets `content_for(:og_type)`;
`/background` sets `profile`. `og:image` is the site card unless the page sets
`content_for(:og_image)`.

### The card

`app/assets/images/card.png`, 1200×630, is rendered from `card.svg`: the radar
scope from `icon.svg`, the name in Newsreader and `markevans.io` in Plex Mono,
in the tokens' colours. Most card readers take no SVG, so pages point at the
PNG. After editing the SVG, render it again from `app/assets/images` and
commit both files:

```bash
google-chrome --headless=new --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1200,630 --virtual-time-budget=2000 \
  --screenshot="$PWD/card.png" "file://$PWD/card.svg"
```

The SVG loads its fonts from `../fonts/`, so render it in place.

### Structured data

The layout's JSON-LD, on every page, is one graph: a `WebSite` published by
the `Person` whose `@id` is `https://markevans.io/#mark`
(`StructuredDataHelper::PERSON_ID`). The `@id` is the same literal in every
environment. The Person's `sameAs` is the `https` links `/background` lists,
with placeholders left out (`site_jsonld`). Pages refer to the Person by
`@id`. They never describe Mark again. Every page's JSON-LD names it as
`author` (`web_page_jsonld`):

| Page | JSON-LD |
|---|---|
| `/` | The layout's graph only |
| `/work` | `CollectionPage` whose `mainEntity` is an `ItemList` of the projects, in the page's order (`project_list_jsonld`) |
| `/work/:id`, `/workflow` | `WebPage` (`web_page_jsonld`) |
| `/background` | `ProfilePage` whose `mainEntity` is the Person, by `@id` (`profile_jsonld`) |
| `/contact` | `ContactPage` |

### Crawling

`HomeController#sitemap` lists the four pages and then every project from
`Portfolio.all`. `RobotsController#show` serves `/robots.txt`. Its `Sitemap:`
line is `sitemap_url` for the host that was asked, so it can never name
another. It keeps the template's `Disallow` lines. There is no
`public/robots.txt`. A file there would be served before the route.

`markevans.io` is the canonical host. `www.markevans.io` is in the Kamal
proxy's `hosts`, so it has its own certificate. A host constraint at the top
of `config/routes.rb` answers anything on it with a 301 to the apex, keeping
the path and query. `http://www.markevans.io` takes two 301s: `force_ssl`
moves it to `https://www…` before routing, and the route then moves it to the
apex. That is expected, not a loop. The weekly Lighthouse workflow
(`.github/workflows/lighthouse.yml`) audits `https://markevans.io`.

Walk `robots.txt` and the card in a browser: `bin/qa-walkthrough crawl_baseline`.

## Print

`/background` prints to one A4 or Letter page. Header and footer are
`print:hidden`. The page drops its padding and width (`print:p-0`,
`print:max-w-none`) and tightens its gaps (`print:mt-*`, `print:gap-*`).
`application.css` sets a 10 mm sheet margin with `@page`, which no utility
can do.

Letter is the tight sheet. Its printable area is 980 px tall at 10 mm, and
the CV leaves about 9 px of it, half a line. A4 leaves about 75 px. To
get there, the sections sit one spacing unit (6 px) apart in print, and so
do the links and the sections. Any added line on Background will tip it to
two pages. The print test catches that, and the fix is to cut a row, not
shrink type.

At the screen's scale a Letter page holds about thirty lines, too few for a
CV, so print has its own type scale (#38). The tokens are `text-print-headline`,
`text-print-prose`, `text-print-key` and `text-print-label`, plus a 150 px
`w-print-key` column, all in `tokens.css`. The Background view,
`PageSectionsComponent`, `DetailGroupComponent` and `LinkListComponent`
apply them with `print:`, and a printed link drops its 44 px touch height
(`print:min-h-0`). The screen is unchanged. Because the components are
shared, any page that uses them prints at this scale.

`test/system/other_pages_test.rb` prints the page through Chrome and counts
the PDF's pages. It is what says the CV still fits.

## Tests

| File | Covers |
|---|---|
| `test/lib/portfolio_test.rb`, `test/lib/site_page_test.rb` | The loaders and their schemas |
| `test/tasks/content_tasks_test.rb` | `content:schema` over the work list and pages |
| `test/integration/other_pages_test.rb` | Each page's copy read back from the file, in order; placeholders as written, from `test/fixtures/files/work/placeholder.yml`; the 404; the Workflow chain against the thread, and its command links; the current section; the footer |
| `test/integration/seo_test.rb` | Meta description, canonical URL and JSON-LD per page; the link card on every page and the `og:type` override; the Person on every page and each page's reference to it; the sitemap; `robots.txt` |
| `test/integration/www_redirect_test.rb` | `www` moves permanently to the apex, with the path and query kept |
| `test/helpers/page_meta_helper_test.rb` | The layout's title, description and canonical URL, with their fallbacks |
| `test/components/{site_header,site_footer,page_sections,detail_group,link_list}_component_test.rb` | Each component, including the print scale on a row and a link |
| `test/system/other_pages_test.rb` | axe on every page at 1400 and 390 px, no sideways scroll at 390 px, the one-page print |

Walk it in a browser: `bin/qa-walkthrough site_pages`.

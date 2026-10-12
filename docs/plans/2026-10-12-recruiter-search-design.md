# Recruiter search — design

Status: Approved (G1, 2026-10-12)
Date: 2026-10-12
Slug: recruiter-search
Issue: #55 (slices #56–#60)
**Feature branch:** feature/recruiter-search

When a recruiter looks for a Ruby on Rails engineer who wants a full-time
role, markevans.io should be the first thing they see, whether they search
Google or ask an AI assistant.

**Two places recruiters search.** One is the results page: Google, and Bing
behind it. The other is answer engines: ChatGPT, Claude, Perplexity, Gemini,
and Google's AI Overviews and AI Mode. A recruiter types "find me senior
Rails engineers in Phoenix open to full-time" and gets a short list with
sources. These engines read from search indexes, but each has its own
crawler and its own way of picking what to cite, so each gets its own part
of the plan (*Approach*, 4).

**Search terms and page copy are aimed differently.** Rails is the primary
search term: it is Mark's strongest skill and an easier term to rank for than
"web developer". AI/LLM terms are a secondary target, chosen for what is
distinctive about Mark's work, so they are easier to rank for (*Search
terms*). A recruiter who lands on the site should read a
senior engineer whose strongest stack is Rails and who is open to other
stacks, not a Rails-only candidate. Titles, descriptions and structured data
carry the terms. Page copy stays broad, as `40e8052` made the Background
intro.

## Problem

The readers are the ones the home-thread design names: hiring managers first,
then engineers on the hiring team (`docs/plans/2026-10-03-home-thread-design.md`,
section 2). This feature adds a step before they read: recruiters, who find
candidates through search. Today they have no way to find the site through
search.

What the live site says about itself (curl, 2026-10-12):

- **Rails is missing from every heavily weighted place.** The home `<title>` is
  "Mark Evans". Its description and `h1` are about coding agents. The pages are
  titled Work, Workflow, Background and Contact. "Ruby on Rails" appears only
  in the Skills row of `/background`. A commit from 2026-10-11 (`40e8052`)
  took "Rails" out of the Background intro on purpose.
- **The crawl surface is broken.** Production serves a `robots.txt` that points
  at `https://YOURAPP.com/sitemap.xml`. The Lighthouse workflow audits
  `YOURAPP.com`.
- **Shares look bare.** `docs/sop/add-seo-to-a-page.md` tells pages to set
  `og_*` blocks, but the layout never renders them. A link pasted into
  LinkedIn, Slack or an ATS shows no card.
- **Nothing on the site is about Rails specifically.** The site makes its
  claims through projects. There is no writing, so nothing can rank for the
  technical queries that bring a Rails reader in.
- **There is no measurement.** Search Console is not set up, so nobody knows
  which queries the site shows up for, or where it ranks. Nothing records
  whether an AI crawler has fetched the site, or whether an answer engine has
  sent anyone to it.
- **Answer engines are not addressed.** `robots.txt` allows every agent but
  names none. The site is not registered with Bing, whose index sits behind
  ChatGPT search, Copilot and (in part) Perplexity. Nothing on the site is a
  short, self-contained statement of who Mark is and what he is looking for,
  which is the kind of passage an answer engine quotes.
- **`www` is broken.** `www.markevans.io` resolves to the server, but no
  certificate covers it, so a visitor gets a TLS error instead of a redirect
  (curl, 2026-10-12). `http://` already redirects to `https://markevans.io/`.

## What "number one" means here

Taken literally, the goal is out of reach for any personal site, so the plan
names the searches it can win and sets aside the one it cannot.

| Query shape | Example | Who ranks today | Target |
|---|---|---|---|
| Name + skill | "Mark Evans Rails" | LinkedIn, GitHub, other Mark Evanses | **#1**. Recruiters search this once they have a name from a referral, a résumé or LinkedIn |
| Skill + place + intent | "senior Ruby on Rails engineer Phoenix", "Rails engineer open to full-time remote" | Job boards, a few personal sites | **Top 3** |
| AI/LLM terms (secondary) | See *Search terms* | Depends on the tier | Per tier, below |
| Long-tail technical | "flay duplicate code CI gate", "shard Rails tests GitHub Actions", "coding agent workflow gates", "Postgres slow query missing index Rails" | Blogs, Stack Overflow, docs | **Page 1** for each article |
| Head terms | "ruby on rails developer", "AI engineer" | Indeed, LinkedIn, Toptal, Upwork, agencies | **Not targeted** (see *Rejected alternatives*) |
| Answer-engine prompt | "Find senior Rails engineers in Phoenix open to full-time", "Who is Mark Evans, the Rails engineer?" | Whatever the engine's index and corroborating sources support | **Named, with markevans.io cited**, for the name prompt in every engine; named in the short list for the Phoenix prompt in at least two |

The secondary AI/LLM target is where the site's existing claim already
points. The home thread, `/workflow` and harness are about building with
coding agents, and the résumé backs it: the platform's first LLM backend, a
self-hosted vLLM host, and a multi-model OCR pipeline. Once the terms are
chosen, they need to appear where a crawler gives words the most weight,
and they need articles to rank with. They do not need new claims.

Answer engines mostly reward the same work: being in the index they read,
and being corroborated by other sources. A model names a candidate when
several sources agree (the site, LinkedIn, GitHub, an article someone
linked). The one thing they add is a preference for a passage that answers
the question on its own.

The head terms are listed so they are not re-argued later.

## Search terms

Settled 2026-10-12: Mark took the recommended set (open question 7). There is no
keyword-volume data behind this. Each term is judged on who ranks for it
today (web searches, 2026-10-12) and on whether Mark's work is distinctive
there. Search Console data replaces the judgment after about 60 days.

**The principle: rank where the competition is thin and the proof is Mark's
own.** A term where Mark has unusual proof and the results are job
listings, or a few months old, is winnable. A term where the results are
established publishers is not.

### Tier A: the role, as recruiters type it

| Term | Who ranks today | Mark's proof | Verdict |
|---|---|---|---|
| **"AI Engineer, Ruby on Rails"** | Only job postings: employers post this exact title (Workable, WeAreDevelopers). No candidate pages | The platform's first LLM backend, built in Rails; the self-hosted vLLM host; the OCR pipeline | **Recommended primary AI term.** Recruiters with this req search this title. The candidate who matches it can win it |
| "Rails LLM engineer", "Ruby on Rails developer LLM" | Job postings | Same | Take it as a variant of the above, in the description and `knowsAbout` |
| "AI engineer Phoenix" | Job boards, consultancies | Same | Secondary. Only the Rails pairing is distinctive |

### Tier B: expertise, where articles rank and hiring managers search

| Term | Who ranks today | Mark's proof | Verdict |
|---|---|---|---|
| **"Deterministic gates" / "deterministic guardrails for coding agents"** | Emerging: 2026 blogs, a pattern catalogue (agentpatterns.ai), an arXiv paper. No Rails-specific source | rails-rocket-sheep's gates, harness's "failures become deterministic guards", `bin/flay`, the query ledger | **Recommended.** The flay series already targets it, and nobody owns the Rails angle |
| **"Harness engineering" / "agent harness"** | Emerging: a 2026 arXiv paper, a few blogs | harness: a turn state machine, a critic loop, 11 eval suites, a router bake-off, 4,231 tests with no mocks | **Recommended.** A new term, and Mark's project is literally named for it. Wants its own article (*Approach*, 3) |
| "Agent-native Rails template", "Rails for AI coding agents" | Crowded since 2026: Obie's Machina, rails_ai_agents, claude-on-rails | rails-rocket-sheep | Use on the project page, not as a target. Others got there first |
| "LLM evals", "self-hosted vLLM" | Vendors and established publishers | harness's evals; the vLLM GPU host | Keywords on the pages they belong to, not targets |

### Tier C: identity, terms only Mark has

| Term | Why |
|---|---|
| **"Positive control"** for coding agents | Mark's coined frame, from his own Navy air traffic control work. Almost nobody searches it, but using it the same way everywhere teaches answer engines to tie Mark to a concept, and a recruiter who has seen it can find him with it |
| "Air traffic controller turned software engineer" | Rare and memorable. It is the hook a recruiter repeats to a hiring manager. Use it in the quotable paragraph and on LinkedIn, not in titles |

**The chosen set:** "AI Engineer, Ruby on Rails" (A), "deterministic
gates" and "harness engineering" (B), and "positive control" used everywhere
(C). Applied that way:

- Home `<title>`: "Mark Evans · Senior Rails & AI Engineer"
- `jobTitle`: "Senior Software Engineer"
- `knowsAbout`: adds "AI engineering", "LLM integration", "agent harness
  engineering", "deterministic guardrails"
- The B terms are earned by articles, not by meta tags.

## Constraints

- **Copy is content, and none of it is invented** (`docs/rules/content-is-files.md`,
  `docs/rules/no-invented-content.md`). Every title, description and fact a
  recruiter needs (availability, work authorization, location terms) comes
  from Mark. Anything he has not supplied ships in `[brackets]`, and the
  placeholder gate keeps it out of production.
- **`/background` stays one printed page.** It has about 9 px of room on
  Letter (`docs/system/site-pages.md`, *Print*). Positioning goes in the intro
  and the meta, not in new rows.
- **The home page's claim is the agent workflow.** "I build web products with
  coding agents under positive control" is settled positioning (home-thread
  design, section 2), and the `h1` stays as it is. This feature adds Rails and
  AI to the title and meta around that claim.
- **No Rails-only copy.** Page copy never presents Mark as Rails-only. Where
  it names Rails, it is as the strongest stack, alongside openness to others
  (Mark, 2026-10-12). The Background intro stays "web".
- **No new top-level pattern.** Articles are content files with a loader in
  `app/lib/`, like `Portfolio` and `SitePage` (`docs/rules/pattern-budget.md`).
- **No spam signals.** Nothing that Google's spam policies name: doorway pages,
  keyword stuffing, or structured data that misdescribes the page.
- **The site is a feature, not a campaign.** The app can make Mark findable and
  convincing. Backlinks, LinkedIn and community presence are where much of the
  ranking comes from, but they happen outside the repo. They are listed under
  *Outside the app* and tracked in an SOP, not as issues.

## Approach

Five parts.

### 1. Crawl baseline: let Google read the site correctly

- **`robots.txt` from a route.** It names `sitemap_url` for the request's host,
  so it can never point at the wrong host again. Delete `public/robots.txt`.
- **Social and ATS cards.** The layout renders `og:title`, `og:description`,
  `og:url`, `og:type` and `twitter:card`, defaulting to the page's own title,
  description and canonical URL. One site-wide card image goes in
  `app/assets/images`. Its design is part of the slice, built from the existing
  tokens and the radar scope.
- **One Person entity.** The layout's `WebSite` JSON-LD gains a `Person` with a
  stable `@id` (`https://markevans.io/#mark`), `sameAs` set to GitHub and
  LinkedIn, and `jobTitle` and `knowsAbout` read from content. Every page's
  JSON-LD refers to that `@id` instead of describing Mark again. Consistent
  entity data is what helps Google tie the name, the profiles and the site
  together on a name search.
- **The home page's title and description move to content.** They are
  hard-coded in `home/index.html.slim` today, so a copy change needs a code
  change. They join the other pages' copy in `content/`.
- **`www` redirects to the apex.** `www.markevans.io` joins the Kamal proxy
  hosts so it gets a certificate, and a 301 sends it to `https://markevans.io`.
  The apex stays canonical, so the site never splits its ranking across two
  hosts.
- **Housekeeping.** The Lighthouse workflow audits `https://markevans.io`. The
  sitemap's `changefreq` and `priority` stay as they are, because Google
  ignores both.
- **Search Console and Bing Webmaster Tools.** Mark adds the DNS TXT record
  and the Search Console property (domain-wide, so `www` and the apex count
  as one), then imports the site into Bing Webmaster Tools from Search
  Console. Bing's index is the one behind ChatGPT search and Copilot. No code
  changes, and nothing about it lives in the app. Both go in before slice 1
  deploys, so there is a baseline to compare against.

### 2. Positioning: say "Rails" and "AI" where Google looks

Mostly content, plus the Person data. **Search terms go in the metadata; the
page copy stays broad.**

- **Titles and descriptions name both targets.** Home, Background and Contact
  carry a role line in the `<title>` and description. Proposed (Mark edits):
  - Home `<title>`: "Mark Evans · Senior Rails & AI Engineer"
  - Home description: "Senior software engineer in Phoenix. Strongest in
    Ruby on Rails; builds LLM features and ships with coding agents under
    positive control. Open to full-time roles."

  Under 60 and 155 characters. Rails comes first because it is the term
  most likely to rank.
- **`/contact` becomes the page recruiters land on.** The route and nav label
  stay. Its title, intro and one new section, *At a glance*, answer what a
  recruiter screens for, in their order. The facts are Mark's (2026-10-12):

  | Row | Value |
  |---|---|
  | Looking for | Full-time senior, lead or staff roles |
  | Availability | Available; start pending notice at current role |
  | Work authorization | US citizen; no sponsorship needed |
  | Location | Remote, hybrid, or in-office in the Phoenix metro |
  | Contract-to-hire | Open to it; full-time preferred |
  | Stack | Strongest in Ruby on Rails; open to other stacks. LLM features and agent workflows |

  No salary on the page. The level line keeps today's "senior, lead, or staff"
  from `content/pages/contact.yml`. The stack row is the sentence that keeps
  Rails from reading as a limit.
- **The Person data names both.** `jobTitle` ("Senior Software Engineer") and
  `knowsAbout` (Ruby on Rails, Hotwire, PostgreSQL, Kamal, large language
  models, LLM inference, AI coding agents, …) come from the same content, so
  the page and the structured data cannot disagree. `knowsAbout` is where
  breadth is cheap: it says "Rails and more" to a machine without any
  Rails-only copy.
- **The Workflow page's title and description** name AI coding agents. It is
  the page most likely to rank for the agent-workflow searches.
- Each project page's JSON-LD becomes `SoftwareSourceCode` with
  `programmingLanguage` taken from its `tags`, where it has a repository link.
  `rails-rocket-sheep` is the strongest Rails proof on the site, and its page
  should say so to a machine as well as a person.

### 3. Writing: earn the long-tail queries

`/writing` and `/writing/:slug`, which are articles in Markdown in
`content/writing/`, read by a `Writing` loader in `app/lib/` with the same
shape as `Portfolio`: a frozen `Data` object, a schema checked at load time,
and `content:schema` coverage.

- Front matter: `title`, `description`, `published_on`, `updated_on`
  (optional), `tags` (from `StackRegistry`), and `series` (optional).
- **Series.** Two of the planned topics are series, so a series is a key in
  front matter, not a page type. `Writing::SERIES` lists each series' key,
  name and one-line description, the way `Portfolio::CATEGORIES` lists
  categories. `/writing` groups articles under their series and puts single
  articles after them. Each article in a series shows its place ("Part 2 of
  Deterministic gates") and links to the other parts. Its JSON-LD carries
  `isPartOf` and `position`. A series page of its own is deferred until a
  series has enough parts to need one.
- `BlogPosting` JSON-LD whose `author` is the Person `@id`. The pages join the
  sitemap with `lastmod` from `updated_on || published_on`, the one sitemap
  field Google reads.
- An Atom feed at `/writing.atom`, the format Ruby Weekly, RubyFlow and feed
  readers pick up.
- A nav entry "Writing", added when the first article exists.
- **Renderer:** `commonmarker` (GitHub-flavored Markdown, a Rust extension, no
  JS). It is the one new gem in the feature. The task plan checks it against
  brakeman's view of `html_safe`, and the output is sanitized.
- Not paginated: like `/work`, the list changes only when a file is edited,
  never through use of the site (`docs/rules/pagination.md`).

The topics are Mark's (2026-10-12). Each sits on a skill the résumé already
claims, and each figure comes from a repo or from Mark
(`docs/rules/no-invented-content.md`):

| Topic | Shape | Search target | Source of truth |
|---|---|---|---|
| Deterministic gates: using flay to catch duplicated code | Series *Deterministic gates*, part 1. Later parts: the other mechanical gates (lint, brakeman, the placeholder and schema gates, the query ledger) | Rails, and AI: gates are how agent-written code is held to a standard | `bin/flay`, rails-rocket-sheep |
| CI tuning: sharding tests | Series *CI tuning*, part 1 | Rails | A real CI run's timings, before and after |
| Building an AI workflow | Single article | AI/LLM | `WORKFLOW.md`, `.claude/commands/`, rails-rocket-sheep's history |
| Database and query tuning | Single article | Rails, Postgres | The card-labeler fix (20–25 s → ~1 s, un-indexed 570k-row scans), in the detail Mark can share |
| Harness engineering: making a local model reliable unattended | Single article | AI/LLM, tier B "harness engineering" | The harness repository: its turn state machine, guards, eval suites and router bake-off |

**First article: flay as a deterministic gate.** Its subject runs in this
repo (`bin/flay`), so every command and every output in it can be
reproduced. It opens the series that ties the Rails and AI targets
together.

**The harness-engineering article** is the fifth topic (Mark, 2026-10-12).
It earns the tier B term, and its source of truth is the harness
repository.

#### How an article gets written

Each article goes through four steps. Steps 1 and 3 are Mark's, and step 4
makes step 2 better over time:

1. **Structure, together.** Mark and the agent agree an outline: title,
   the query it targets, the sections, the claim each section makes, and
   the evidence each claim rests on (a command, a commit, a CI run, a
   number from Mark). It is committed as the article file with headings and
   bullets only. Nothing gets drafted until the outline is agreed.
2. **Draft.** The agent writes prose under each heading, following the voice
   rule (below), and uses only the evidence listed in the outline.
   Committed with the trailer `Voice: draft`.
3. **Refine.** Mark edits the draft into the article he would sign.
   Committed with the trailer `Voice: edit`. Facts corrected here are also
   recorded, but they are not voice.
4. **Learn.** `/voice_learn <slug>` reads the draft-to-edit diff and proposes
   changes to the voice rule. Mark approves them.

A default skeleton to start the outline from; each article changes it as
needed:

- **The incident:** a real moment the problem cost something
- **Why a prompt was not enough:** the probabilistic fix, and why it fails
- **The gate:** what it checks, how it runs, its real output
- **What it caught:** examples from repo history
- **What it costs:** false positives, runtime, when not to use it
- **Adopt it:** the steps for a reader's own app
- **The series:** the other parts, as links
- **About the author:** one line, rendered from `/contact`'s content: who
  Mark is, that he is open to full-time roles, and a link. Every article
  is a door to the page recruiters land on.

**The voice rule, `docs/rules/article-voice.md`.** It routes from the index
for `content/writing/**`, so any agent drafting there reads it with no
extra step. Each trait is written as a rule's Wrong/Right pair, taken from
a real draft-to-edit pair: the sentence the agent wrote, and the one Mark
kept. Every trait cites the article it came from. When a later edit
contradicts a trait, the trait is changed, not added to. The rule's read
cost is capped (`bin/doc-tokens`), so it stays sharp instead of growing
forever.

**The script, `bin/voice-pairs <slug>`.** Deterministic, with no model
call. It finds the `Voice: draft` and `Voice: edit` commits for an article,
aligns their paragraphs, and prints each changed pair with a word-level
diff, plus one number: the share of words Mark changed. Tests run it on a
fixture repository.

**The command, `/voice_learn <slug>`.** It reads the script's output and
sorts each change into voice (word choice, rhythm, cuts, structure) or fact
(not voice). It proposes new, changed or retired traits, each with its
evidence, and edits the rule once Mark approves. It also appends the
article's change share to a ledger table in the rule. **That share is the
measure of the drafts getting better:** if it falls from article to
article, the loop works.

**The seed.** The rule starts with only what is already known: the
no-invented-content and no-volume constraints, and any traits Mark states
now. Copy already on the site is not used as evidence, because it was cut
from the résumé or drafted with an agent, and is not known to be Mark's own
prose. If Mark has writing of his own (a post, a long email, a design doc
he wrote by hand), one sample would give the first draft a head start (open
question 9).

### 4. Answer engines: be in what they read, and be quotable

What each engine reads, as of 2026-10:

| Engine | Index it answers from | Crawler tokens |
|---|---|---|
| Google AI Overviews, AI Mode, Gemini | Google's index | `Googlebot`. `Google-Extended` covers Gemini training only |
| ChatGPT search | Bing, plus OpenAI's own crawl | `OAI-SearchBot` (search), `ChatGPT-User` (fetch on request), `GPTBot` (training) |
| Copilot | Bing | `Bingbot` |
| Claude | Brave Search | `Claude-SearchBot` (search), `Claude-User` (fetch on request), `ClaudeBot` (training) |
| Perplexity | Its own crawl, with Bing | `PerplexityBot`, `Perplexity-User` |

Every token is independent: allowing a search bot and blocking its training
bot is a supported combination.

- **`robots.txt` allows every AI crawler by name, training included**
  (Mark, 2026-10-12). One group lists each user agent above, plus
  `Applebot-Extended`, `CCBot`, `PerplexityBot` and `Meta-ExternalAgent`, so a
  later blanket rule cannot shut them out by accident. A crawler that
  matches a named group ignores the `*` group, so the named group repeats
  its `Disallow` lines (`/users/…`). The test checks the two groups match.
- **IndexNow on deploy.** A post-deploy step tells Bing (and the other
  IndexNow engines) which URLs changed, so ChatGPT and Copilot see a new
  article in hours instead of on Bing's next crawl. A key file under
  `public/`, plus one `curl` in the Kamal post-deploy hook, listing the
  sitemap's URLs. Brave has no submission API: it finds pages through links
  and crawling, which is one more reason the backlinks in part 5 matter.
- **The facts are in the HTML.** Answer-engine crawlers mostly do not run
  JavaScript. The home thread already renders completely without scripts
  (home-thread design, section 1). A test fetches `/contact` and `/` without
  JS and checks that the facts are there: name, role, Rails, location,
  availability.
- **One quotable paragraph.** `/contact` opens with one plain paragraph that
  answers "who is this and what is he looking for" without needing the rest
  of the page. The `Person` data says the same thing, and so do the LinkedIn
  headline and about section (*Outside the app*). The *At a glance* rows are
  the second thing an engine lifts. It is content, Mark writes it, and it
  follows the no-Rails-only rule.
- **`/llms.txt`, generated, at low priority.** A Markdown summary built from
  the same content files (the paragraph, the facts, the page list), so it
  cannot drift from the site. Expect little from it: in a May 2026 sample,
  97% of `llms.txt` files got no requests, and the major labs' crawlers fetch
  it a fraction of a percent as often as `robots.txt`. It is in the plan
  because it is about 40 lines, coding assistants do read it, and it costs
  nothing to keep. If the slice runs long, it is the first thing cut.
- **Measure what can be measured.** Answer engines have no Search Console, so:
  - **Tagged log lines.** A request from an AI crawler (by user agent) or one
    referred by an answer engine (`utm_source=chatgpt.com`, or a referrer of
    chatgpt.com, perplexity.ai, claude.ai, gemini.google.com or
    copilot.microsoft.com) is logged with a tag, so
    `kamal app logs | grep ai_` answers "has ChatGPT fetched us, and has it
    sent anyone?" No database table and no analytics vendor.
  - **A monthly prompt panel**, in the SOP. Run a fixed set of recruiter
    prompts in ChatGPT, Claude, Perplexity, Gemini and Google AI Mode. Record
    whether Mark is named, whether markevans.io is cited, and whether what is
    said is right. The prompts are fixed so months can be compared.

### 5. Outside the app

These are not issues. `docs/sop/recruiter-visibility.md` holds the checklist,
the monthly Search Console review and the prompt panel:

- LinkedIn: headline names Rails and the chosen AI terms, for example "Senior
  Software Engineer · Ruby on Rails · LLM & AI agents"; the about section
  repeats `/contact`'s opening paragraph, so the sources agree when an answer
  engine compares them; Open to Work, set to recruiters only, with remote,
  hybrid and Phoenix listed; markevans.io in the contact info and the
  Featured section.
- GitHub: a profile README linking markevans.io. The rails-rocket-sheep README
  links back to the site.
- Each article goes to RubyFlow, Ruby Weekly and r/rails, and is cross-posted
  to dev.to with `canonical_url` pointing at markevans.io.
- The monthly HN "Who wants to be hired?" thread, and the Ruby on Rails Link
  Slack's job channels.
- Phoenix Ruby meetups, and conference CFPs for any article that lands well.

## Rejected alternatives

- **Targeting the head terms "ruby on rails developer" and "AI engineer".**
  Those results pages answer a different question, "where do I hire one?",
  and job boards, marketplaces and agencies own them with domain authority a
  personal site cannot match. Recruiters at that stage search LinkedIn
  Recruiter, not Google. The effort goes to the queries a recruiter types
  once Google is the right tool.
- **Rails-first page copy.** It would rank about the same as broad copy,
  since titles and meta carry the terms. But it would tell a recruiter who
  has already arrived that Mark is Rails-only, and he is not
  (Mark, 2026-10-12).
- **"AI Engineer" as the headline title.** It is a crowded and loosely
  defined label, and the résumé's AI claims sit inside product engineering
  roles. "Rails & AI Engineer" says what the work actually was.
- **`JobPosting` or any "job seeker" structured data.** `JobPosting` is for
  employers. Using it on a candidate's page misdescribes the page and risks a
  manual action. schema.org has no candidate type, so `Person` and
  `ProfilePage` are the honest fit.
- **A separate `/hire` page beside `/contact`.** The two would say the same
  thing, and two thin pages rank worse than one complete one. `/contact` is
  already the page that says "looking for full-time".
- **City pages ("Rails engineer in Austin / Denver / …").** Google's spam
  policy calls these doorway pages. One page that says "remote or Phoenix"
  covers it.
- **Writing hosted on dev.to or Medium as the primary copy.** The links and
  authority would build up on their domain. Cross-posting with a canonical
  back to markevans.io gets the reach without that loss.
- **Blocking AI crawlers by default.** Some sites do, to keep their content
  out of training. The goal here is the opposite: to be known. Search and
  user-fetch bots are always allowed. Training bots are Mark's call (open
  question 8).
- **Automating the prompt panel** through each vendor's API, with web search
  turned on. API answers differ from what a recruiter sees in the consumer
  apps, the result has to be judged by reading it, and the panel is five
  prompts a month. Revisit if it grows.
- **Writing "for the AI" (FAQ blocks, keyword lists, prompt-shaped copy).**
  Engines reward pages that answer a question plainly, and so do recruiters.
  One paragraph that works for both is enough. Text written at the engines
  reads as spam to people and is, by Google's policy.
- **Fine-tuning a model on Mark's voice.** One article gives a few dozen
  edit pairs, far too few to fine-tune on. A rule with real examples
  works in context today, is readable and reviewable, and carries over to
  any model.
- **Keeping the voice guide in agent memory or a prompt outside the repo.**
  It could not be reviewed, it would not reach other sessions or tools, and
  nothing would record what changed or why.
- **Drafting before the outline is agreed.** Prose hides structural
  problems, and fixing them after drafting costs more. The outline is also
  the point where every claim is tied to its evidence, before the prose can
  blur it.
- **A generated PDF résumé.** Recruiters do want a file for the ATS, but
  `/background` already prints to one page, and server-side PDF rendering adds
  Chrome to the image. Deferred: revisit if recruiters ask for one.
- **Paid search.** Not a site feature, and the cost per click for "hire"
  queries buys agency traffic.

## Open questions

Settled 2026-10-12 (Mark):

1. **Positioning.** Rails is the search term because it is the strongest
   skill and the easiest to rank for. AI/LLM is a second target. The copy must
   not read as Rails-only, so metadata names both and page copy stays broad
   (*Approach*, 2).
2. **Recruiter facts.** Available, pending notice at the current role. US
   citizen. Remote, hybrid or in-office in the Phoenix metro. Open to
   contract-to-hire, though full-time is preferred (*Approach*, 2).
3. **Search Console.** Mark adds the DNS record and the property. The `www`
   question was settled by evidence: it fails TLS today, so slice 1 makes it
   redirect.
4. **Articles.** Flay as a deterministic gate (series), sharding tests in CI
   (series), building an AI workflow, and database and query tuning. Flay
   goes first (*Approach*, 3).

Still open. None of these blocks cutting issues:

7. ~~The secondary AI/LLM terms~~ **Settled 2026-10-12:** the recommended
   set under *Search terms*. They are reviewed against Search Console data
   about 60 days after slice 1 deploys.
8. ~~Training crawlers~~ **Settled 2026-10-12:** every AI crawler is
   allowed, training included.
9. **A voice seed. Deferred, a to-do for Mark.** He will supply samples of
   his own writing. Slice 5 ships the rule with the stated seed. A sample
   that arrives later goes through `/voice_learn` like any edit pair, as
   evidence for traits; it is not pasted into the rule.
10. ~~The harness-engineering article~~ **Settled 2026-10-12:** it is the
    fifth topic.

5. **Wording sign-off.** The proposed title, description and *At a glance*
   rows are written from Mark's answers. He approves the exact strings in
   slice 2's task plan. Until then they ship in brackets.
6. **The first article's draft.** The code in slice 3 can merge to the
   feature branch without an article. The nav entry, and the feature PR to
   `main`, wait for the flay article. Who drafts it (Mark, or an agent from
   `bin/flay` output with Mark editing) is decided when slice 3 is planned.

## Decomposition

Multi-slice, on `feature/recruiter-search`.

| # | Slice | Contents | Forecast |
|---|---|---|---|
| 1 | Crawl baseline | Dynamic `robots.txt`; OG/Twitter tags in the layout with defaults and the card image; Person `@id` site-wide; home title and description from content; `www` → apex redirect; Lighthouse URL; tests in `seo_test.rb` | ~400 lines, ~14 files |
| 2 | Recruiter positioning | Rails & AI titles and descriptions on home, Background, Contact and Workflow; `/contact`'s *At a glance*; `jobTitle`/`knowsAbout` from content; `SoftwareSourceCode` on project pages; the outside-the-app SOP; walkthrough | ~350 lines, ~14 files, mostly content and tests |
| 3 | Writing | `Writing` loader and schema with `series`; `/writing`, `/writing/:slug`, Atom feed; `BlogPosting` JSON-LD with `isPartOf`; the about-the-author line from `/contact`'s content; sitemap `lastmod`; `commonmarker`; nav entry; walkthrough. Articles themselves are content PRs after it | ~1,200 lines, ~24 files |
| 4 | Answer engines | Named bot groups in `robots.txt`; IndexNow key file and post-deploy ping; tagged log lines for AI crawlers and referrals; the no-JS facts test; the quotable paragraph's slot on `/contact`; generated `/llms.txt`; the prompt panel in the SOP | ~450 lines, ~14 files |
| 5 | Article workflow | `docs/rules/article-voice.md` (seed) and its index routing; `bin/voice-pairs` with tests on a fixture repository; `/voice_learn` in `.claude/commands/`; the command count in `CLAUDE.md` and `WORKFLOW.md`; `docs/sop/publish-an-article.md` | ~450 lines, ~10 files |

Slice 2 depends on slice 1 (the Person `@id`). Slice 3 depends on slice 1 and
can run alongside slice 2. Slice 4 depends on slices 1 and 2 (the `robots.txt`
route, and the `/contact` content that `/llms.txt` and the facts test read).
Slice 5 depends only on slice 3's path convention, `content/writing/`, and
can start alongside it.

The flay article's outline (step 1) does not have to wait for any slice:
it can be agreed as soon as this design is approved, and drafted once slice 5
lands, so the first draft is also the voice loop's first data point.

## Measuring it

Monthly, in the SOP:

- **Search Console and Bing Webmaster Tools:** impressions and average
  position for each target row, and which `/writing` pages bring clicks.
- **Logs:** AI crawler fetches and answer-engine referrals, by engine.
- **The prompt panel:** named, cited and correct, by engine.

Success after 90 days:
- #1 for "Mark Evans" plus Rails
- page 1 for "Ruby on Rails engineer Phoenix"
- the flay article on page 1 for its own query
- every engine in the panel names Mark and cites markevans.io for the name
  prompt
- targets for the AI/LLM terms, set once they are chosen Below that, the SOP says what to look at first: the coverage report,
then backlinks, then copy.

## Docs impact

| File | Change | Slice |
|---|---|---|
| `docs/system/site-pages.md` | *SEO* section: Person entity, OG tags, `robots.txt` route, `/contact`'s new role | 1, 2 |
| `docs/sop/add-seo-to-a-page.md` | OG tags now render; refer to the Person `@id`; no `public/robots.txt` | 1 |
| `docs/system/writing.md` (new) | Loader, schema, routes, feed, renderer | 3 |
| `docs/sop/publish-an-article.md` (new) | Outline, draft, refine, learn; check, ship, cross-post with canonical | 3, 5 |
| `docs/rules/article-voice.md` (new) + `docs/rules/INDEX.md` | The voice rule, routed for `content/writing/**` | 5 |
| `CLAUDE.md`, `WORKFLOW.md` | The command count and table gain `/voice_learn` (a local command, which an agent may invoke) | 5 |
| `docs/sop/recruiter-visibility.md` (new) | The *Outside the app* checklist, the monthly Search Console and Bing review, the log greps and the prompt panel | 2, 4 |
| `docs/system/site-pages.md` | *SEO*: the named bots in `robots.txt`, IndexNow, `/llms.txt`, the AI log tags | 4 |

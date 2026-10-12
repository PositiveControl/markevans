# How To: Keep Recruiters Finding the Site

**Status:** Current through #57. #59 adds the AI log greps and the
answer-engine prompt panel.

The work outside the app that ranking depends on, and the monthly review
that says whether it is working. Design:
`docs/plans/2026-10-12-recruiter-search-design.md`, *Approach* §4 and §5,
and *Measuring it*. What the app itself says to a crawler (titles, the
Person, `/contact`'s *At a glance*) is `docs/system/site-pages.md`, *SEO*.

The site can make Mark findable and convincing. Much of the ranking comes
from elsewhere: other sources that agree with it, and links to it.

---

## Once: outside the app

Do each of these once, then re-check them in the monthly review. Wherever a
profile describes Mark, it uses the same words as `/contact`, so search
engines and answer engines see sources that agree.

### Search Console and Bing

- [ ] Search Console: a **domain** property for `markevans.io`, verified by a
  DNS TXT record, so `www` and the apex count as one site.
- [ ] Submit `https://markevans.io/sitemap.xml` in Search Console.
- [ ] Bing Webmaster Tools: import the site from Search Console. Bing's index
  is behind ChatGPT search and Copilot, and partly behind Perplexity.

### LinkedIn

- [ ] Headline names Rails and the AI terms, for example "Senior Software
  Engineer · Ruby on Rails · LLM & AI agents".
- [ ] The About section repeats `/contact`'s opening, and the *At a glance*
  facts say the same thing as `content/pages/contact.yml`.
- [ ] Open to Work, visible to recruiters only, with remote, hybrid and
  Phoenix listed.
- [ ] `https://markevans.io` in the contact info and in Featured.

### GitHub

- [ ] A profile README (`PositiveControl/PositiveControl`) linking to
  `https://markevans.io`.
- [ ] The rails-rocket-sheep README links back to the site.

### Each article

Once `/writing` exists (#58), each article goes to:

- [ ] RubyFlow, Ruby Weekly and r/rails.
- [ ] dev.to as a cross-post, with `canonical_url` set to the article's
  markevans.io URL, so the links and ranking build up on markevans.io.

### Ongoing

- [ ] The monthly Hacker News "Who wants to be hired?" thread.
- [ ] The job channels in the Ruby on Rails Link Slack.
- [ ] Phoenix Ruby meetups, and a conference CFP for any article that does
  well.

---

## Monthly: Search Console and Bing

Once a month, in Search Console (*Performance → Search results*, last 28
days) and then in Bing Webmaster Tools (*Search Performance*):

1. **Target queries.** Filter *Queries* by each target from the design's
   table (*What "number one" means here*) and record its impressions,
   clicks and average position:

   | Target | Query to filter on | Goal |
   |---|---|---|
   | Name + skill | `mark evans` with `rails` | #1 |
   | Skill + place + intent | `rails` with `phoenix`, `full-time` or `remote` | Top 3 |
   | AI/LLM, tier A | `ai engineer` with `rails` | Rank at all, then climb |
   | Long-tail technical | each article's own query | Page 1 |

2. **Pages.** Under *Pages*, check that `/contact` gets impressions on the
   role queries. If `/` or `/background` is taking them instead, Google
   has not picked `/contact` as the recruiter page.
3. **Coverage.** Under *Indexing → Pages*, every URL in the sitemap is
   indexed. A page listed as "Crawled – currently not indexed" or
   "Duplicate" is the first thing to fix.
4. **Record it.** Add one row per month to the table below, so the months
   can be compared.

When a target does not move, look at these in order: coverage first, then
the links pointing to the site (*Links* in Search Console), then the copy.
About 60 days after the crawl baseline (#56) deploys, review the AI/LLM
terms against this data (design, *Search terms*).

| Month | Name + Rails (pos.) | Rails Phoenix (pos.) | AI Engineer Rails (impr.) | Pages indexed | Notes |
|---|---|---|---|---|---|

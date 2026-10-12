# How To: Add SEO to a New Page

What the layout already does for every page is in `docs/system/site-pages.md`,
*SEO*. A new page sets four things and gets the rest from there.

## Steps

### 1. Set the title, meta description and canonical URL

In your Slim view, add `content_for` blocks at the top. The copy comes from the
page's content file (`docs/rules/content-is-files.md`):

```slim
- content_for :title, "#{@page.title} · Mark Evans"
- content_for :meta_description, @page.description.truncate(155, separator: " ")
- content_for(:canonical_url) { your_page_url }
```

The layout falls back to defaults if these are not set (`PageMetaHelper`):
- **Title and description:** "Mark Evans"
- **Canonical URL:** Current URL with query params stripped

### 2. The link card comes with it

The layout renders the Open Graph and Twitter tags from the same three values,
so a page needs nothing more for a share on LinkedIn, Slack or an ATS to show a
card with its title, description, URL and the site card image.

Override only what is different about the page:

```slim
- content_for :og_type, "profile"             # default "website"; "article" for an article
- content_for(:og_image) { image_url("x.png") } # default the site card; 1200×630, absolute URL
```

Do not set `og_title`, `og_description` or `og_url`. They are read from the page
itself so the card and the search snippet cannot disagree.

### 3. Add JSON-LD structured data

Use `StructuredDataHelper` to inject structured data via the `:head` content block:

```slim
- content_for(:head) do
  = jsonld_tag(your_jsonld_hash)
```

`web_page_jsonld(name:, description:, url:, type: "WebPage", **extra)` already
builds a WebPage or any subtype (`CollectionPage`, `ProfilePage`,
`ContactPage`), with Mark as its `author`; `docs/system/site-pages.md` lists
which page uses which. For a shape it cannot build, add a helper method in
`app/helpers/structured_data_helper.rb`.

**Refer to Mark by `@id`; never describe him again.** The layout's graph holds
the one `Person` (`StructuredDataHelper::PERSON`, `@id`
`https://markevans.io/#mark`) on every page. Where a schema needs a person (an
`author`, a `mainEntity`, an `about`), use `PERSON`, not a new `Person` hash:

```ruby
web_page_jsonld(type: "ProfilePage", name:, description:, url:, mainEntity: PERSON)
```

Common schema types: `WebPage`, `CollectionPage`, `ProfilePage`, `ItemList`, `BlogPosting`.

Reference: [schema.org](https://schema.org)

### 4. Add the page to the sitemap

Edit the `sitemap` action in `app/controllers/home_controller.rb`. A single
page joins the list of page URLs there:

```ruby
[ projects_url, workflow_url, background_url, contact_url, your_page_url ].each do |loc|
```

Pages that come from a content file are listed from their loader, so a new
entry in the file is in the sitemap with no edit here. Projects work like this:

```ruby
Portfolio.all.each do |project|
  urlset.url do |url|
    url.loc project_url(project.key)
    url.changefreq "monthly"
    url.priority "0.6"
  end
end
```

`robots.txt` names the sitemap already (`RobotsController`), so it needs no
edit. Never add a `public/robots.txt`: it would be served instead of the route.

### 5. Add an SEO regression test

Add the page's path to `PAGES` in `test/integration/seo_test.rb`. That runs
the link-card and Person tests on it. Then assert its own description,
canonical URL and JSON-LD type in the table test there:

```ruby
"/your-page" => [ "WebPage", -> { SitePage.fetch(:your_page).description } ],
```

### 6. Verify with external tools

After deploying:
- [Google Rich Results Test](https://search.google.com/test/rich-results) — validate structured data
- [Schema Validator](https://validator.schema.org) — check JSON-LD syntax
- [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/) — see the link card, and refresh LinkedIn's cache of it
- Chrome DevTools → Lighthouse → SEO category

### 7. Update docs

Add the page's row to the JSON-LD table in `docs/system/site-pages.md`, *SEO*.

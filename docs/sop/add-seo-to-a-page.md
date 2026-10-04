# How To: Add SEO to a New Page

## Steps

### 1. Add meta description and canonical URL

In your Slim view, add `content_for` blocks at the top:

```slim
- content_for(:meta_description) { "Your page-specific description here." }
- content_for(:canonical_url) { your_page_url }
```

The layout falls back to defaults if these are not set:
- **Description:** Your app's default description
- **Canonical URL:** Current URL with query params stripped

### 2. Add Open Graph tags (for social sharing)

```slim
- content_for(:og_title) { "Page Title" }
- content_for(:og_description) { "Description for social cards." }
- content_for(:og_image) { "https://example.com/image.jpg" }
- content_for(:og_url) { your_page_url }
```

### 3. Add JSON-LD structured data

Use `StructuredDataHelper` to inject structured data via the `:head` content block:

```slim
- content_for(:head) do
  = jsonld_tag(your_jsonld_hash)
```

`web_page_jsonld(name:, description:, url:, type: "WebPage", **extra)` already
builds a WebPage or any subtype (`CollectionPage`, `ProfilePage`,
`ContactPage`); `docs/system/site-pages.md` lists which page uses which. For a
shape it cannot build, add a helper method in `app/helpers/structured_data_helper.rb`:

```ruby
def your_page_jsonld(args)
  {
    "@context" => "https://schema.org",
    "@type" => "WebPage",
    "name" => "Page Title",
    "url" => your_page_url,
    "description" => "Page description."
  }
end
```

Common schema types: `WebPage`, `CollectionPage`, `ProfilePage`, `ItemList`, `Person`, `Product`.

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

Priority guide: 1.0 (homepage), 0.8 (primary content), 0.6 (browse/discover), 0.3 (static pages).

### 5. Add an SEO regression test

Add assertions to `test/integration/seo_test.rb`:

```ruby
test "your page includes SEO meta tags" do
  get your_page_url
  assert_response :success
  assert_select 'meta[name="description"]', true
  assert_select 'link[rel="canonical"]', true
end

test "your page includes JSON-LD" do
  get your_page_url
  assert_json_ld("WebPage")  # or your schema type
end
```

### 6. Verify with external tools

After deploying:
- [Google Rich Results Test](https://search.google.com/test/rich-results) — validate structured data
- [Schema Validator](https://validator.schema.org) — check JSON-LD syntax
- Chrome DevTools → Lighthouse → SEO category

### 7. Update docs

Update your SEO strategy doc if the page introduces a new schema type or content category.

# frozen_string_literal: true

module StructuredDataHelper
  # Mark, as every page's JSON-LD names him. An identifier, not a link built
  # from the request: the same in every environment, so search engines tie
  # the whole site to one entity (docs/system/site-pages.md, SEO).
  PERSON_ID = "https://markevans.io/#mark"
  PERSON = { "@id" => PERSON_ID }.freeze

  # Renders a <script type="application/ld+json"> tag with the given hash.
  #
  # Usage in Slim views:
  #   - content_for(:head) do
  #     = jsonld_tag(your_schema_hash)
  #
  # See docs/sop/add-seo-to-a-page.md for the full pattern.
  def jsonld_tag(data)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  # The layout's graph, on every page: the WebSite and the one Person, Mark,
  # with the https profiles /background links to. A link still to be written
  # is left out. Pages refer to the Person by PERSON_ID and never describe
  # him again.
  def site_jsonld(profile)
    same_as = profile.links.reject(&:placeholder?).map(&:url).select { |url| url.start_with?("https://") }
    { "@context" => "https://schema.org", "@graph" => [
      { "@type" => "WebSite", "name" => "Mark Evans", "url" => root_url, "publisher" => PERSON },
      { "@type" => "Person", "@id" => PERSON_ID, "name" => "Mark Evans", "url" => root_url, "sameAs" => same_as }
    ] }
  end

  # A page of the site as schema.org sees it: WebPage, or a subtype such as
  # CollectionPage, ProfilePage or ContactPage, written by Mark. Extra keys are
  # merged in.
  def web_page_jsonld(name:, description:, url:, type: "WebPage", **extra)
    { "@context" => "https://schema.org", "@type" => type, "name" => name, "description" => description, "url" => url,
      "author" => PERSON }.merge(extra.transform_keys(&:to_s))
  end

  # /work: a CollectionPage whose main entity lists each project, in order.
  def project_list_jsonld(page, projects)
    items = projects.each_with_index.map do |project, index|
      { "@type" => "ListItem", "position" => index + 1, "name" => project.name, "url" => project_url(project.key) }
    end
    web_page_jsonld(type: "CollectionPage", name: page.title, description: page.description, url: projects_url,
      mainEntity: { "@type" => "ItemList", "itemListElement" => items })
  end

  # /background: a ProfilePage about Mark, the layout's Person.
  def profile_jsonld(page)
    web_page_jsonld(type: "ProfilePage", name: page.title, description: page.description, url: background_url, mainEntity: PERSON)
  end

  # Converts milliseconds to ISO 8601 duration (e.g., "PT3M45S").
  # Useful for MusicRecording, Video, Recipe, and other schema types.
  def iso8601_duration(ms)
    total_seconds = ms / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "PT#{minutes}M#{seconds}S"
  end
end

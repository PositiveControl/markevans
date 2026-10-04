# frozen_string_literal: true

module StructuredDataHelper
  # Renders a <script type="application/ld+json"> tag with the given hash.
  #
  # Usage in Slim views:
  #   - content_for(:head) do
  #     = jsonld_tag(your_schema_hash)
  #
  # See docs/how-tos/add-seo-to-a-page.md for the full pattern.
  def jsonld_tag(data)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  # A page of the site as schema.org sees it: WebPage, or a subtype such as
  # CollectionPage, ProfilePage or ContactPage. Extra keys are merged in.
  def web_page_jsonld(name:, description:, url:, type: "WebPage", **extra)
    { "@context" => "https://schema.org", "@type" => type, "name" => name, "description" => description, "url" => url }
      .merge(extra.transform_keys(&:to_s))
  end

  # /work: a CollectionPage whose main entity lists each project, in order.
  def project_list_jsonld(page, projects)
    items = projects.each_with_index.map do |project, index|
      { "@type" => "ListItem", "position" => index + 1, "name" => project.name, "url" => project_url(project.key) }
    end
    web_page_jsonld(type: "CollectionPage", name: page.title, description: page.description, url: projects_url,
      mainEntity: { "@type" => "ItemList", "itemListElement" => items })
  end

  # /background: a ProfilePage about Mark, linked to the profiles the page
  # links to. A link still to be written is left out.
  def profile_jsonld(page)
    person = { "@type" => "Person", "name" => "Mark Evans", "url" => root_url,
      "sameAs" => page.links.reject(&:placeholder?).map(&:url).select { |url| url.start_with?("https://") } }
    web_page_jsonld(type: "ProfilePage", name: page.title, description: page.description, url: background_url, mainEntity: person)
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

# frozen_string_literal: true

require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  test "homepage includes meta description" do
    get root_url
    assert_select 'meta[name="description"]', true, "Missing meta description"
  end

  test "homepage includes canonical URL" do
    get root_url
    assert_select 'link[rel="canonical"]', true, "Missing canonical URL"
  end

  test "homepage includes WebSite JSON-LD" do
    get root_url
    assert_json_ld("WebSite")
  end

  test "sitemap returns valid XML" do
    get sitemap_url(format: :xml)
    assert_response :success
    assert_includes response.content_type, "xml"
    assert_includes response.body, "<urlset"
  end

  test "the sitemap lists every page and every project" do
    get sitemap_url(format: :xml)

    [ projects_url, workflow_url, background_url, contact_url ].each { |url| assert_includes response.body, "<loc>#{url}</loc>" }
    Portfolio.all.each { |project| assert_includes response.body, "<loc>#{project_url(project.key)}</loc>" }
  end

  {
    "/work" => [ "CollectionPage", -> { SitePage.fetch(:work).description } ],
    "/work/rails-rocket-sheep" => [ "WebPage", -> { Portfolio.fetch("rails-rocket-sheep").summary } ],
    "/workflow" => [ "WebPage", -> { SitePage.fetch(:workflow).description } ],
    "/background" => [ "ProfilePage", -> { SitePage.fetch(:background).description } ],
    "/contact" => [ "ContactPage", -> { SitePage.fetch(:contact).description } ]
  }.each do |path, (type, description)|
    test "#{path} has its own meta description, canonical URL and #{type} JSON-LD" do
      get path

      assert_response :success
      assert_select 'meta[name="description"][content=?]', instance_exec(&description).truncate(155, separator: " ")
      assert_select 'link[rel="canonical"][href=?]', "http://www.example.com#{path}"
      assert_json_ld(type)
    end
  end

  test "/work's JSON-LD lists each project, in the page's order" do
    get projects_url

    list = json_ld("CollectionPage").dig("mainEntity", "itemListElement")
    assert_equal Portfolio.grouped.flat_map(&:last).map { |project| project_url(project.key) }, list.map { |item| item["url"] }
    assert_equal (1..Portfolio.all.size).to_a, list.map { |item| item["position"] }
  end

  test "/work's JSON-LD lists every project even when the page is filtered, as its canonical URL does" do
    get projects_url(tag: "Swift")

    list = json_ld("CollectionPage").dig("mainEntity", "itemListElement")
    assert_equal Portfolio.all.size, list.size
    assert_select "link[rel=canonical][href=?]", projects_url
  end

  test "/background's JSON-LD is a Person with the profiles the page links to, and no placeholder" do
    get background_url

    person = json_ld("ProfilePage")["mainEntity"]
    assert_equal "Person", person["@type"]
    assert_equal "Mark Evans", person["name"]
    links = SitePage.fetch(:background).links.reject(&:placeholder?).map(&:url)
    assert_equal links.select { |url| url.start_with?("https://") }, person["sameAs"]
    assert_includes person["sameAs"], "https://github.com/PositiveControl"
    assert person["sameAs"].none? { |url| url.start_with?("mailto:") }
  end

  test "every written page and project description fits a search snippet whole, so none reads as cut off" do
    descriptions = SitePage.all.map { |page| [ page.title, page.description ] } + Portfolio.all.map { |project| [ project.name, project.summary ] }

    descriptions.reject { |_, text| text.start_with?("[") }.each do |name, text|
      assert_operator text.length, :<=, 155, "#{name}'s description is #{text.length} characters; the meta tag cuts it at 155"
    end
  end

  test "robots.txt names the sitemap on the host it was asked for, so it cannot point at another" do
    get "/robots.txt"

    assert_response :success
    assert_includes response.content_type, "text/plain"
    assert_includes response.body.lines.map(&:chomp), "Sitemap: http://www.example.com/sitemap.xml"

    host! "markevans.io"
    get "/robots.txt"
    assert_includes response.body.lines.map(&:chomp), "Sitemap: http://markevans.io/sitemap.xml"
  end

  test "robots.txt allows the site and keeps the account and admin paths out" do
    get "/robots.txt"

    lines = response.body.lines.map(&:chomp)
    [ "User-agent: *", "Allow: /", "Disallow: /admin/", "Disallow: /api/", "Disallow: /users/sign_in", "Disallow: /users/sign_up" ]
      .each { |line| assert_includes lines, line }
  end

  test "robots.txt comes from the route alone: no static file shadows it" do
    assert_not Rails.public_path.join("robots.txt").exist?
  end

  private

  def json_ld(type)
    css_select('script[type="application/ld+json"]').map { |script| JSON.parse(script.text) }.find { |data| data["@type"] == type }
  end

  def assert_json_ld(expected_type)
    scripts = css_select('script[type="application/ld+json"]')
    assert scripts.any?, "Expected at least one JSON-LD script tag"

    found = scripts.any? do |script|
      data = JSON.parse(script.text)
      data["@type"] == expected_type
    rescue JSON::ParserError
      false
    end

    assert found, "Expected JSON-LD with @type '#{expected_type}'"
  end
end

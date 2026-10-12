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
    assert_equal root_url, graph_node("WebSite")["url"]
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

  PAGES = %w[/ /work /work/rails-rocket-sheep /workflow /background /contact].freeze
  PERSON = { "@id" => "https://markevans.io/#mark" }.freeze

  PAGES.each do |path|
    test "#{path} carries the one Person, with the profiles /background links to and no placeholder" do
      get path

      person = graph_node("Person")
      assert_equal PERSON["@id"], person["@id"]
      assert_equal "Mark Evans", person["name"]
      links = SitePage.fetch(:background).links.reject(&:placeholder?).map(&:url)
      assert_equal links.select { |url| url.start_with?("https://") }, person["sameAs"]
      assert_includes person["sameAs"], "https://github.com/PositiveControl"
      assert person["sameAs"].any? { |url| url.start_with?("https://www.linkedin.com/") }
      assert_equal PERSON, graph_node("WebSite")["publisher"]
    end
  end

  PAGES.drop(1).each do |path|
    test "#{path}'s own JSON-LD refers to the Person by @id and never describes Mark again" do
      get path

      page = page_json_ld
      assert_equal PERSON, page["author"]
      assert_equal [ PERSON["@id"] ], json_ld_scripts.flat_map { |data| people(data) }.map { |person| person["@id"] }.uniq
      assert_equal 1, json_ld_scripts.sum { |data| people(data).count { |person| person.key?("name") } }
    end
  end

  PAGES.each do |path|
    test "#{path} has a link card: its own title, description and canonical URL, and the site card image" do
      get path

      assert_equal css_select("title").first.text, og("og:title")
      assert_equal css_select('meta[name="description"]').first["content"], og("og:description")
      assert_equal css_select('link[rel="canonical"]').first["href"], og("og:url")
      assert_equal "Mark Evans", og("og:site_name")
      assert_match %r{\Ahttp://www\.example\.com/assets/card-\h+\.png\z}, og("og:image")
      assert_equal %w[1200 630], [ og("og:image:width"), og("og:image:height") ]
      assert og("og:image:alt").present?
      assert_select 'meta[name="twitter:card"][content="summary_large_image"]'
    end
  end

  test "a page is a website to a link card unless it says otherwise" do
    get projects_url
    assert_equal "website", og("og:type")
  end

  test "a page can override its link card: /background is a profile" do
    get background_url
    assert_equal "profile", og("og:type")
    assert_select 'meta[property="og:type"]', count: 1
  end

  test "the Person's job title and what Mark knows about come from /contact's content" do
    person = SitePage.fetch(:contact).person
    get root_url

    node = graph_node("Person")
    assert_equal person.job_title, node["jobTitle"]
    assert_equal person.knows_about, node["knowsAbout"]
    assert_equal "Senior Software Engineer", node["jobTitle"]
    [ "Ruby on Rails", "AI engineering", "LLM integration", "Agent harness engineering", "Deterministic guardrails" ]
      .each { |term| assert_includes node["knowsAbout"], term }
  end

  test "/contact's main entity is the Person, by @id" do
    get contact_url

    assert_equal PERSON, json_ld("ContactPage")["mainEntity"]
  end

  test "a project page with a repository is about its SoftwareSourceCode: the repository, its languages and its stack" do
    project = Portfolio.fetch("rails-rocket-sheep")
    get project_url(project.key)

    code = json_ld("WebPage")["mainEntity"]
    assert_equal "SoftwareSourceCode", code["@type"]
    assert_equal project.name, code["name"]
    assert_equal project.repository.url, code["codeRepository"]
    assert_equal [ "Ruby" ], code["programmingLanguage"]
    assert_equal project.tags, code["keywords"]
    assert_includes code["keywords"], "Rails"
    assert_equal PERSON, code["author"]
  end

  test "programmingLanguage holds every language a project is written in, and only languages" do
    get project_url("kram")

    assert_equal %w[Go OpenQASM], json_ld("WebPage").dig("mainEntity", "programmingLanguage")
  end

  test "a project page with no repository is a plain WebPage with no SoftwareSourceCode" do
    get project_url("idlempire")

    assert_nil json_ld("WebPage")["mainEntity"]
    assert_not_includes response.body, "SoftwareSourceCode"
  end

  test "/background's main entity is the Person, by @id" do
    get background_url

    assert_equal PERSON, json_ld("ProfilePage")["mainEntity"]
  end

  test "every written page and project description fits a search snippet whole, so none reads as cut off" do
    home = DeliveryThread.fetch(:home)
    descriptions = [ [ home.page_title, home.description ] ] +
      SitePage.all.map { |page| [ page.title, page.description ] } + Portfolio.all.map { |project| [ project.name, project.summary ] }

    descriptions.reject { |_, text| text.start_with?("[") }.each do |name, text|
      assert_operator text.length, :<=, 155, "#{name}'s description is #{text.length} characters; the meta tag cuts it at 155"
    end
  end

  {
    "/" => -> { DeliveryThread.fetch(:home).page_title },
    "/background" => -> { SitePage.fetch(:background).page_title },
    "/contact" => -> { SitePage.fetch(:contact).page_title },
    "/workflow" => -> { SitePage.fetch(:workflow).page_title }
  }.each do |path, page_title|
    test "#{path}'s <title> is its page_title from content, not its heading" do
      get path

      expected = instance_exec(&page_title)
      assert expected.present?, "#{path} has no page_title"
      assert_equal expected, css_select("title").first.text
    end
  end

  test "home, Background and Contact name the role in their title and description; Workflow names AI coding agents" do
    home = DeliveryThread.fetch(:home)
    pages = { home: home, background: SitePage.fetch(:background), contact: SitePage.fetch(:contact) }

    pages.each do |key, page|
      assert_match(/Rails/, page.page_title, "#{key}'s title")
      assert_match(/\bAI\b/, page.page_title, "#{key}'s title")
      assert_match(/Ruby on Rails/, page.description, "#{key}'s description")
    end
    assert_match(/AI Engineer, Ruby on Rails/, pages[:contact].page_title)
    assert_match(/positive control/, home.description)
    assert_match(/AI coding agents/, SitePage.fetch(:workflow).page_title)
    assert_match(/AI coding agents/, SitePage.fetch(:workflow).description)
  end

  test "no page's <title> runs past 60 characters, where search results cut it" do
    (PAGES + [ "/work/#{Portfolio.all.max_by { |project| project.name.length }.key}" ]).each do |path|
      get path

      title = css_select("title").first.text
      assert_operator title.length, :<=, 60, "#{path}'s title is #{title.length} characters"
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

  def og(property) = css_select("meta[property=\"#{property}\"]").first&.[]("content")

  def json_ld_scripts = css_select('script[type="application/ld+json"]').map { |script| JSON.parse(script.text) }

  def json_ld(type) = json_ld_scripts.find { |data| data["@type"] == type }

  # The layout's graph: the WebSite and the Person every page refers to.
  def graph_node(type) = json_ld_scripts.flat_map { |data| Array(data["@graph"]) }.find { |node| node["@type"] == type }

  # The page's own JSON-LD: the one script that is not the layout's graph.
  def page_json_ld
    pages = json_ld_scripts.reject { |data| data.key?("@graph") }
    assert_equal 1, pages.size
    pages.first
  end

  # Every node anywhere in the data that is, or refers to, a Person.
  def people(data)
    case data
    when Hash
      own = data["@type"] == "Person" || data == PERSON ? [ data ] : []
      own + data.values.flat_map { |value| people(value) }
    when Array then data.flat_map { |value| people(value) }
    else []
    end
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

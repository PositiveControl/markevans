require "test_helper"

class SitePageTest < ActiveSupport::TestCase
  test "fetch loads a page from content/pages" do
    page = SitePage.fetch(:contact)

    assert_equal "contact", page.key
    assert_equal "Contact", page.title
    assert_kind_of SitePage::Link, page.links.first
  end

  test "every page in content/pages loads" do
    assert_equal %w[background contact workflow], SitePage.all.map(&:key)
  end

  test "sections carry their heading, paragraphs and groups of rows as values" do
    page = load_page(minimal)
    section = page.sections.first

    assert_equal "Experience", section.heading
    assert_equal [ "A paragraph." ], section.paragraphs
    assert_kind_of SitePage::Group, section.groups.first
    assert_equal "Role", section.groups.first.rows.first.key
    assert_equal "Company", section.groups.first.rows.first.value
  end

  test "a loaded page is frozen all the way down" do
    page = load_page(minimal)

    assert page.sections.frozen?
    assert page.sections.first.paragraphs.frozen?
    assert page.sections.first.groups.first.rows.frozen?
    assert page.links.frozen?
    assert page.intro.frozen?
  end

  test "links and sections are empty when the page has none" do
    data = minimal.except("links", "sections")

    assert_equal [], load_page(data).links
    assert_equal [], load_page(data).sections
  end

  test "a link to a [placeholder] is a placeholder; an https or mailto link is not" do
    assert SitePage::Link.new(label: "Email", url: "[mailto:address]").placeholder?
    assert_not SitePage::Link.new(label: "Email", url: "mailto:a@example.com").placeholder?
    assert_not SitePage::Link.new(label: "GitHub", url: "https://github.com/x").placeholder?
  end

  test "an unknown page raises KeyError, and a path reaches no file" do
    assert_raises(KeyError) { SitePage.fetch(:nope) }
    assert_raises(KeyError) { SitePage.fetch("../work") }
  end

  test "missing title, description or intro are each reported" do
    error = assert_invalid(/missing title/) { |data| data.except!("title", "description", "intro") }

    assert_match(/missing description/, error.message)
    assert_match(/missing intro/, error.message)
  end

  test "an unknown key is reported" do
    assert_invalid(/unknown key headline/) { |data| data["headline"] = "x" }
  end

  test "a link needs a label and a url that is https, mailto or a placeholder" do
    assert_invalid(/links\[1\] needs a label and a url/) { |data| data["links"] = [ { "label" => "x" } ] }
    assert_invalid(/links\[1\]: url must start https/) { |data| data["links"] = [ { "label" => "x", "url" => "http://x" } ] }
    assert_invalid(/links\[1\]: url must start https/) { |data| data["links"] = [ { "label" => "x", "url" => "javascript:alert(1)" } ] }
  end

  test "a section needs a heading, and paragraphs or groups" do
    assert_invalid(/sections\[1\]: missing heading/) { |data| data["sections"].first.delete("heading") }
    assert_invalid(/sections\[1\]: needs paragraphs or groups/) { |data| data["sections"] = [ { "heading" => "Empty" } ] }
  end

  test "paragraphs must be text, and a group's rows need k and v" do
    assert_invalid(/paragraphs must be a list of text/) { |data| data["sections"].first["paragraphs"] = [ "" ] }
    assert_invalid(/groups\[1\].rows\[1\] needs k and v/) { |data| data["sections"].first["groups"].first["rows"] = [ { "k" => "x" } ] }
  end

  private

  def minimal
    { "title" => "Background", "description" => "Who.", "intro" => "Intro.",
      "links" => [ { "label" => "GitHub", "url" => "https://github.com/PositiveControl" } ],
      "sections" => [ { "heading" => "Experience", "paragraphs" => [ "A paragraph." ],
        "groups" => [ { "title" => "Years", "rows" => [ { "k" => "Role", "v" => "Company" } ] } ] } ] }
  end

  def load_page(data)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "broken.yml")
      File.write(path, data.to_yaml)
      SitePage.load(path)
    end
  end

  def assert_invalid(pattern)
    data = minimal.deep_dup
    yield data
    error = assert_raises(SitePage::Invalid) { load_page(data) }
    assert_match pattern, error.message
    error
  end
end

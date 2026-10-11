require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "all lists the eight projects in the file's order" do
    assert_equal %w[rails-rocket-sheep idlempire harness kram dailydrop spamsandwich slowpoke-rb myrelay], Portfolio.all.map(&:key)
  end

  test "grouped lists each category in its fixed order, its projects in the file's order" do
    groups = Portfolio.grouped

    assert_equal Portfolio::CATEGORIES, groups.map(&:first)
    assert_equal %w[rails-rocket-sheep harness slowpoke-rb myrelay], groups.first.last.map(&:key)
    assert_equal Portfolio.all.sort_by(&:key), groups.flat_map(&:last).sort_by(&:key)
  end

  test "grouped with a tag keeps only the projects carrying it, and drops empty categories" do
    groups = Portfolio.grouped(tag: "Swift")

    assert_equal [ [ "Applications", %w[dailydrop] ] ], groups.map { |category, projects| [ category, projects.map(&:key) ] }
  end

  test "tags lists every tag in use once, languages first, in registry order" do
    tags = Portfolio.tags

    assert_equal tags.uniq, tags
    assert_equal Portfolio.all.flat_map(&:tags).uniq.sort, tags.sort
    assert_equal StackRegistry.all.map(&:name) & tags, tags
  end

  test "a category outside the fixed set, or none, is reported" do
    assert_invalid(/one: category must be one of AI and Tooling, Applications, Languages and Compilers/) { |data| data["projects"].first["category"] = "Hobbies" }
    assert_invalid(/one: missing category/) { |data| data["projects"].first.delete("category") }
  end

  test "tags are an optional list of short words, in the file's order" do
    assert_equal %w[Ruby Rails Swift iOS], Portfolio.fetch("dailydrop").tags.first(4)
    assert_equal [], load_projects(minimal).first.tags
    assert_invalid(/one: tags must be a list of words/) { |data| data["projects"].first["tags"] = "Ruby" }
    assert_invalid(/one: tags must be a list of words/) { |data| data["projects"].first["tags"] = [ "Ruby", "" ] }
    assert_invalid(/one: tag COBOL is not in StackRegistry/) { |data| data["projects"].first["tags"] = [ "COBOL" ] }
  end

  test "fetch finds a project by its key, with sections and links as values" do
    project = Portfolio.fetch("rails-rocket-sheep")

    assert_equal "rails-rocket-sheep", project.name
    assert_kind_of SitePage::Link, project.links.first
    assert_kind_of SitePage::Section, project.sections.first
  end

  test "an unknown key raises NotFound" do
    assert_raises(Portfolio::NotFound) { Portfolio.fetch("nope") }
  end

  test "a loaded list is frozen all the way down" do
    projects = load_projects(minimal)

    assert projects.frozen?
    assert projects.first.summary.frozen?
    assert projects.first.sections.frozen?
  end

  test "missing key, name or summary are each reported, under the project's key" do
    error = assert_invalid(/one: missing name/) { |data| data["projects"].first.except!("name", "summary") }

    assert_match(/one: missing summary/, error.message)
  end

  test "a key used twice is reported" do
    assert_invalid(/one: key used by more than one project/) { |data| data["projects"] << data["projects"].first.dup }
  end

  test "a key must be fit for a URL" do
    assert_invalid(/key must be lowercase letters/) { |data| data["projects"].first["key"] = "Has Space" }
    assert_invalid(/key must be lowercase letters/) { |data| data["projects"].first["key"] = "../x" }
  end

  test "an unknown key on a project or at the top is reported" do
    assert_invalid(/one: unknown key labels/) { |data| data["projects"].first["labels"] = "x" }
    assert_invalid(/unknown top-level key title/) { |data| data["title"] = "x" }
  end

  test "links and sections are checked as a page's are" do
    assert_invalid(/one: links\[1\]: url must start https/) { |data| data["projects"].first["links"] = [ { "label" => "x", "url" => "ftp://x" } ] }
    assert_invalid(/one: sections\[1\]: missing heading/) { |data| data["projects"].first["sections"] = [ { "paragraphs" => [ "x" ] } ] }
  end

  test "a file with no projects is refused" do
    assert_invalid(/no projects/) { |data| data["projects"] = [] }
    assert_invalid(/a list of projects/) { |data| data.delete("projects") }
  end

  private

  def minimal
    { "projects" => [ { "key" => "one", "name" => "One", "summary" => "The first.", "category" => "Applications" } ] }
  end

  def load_projects(data)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "work.yml")
      File.write(path, data.to_yaml)
      Portfolio.load(path)
    end
  end

  def assert_invalid(pattern)
    data = minimal.deep_dup
    yield data
    error = assert_raises(Portfolio::Invalid) { load_projects(data) }
    assert_match pattern, error.message
    error
  end
end

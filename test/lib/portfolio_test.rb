require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "all lists the six projects in the file's order" do
    assert_equal %w[rails-rocket-sheep idlempire harness kram dailydrop spamsandwich], Portfolio.all.map(&:key)
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
    assert_invalid(/one: unknown key tags/) { |data| data["projects"].first["tags"] = "x" }
    assert_invalid(/unknown top-level key title/) { |data| data["title"] = "x" }
  end

  test "links and sections are checked as a page's are" do
    assert_invalid(/one: links\[1\]: url must start https/) { |data| data["projects"].first["links"] = [ { "label" => "x", "url" => "ftp://x" } ] }
    assert_invalid(/one: sections\[1\]: missing heading/) { |data| data["projects"].first["sections"] = [ { "paragraphs" => [ "x" ] } ] }
  end

  test "findings are read into values, in the file's order, with any evidence as a link" do
    data = minimal
    data["projects"].first["findings"] = [
      finding("surprise", "evidence" => { "label" => "PR #1", "url" => "https://example.com/1" }),
      finding("takeaway")
    ]
    findings = load_projects(data).first.findings

    assert_equal %w[surprise takeaway], findings.map(&:kind)
    assert_equal [ "A surprise.", "Body of a surprise." ], [ findings.first.title, findings.first.body ]
    assert_equal SitePage::Link.new(label: "PR #1", url: "https://example.com/1"), findings.first.evidence
    assert_nil findings.last.evidence
    assert findings.frozen?
  end

  test "a project without findings has none" do
    assert_equal [], load_projects(minimal).first.findings
  end

  test "a finding's kind must be one of the three" do
    assert_invalid(/one: findings\[1\]: kind must be learning, surprise or takeaway/) { |data| data["projects"].first["findings"] = [ finding("insight") ] }
    assert_invalid(/one: findings\[1\]: kind must be/) { |data| data["projects"].first["findings"] = [ finding("learning").except("kind") ] }
  end

  test "a finding without a title or body is reported, each once" do
    error = assert_invalid(/one: findings\[1\]: missing title/) { |data| data["projects"].first["findings"] = [ finding("learning", "title" => " ").except("body") ] }

    assert_match(/one: findings\[1\]: missing body/, error.message)
  end

  test "an unknown key on a finding is reported, step included until findings pin to a thread" do
    assert_invalid(/one: findings\[1\]: unknown key step/) { |data| data["projects"].first["findings"] = [ finding("learning", "step" => "implement") ] }
  end

  test "a finding's evidence is checked as a link is" do
    assert_invalid(/one: findings\[1\]\.evidence: url must start https/) { |data| data["projects"].first["findings"] = [ finding("learning", "evidence" => { "label" => "x", "url" => "ftp://x" }) ] }
    assert_invalid(/one: findings\[1\]\.evidence needs a label and a url/) { |data| data["projects"].first["findings"] = [ finding("learning", "evidence" => "https://x") ] }
  end

  test "findings must be a list of mappings" do
    assert_invalid(/one: findings must be a list/) { |data| data["projects"].first["findings"] = "x" }
    assert_invalid(/one: findings\[2\]: must be a mapping/) { |data| data["projects"].first["findings"] = [ finding("learning"), "x" ] }
  end

  test "a file with no projects is refused" do
    assert_invalid(/no projects/) { |data| data["projects"] = [] }
    assert_invalid(/a list of projects/) { |data| data.delete("projects") }
  end

  private

  def minimal
    { "projects" => [ { "key" => "one", "name" => "One", "summary" => "The first." } ] }
  end

  def finding(kind, **extra)
    { "kind" => kind, "title" => "A #{kind}.", "body" => "Body of a #{kind}." }.merge(extra.transform_keys(&:to_s))
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

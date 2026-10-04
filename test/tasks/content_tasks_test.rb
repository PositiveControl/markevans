require "test_helper"
require "rake"

class ContentTasksTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["content:placeholders"]
    @task.reenable
    @root = Dir.mktmpdir
  end

  teardown do
    FileUtils.rm_rf(@root)
  end

  test "passes when content has no placeholders" do
    write "threads/home.yml", "title: \"Shipped\"\n"

    assert_output(/no placeholders/) { run_task }
  end

  test "fails on a square-bracket placeholder, naming file and line" do
    write "threads/home.yml", "title: \"Shipped\"\nnote: \"[Your note]\"\n"

    _, err = capture_io { assert_raises(SystemExit) { run_task } }
    assert_includes err, "threads/home.yml:2: [Your note]"
  end

  test "fails on TBD" do
    write "work/kram.md", "Outcome TBD.\n"

    _, err = capture_io { assert_raises(SystemExit) { run_task } }
    assert_includes err, "work/kram.md:1: TBD"
  end

  test "a markdown link is not a placeholder" do
    write "work/kram.md", "See [the repo](https://example.com).\n"

    assert_output(/no placeholders/) { run_task }
  end

  test "markdown checkboxes and reference links are not placeholders" do
    write "work/kram.md", "- [ ] ship it\n- [x] plan it\nSee [the repo][1].\n\n[1]: https://example.com\n"

    assert_output(/no placeholders/) { run_task }
  end

  test "a placeholder beside a markdown link is still found" do
    write "work/kram.md", "See [the repo](https://example.com), shipped in [n] days.\n"

    _, err = capture_io { assert_raises(SystemExit) { run_task } }
    assert_includes err, "work/kram.md:1: [n]"
  end

  test "content:check fails the build on a thread that breaks the schema" do
    write "threads/home.yml", { "id" => "home", "title" => "Home", "steps" => [] }.to_yaml.sub("steps: []", "steps: [ 1 ]")
    check = Rake::Task["content:check"]
    check.reenable
    Rake::Task["content:schema"].reenable

    _, err = capture_io { assert_raises(SystemExit) { with_root { check.invoke } } }
    assert_includes err, "home.yml: step 1: must be a mapping"
  end

  test "content:check passes a valid thread with no placeholders" do
    FileUtils.mkdir_p(File.join(@root, "threads"))
    FileUtils.cp(Rails.root.join("content/threads/home.yml"), File.join(@root, "threads/home.yml"))
    File.write(File.join(@root, "threads/home.yml"), File.read(File.join(@root, "threads/home.yml")).gsub(/\[[^\]\n]+\]|\bTBD\b/, "x"))
    %w[content:check content:schema].each { |name| Rake::Task[name].reenable }

    assert_output(/threads: 1 valid.*no placeholders/m) { with_root { Rake::Task["content:check"].invoke } }
  end

  test "content:schema fails on a work list or a page that breaks its schema, naming the file" do
    write "work.yml", { "projects" => [ { "key" => "Bad Key", "name" => "x", "summary" => "x" } ] }.to_yaml
    write "pages/contact.yml", { "title" => "Contact" }.to_yaml
    schema = Rake::Task["content:schema"]
    schema.reenable

    _, err = capture_io { assert_raises(SystemExit) { with_root { schema.invoke } } }
    assert_includes err, "work.yml: Bad Key: key must be lowercase letters"
    assert_includes err, "contact.yml: missing description"
  end

  test "content:schema passes the work list and pages as they ship" do
    FileUtils.cp_r(Rails.root.join("content/."), @root)
    schema = Rake::Task["content:schema"]
    schema.reenable

    assert_output(/threads: 1 valid, work: 1 valid, pages: 4 valid/) { with_root { schema.invoke } }
  end

  private

  def with_root
    ENV["CONTENT_ROOT"] = @root
    yield
  ensure
    ENV.delete("CONTENT_ROOT")
  end

  def write(path, text)
    FileUtils.mkdir_p(File.dirname(File.join(@root, path)))
    File.write(File.join(@root, path), text)
  end

  def run_task
    ENV["CONTENT_ROOT"] = @root
    @task.invoke
  ensure
    ENV.delete("CONTENT_ROOT")
  end
end

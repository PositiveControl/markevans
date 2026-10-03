require "test_helper"
require "rake"

class ContentPlaceholdersTest < ActiveSupport::TestCase
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

  private

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

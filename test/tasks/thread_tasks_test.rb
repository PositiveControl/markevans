require "test_helper"
require "rake"

class ThreadTasksTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["thread:export"]
    @root = Dir.mktmpdir
    @out = File.join(@root, "out/thread.html")
    @content = File.join(@root, "content")
    FileUtils.mkdir_p(@content)
    # The stylesheet is already built for the suite, and rebuilding it would
    # rewrite a file other workers read; the export is what is under test.
    @prerequisites = @task.prerequisites.dup
    @task.prerequisites.delete("tailwindcss:build")
    @task.reenable
  end

  teardown do
    @task.prerequisites.replace(@prerequisites)
    FileUtils.rm_rf(@root)
  end

  test "writes the page to OUT, making the directory it needs" do
    out, = capture_io { run_task }

    assert_includes File.read(@out), DeliveryThread.fetch(:home).headline
    assert_includes out, "wrote #{@out}"
  end

  test "a placeholder in a thread is reported, and the file is written anyway" do
    write "threads/home.yml", "title: \"[example TBD]\"\n"

    _, err = capture_io { run_task }

    assert_includes err, "home.yml:1: [example TBD]"
    assert_includes err, "writing it anyway"
    assert File.exist?(@out)
  end

  test "content the page does not show is left to content:check" do
    write "work.yml", "role: \"[Your role]\"\n"

    out, err = capture_io { run_task }

    assert_includes out, "no placeholders"
    assert_empty err
  end

  test "builds the stylesheet first, so the file matches the views" do
    assert_includes @prerequisites, "tailwindcss:build"
  end

  private

  def write(path, text)
    FileUtils.mkdir_p(File.dirname(File.join(@content, path)))
    File.write(File.join(@content, path), text)
  end

  def run_task
    with_env("OUT" => @out, "CONTENT_ROOT" => @content) { @task.invoke }
  end

  def with_env(values)
    saved = values.keys.to_h { |key| [ key, ENV[key] ] }
    ENV.update(values)
    yield
  ensure
    ENV.update(saved)
  end
end

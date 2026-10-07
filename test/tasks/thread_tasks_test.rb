require "test_helper"
require "rake"

class ThreadTasksTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["thread:export"]
    @root = Dir.mktmpdir
    @out = File.join(@root, "out/thread.html")
    @content = File.join(@root, "content")
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

  test "scans the threads the page renders, not CONTENT_ROOT, and writes the file anyway on a placeholder" do
    scanned = nil
    with_placeholder_scan(-> { scanned = ENV["CONTENT_ROOT"]; warn "home.yml:1: [example TBD]"; exit 1 }) do
      _, err = capture_io { run_task }

      assert_includes err, "home.yml:1: [example TBD]"
      assert_includes err, "writing it anyway"
      assert_equal @content, ENV["CONTENT_ROOT"], "CONTENT_ROOT not put back"
    end

    assert_equal DeliveryThread::ROOT.to_s, scanned
    assert File.exist?(@out)
  end

  test "builds the stylesheet first, so the file matches the views" do
    assert_includes @prerequisites, "tailwindcss:build"
  end

  private

  # Swaps content:placeholders' body for the block, so the test controls what
  # it finds; the real scan has its own tests in content_tasks_test.rb.
  def with_placeholder_scan(scan)
    task = Rake::Task["content:placeholders"]
    actions = task.actions.dup
    begin
      task.actions.replace([ ->(*) { scan.call } ])
      with_env("CONTENT_ROOT" => @content) { yield }
    ensure
      task.actions.replace(actions)
    end
  end

  def run_task
    with_env("OUT" => @out) { @task.invoke }
  end

  def with_env(values)
    saved = values.keys.to_h { |key| [ key, ENV[key] ] }
    ENV.update(values)
    yield
  ensure
    ENV.update(saved)
  end
end

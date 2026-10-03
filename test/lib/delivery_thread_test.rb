require "test_helper"

class DeliveryThreadTest < ActiveSupport::TestCase
  test "fetch loads the home thread" do
    thread = DeliveryThread.fetch(:home)

    assert_equal "home", thread.id
    assert_equal 15, thread.steps.size
    assert_equal "pick", thread.steps.first.key
    assert_equal "deploy", thread.steps.last.key
  end

  test "a step carries its fields as values, not hashes" do
    step = DeliveryThread.fetch(:home).steps.find { |s| s.key == "task_plan" }

    assert_equal "command", step.kind
    assert_equal "feature", step.git.on
    assert_equal "fork", step.git.event
    assert_equal "main", step.git.from
    assert_kind_of DeliveryThread::Group, step.groups.first
    assert_kind_of DeliveryThread::Row, step.groups.first.rows.first
    assert_kind_of DeliveryThread::Artifact, step.artifact
  end

  test "optional fields are nil when absent" do
    step = DeliveryThread.fetch(:home).steps.first

    assert_nil step.artifact
    assert_nil step.note
    assert_nil step.seconds
  end

  test "an unknown thread raises KeyError" do
    assert_raises(KeyError) { DeliveryThread.fetch(:nope) }
  end

  test "every thread in content/threads loads" do
    threads = DeliveryThread.all

    assert_not_empty threads
    threads.each { |thread| assert_not_empty thread.steps, "#{thread.id} has no steps" }
  end

  test "a missing required key names the file and the step" do
    error = assert_invalid(/two: missing outcome/) { |data| data["steps"][1].delete("outcome") }

    assert_includes error.message, "broken.yml"
  end

  test "an unknown key is rejected" do
    assert_invalid(/one: unknown key colour/) { |data| data["steps"][0]["colour"] = "teal" }
  end

  test "a value outside the allowed set is rejected" do
    assert_invalid(/two: kind "robot"/) { |data| data["steps"][1]["kind"] = "robot" }
    assert_invalid(/one: lane "ops"/) { |data| data["steps"][0]["lane"] = "ops" }
    assert_invalid(/one: bay "Doing"/) { |data| data["steps"][0]["bay"] = "Doing" }
    assert_invalid(/two: git.on "trunk"/) { |data| data["steps"][1]["git"]["on"] = "trunk" }
    assert_invalid(/two: git.event "rebase"/) { |data| data["steps"][1]["git"]["event"] = "rebase" }
  end

  test "a thread needs exactly one start and one end" do
    assert_invalid(/exactly one start, found 0/) { |data| data["steps"][0]["git"].delete("event") }
    assert_invalid(/exactly one end, found 2/) { |data| data["steps"][1]["git"]["event"] = "end" }
  end

  test "a fork needs a later merge back from its branch" do
    assert_invalid(/three: fork onto feature never merges/) do |data|
      data["steps"][3]["git"] = { "on" => "main", "event" => "end" }
      data["steps"][4]["git"] = { "on" => "main" }
    end
  end

  test "a bare on: key, which YAML reads as true, still loads as git.on" do
    thread = load_thread(minimal.tap { |data| data["steps"][0]["git"] = { true => "main", "event" => "start" } })

    assert_equal "main", thread.steps.first.git.on
  end

  private

  # one: start · two: plain · three: fork onto feature · four: merge · five: end
  def minimal
    step = ->(key, git) do
      { "key" => key, "name" => "/#{key}", "kind" => "command", "lane" => "agent", "bay" => "Todo",
        "outcome" => "Done.", "body" => "Body.", "git" => git, "groups" => [] }
    end
    { "id" => "broken", "title" => "Broken",
      "steps" => [
        step.("one", { "on" => "main", "event" => "start" }),
        step.("two", { "on" => "main" }),
        step.("three", { "on" => "feature", "event" => "fork", "from" => "main" }),
        step.("four", { "on" => "main", "event" => "merge", "from" => "feature" }),
        step.("five", { "on" => "main", "event" => "end" })
      ] }
  end

  def load_thread(data)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "#{data['id']}.yml")
      File.write(path, data.to_yaml)
      DeliveryThread.load(path)
    end
  end

  def assert_invalid(pattern)
    data = minimal
    yield data
    error = assert_raises(DeliveryThread::Invalid) { load_thread(data) }
    assert_match pattern, error.message
    error
  end
end

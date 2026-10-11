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

  test "a loaded thread is frozen all the way down, so a shared copy cannot be edited" do
    step = DeliveryThread.fetch(:home).steps.find { |s| s.key == "feature_plan" }

    assert step.body.frozen?
    assert step.groups.frozen?
    assert step.groups.first.rows.frozen?
    assert step.groups.first.rows.first.value.frozen?
    assert step.artifact.body.frozen?
  end

  test "optional fields are nil when absent" do
    step = DeliveryThread.fetch(:home).steps.first

    assert_nil step.artifact
    assert_nil step.note
    assert_nil step.seconds
  end

  test "a step plays for its own seconds, or six" do
    step = DeliveryThread.fetch(:home).steps.first

    assert_equal 6, step.duration
    assert_equal 9, step.with(seconds: 9).duration
  end

  test "a human or machine step is a gate; a command or optional step is not" do
    step = DeliveryThread.fetch(:home).steps.first

    assert step.with(kind: "human").gate?
    assert step.with(kind: "machine").gate?
    assert_not step.with(kind: "command").gate?
    assert_not step.with(kind: "optional").gate?
  end

  test "a cached thread is served without listing the directory again" do
    DeliveryThread.fetch(:home)

    root = DeliveryThread::ROOT
    root.define_singleton_method(:glob) { |*| raise "listed content/threads on a cache hit" }

    assert_equal "home", DeliveryThread.fetch(:home).id
  ensure
    root.singleton_class.remove_method(:glob)
  end

  test "an unknown thread raises KeyError" do
    assert_raises(KeyError) { DeliveryThread.fetch(:nope) }
  end

  test "an id that is a path reaches no file outside content/threads" do
    assert_raises(KeyError) { DeliveryThread.fetch("../../config/database") }
    assert_raises(KeyError) { DeliveryThread.fetch("home/../home") }
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

  test "a blank required value counts as missing" do
    assert_invalid(/two: missing outcome/) { |data| data["steps"][1]["outcome"] = nil }
    assert_invalid(/two: missing name/) { |data| data["steps"][1]["name"] = "  " }
  end

  test "a value of the wrong shape names the step instead of crashing" do
    assert_invalid(/two: git must be a mapping/) { |data| data["steps"][1]["git"] = "main" }
    assert_invalid(/two: groups must be a list/) { |data| data["steps"][1]["groups"] = "Routing" }
    assert_invalid(/two: groups\[1\] needs a title and a list of rows/) { |data| data["steps"][1]["groups"] = [ { "title" => "Routing" } ] }
    assert_invalid(/two: groups\[1\].rows\[1\] needs k and v/) { |data| data["steps"][1]["groups"] = [ { "title" => "T", "rows" => [ { "k" => "a" } ] } ] }
    assert_invalid(/two: artifact needs a source and a body/) { |data| data["steps"][1]["artifact"] = "x" }
    assert_invalid(/two: seconds must be a positive whole number/) { |data| data["steps"][1]["seconds"] = "8" }
  end

  test "an artifact url is optional and must be https" do
    assert_invalid(/two: artifact.url must start with https:\/\//) { |data| data["steps"][1]["artifact"] = { "source" => "s", "body" => "b", "url" => "javascript:alert(1)" } }
    assert_invalid(/two: unknown artifact key link/) { |data| data["steps"][1]["artifact"] = { "source" => "s", "body" => "b", "link" => "https://x" } }
  end

  test "a git block needs on" do
    assert_invalid(/two: git.on is required/) { |data| data["steps"][1]["git"] = { "event" => "loop", "from" => "main" } }
  end

  test "an empty groups list is allowed" do
    assert_equal [], load_thread(minimal).steps.first.groups
  end

  test "a thread needs a title" do
    assert_invalid(/missing title/) { |data| data.delete("title") }
  end

  test "the home thread carries the page's headline and intro" do
    thread = DeliveryThread.fetch(:home)

    assert_match(/positive control/, thread.headline)
    assert_match(/air traffic term/, thread.intro)
  end

  test "headline and intro are optional" do
    thread = load_thread(minimal)

    assert_nil thread.headline
    assert_nil thread.intro
  end

  test "headline and intro must be text" do
    assert_invalid(/headline must be text/) { |data| data["headline"] = [ "a" ] }
    assert_invalid(/intro must be text/) { |data| data["intro"] = { "a" => "b" } }
  end

  test "an unknown top-level key is rejected" do
    assert_invalid(/unknown top-level key subtitle/) { |data| data["subtitle"] = "x" }
  end

  test "step keys are unique" do
    assert_invalid(/two: key used by more than one step/) { |data| data["steps"][1]["key"] = "two"; data["steps"][2]["key"] = "two" }
  end

  test "the id matches the filename" do
    data = minimal.merge("id" => "home")
    error = Dir.mktmpdir do |dir|
      File.write(File.join(dir, "broken.yml"), data.to_yaml)
      assert_raises(DeliveryThread::Invalid) { DeliveryThread.load(File.join(dir, "broken.yml")) }
    end

    assert_match(/id "home" does not match the filename/, error.message)
  end

  test "a YAML boolean is not an allowed value" do
    assert_invalid(/two: kind false/) { |data| data["steps"][1]["kind"] = false }
  end

  test "a git block rejects unknown keys and checks from" do
    assert_invalid(/two: unknown git key evnet/) { |data| data["steps"][1]["git"] = { "on" => "main", "evnet" => "loop" } }
    assert_invalid(/three: git.from "mian"/) { |data| data["steps"][2]["git"]["from"] = "mian" }
    assert_invalid(/three: a fork needs git.from/) { |data| data["steps"][2]["git"].delete("from") }
  end

  test "start is the first step and end the last" do
    assert_invalid(/two: start must be the first step/) do |data|
      data["steps"][0]["git"] = { "on" => "main" }
      data["steps"][1]["git"] = { "on" => "main", "event" => "start" }
    end
    assert_invalid(/four: end must be the last step/) do |data|
      data["steps"][3]["git"] = { "on" => "main", "event" => "end" }
      data["steps"][4]["git"] = { "on" => "main", "event" => "merge", "from" => "feature" }
    end
  end

  test "a step sits on a branch only between its fork and its merge" do
    assert_invalid(/two: on feature, which has not forked yet/) { |data| data["steps"][1]["git"] = { "on" => "feature" } }
    assert_invalid(/five: on feature, which has already merged/) { |data| data["steps"][4]["git"] = { "on" => "feature", "event" => "end" } }
  end

  test "a side thread is a loop from an open line" do
    assert_invalid(/two: on side must be a loop/) { |data| data["steps"][1]["git"] = { "on" => "side" } }
    assert_invalid(/two: loop from feature, which is not open here/) do |data|
      data["steps"][1]["git"] = { "on" => "side", "event" => "loop", "from" => "feature" }
    end
    assert_invalid(/two: a loop must be on side, not main/) do |data|
      data["steps"][1]["git"] = { "on" => "main", "event" => "loop", "from" => "main" }
    end
  end

  test "the home thread's own topology passes" do
    assert_equal 15, DeliveryThread.fetch(:home).steps.size
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

  test "cells pair each step with the lines that run through its row" do
    cells = load_thread(minimal).cells

    assert_equal %w[one two three four five], cells.map { |cell| cell.step.key }
    assert_equal [ [], [], [], [], [] ], cells.map(&:through), "a fork and its merge draw their own half-lines"
  end

  test "a branch runs through every row between its fork and its merge" do
    data = minimal.tap do |thread|
      thread["steps"].insert(3, thread["steps"][1].deep_dup.merge("key" => "build", "git" => { "on" => "feature" }))
      thread["steps"].insert(4, thread["steps"][1].deep_dup.merge("key" => "aside", "git" => { "on" => "side", "event" => "loop", "from" => "main" }))
    end
    through = load_thread(data).cells.to_h { |cell| [ cell.step.key, cell.through ] }

    assert_equal({ "one" => [], "two" => [], "three" => [], "build" => [ "feature" ], "aside" => [ "feature" ], "four" => [], "five" => [] }, through)
  end

  test "a cell starts a sector where the bay differs from the row above" do
    data = minimal.tap do |thread|
      thread["steps"][2]["bay"] = "In Progress"
      thread["steps"][3]["bay"] = "In Progress"
      thread["steps"][4]["bay"] = "Done"
    end

    assert_equal [ "Todo", nil, "In Progress", nil, "Done" ], load_thread(data).cells.map(&:sector)
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

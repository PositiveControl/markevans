# frozen_string_literal: true

require "test_helper"

# Steps come from the fixture thread in test/fixtures/files/threads, so every
# target and every word on the scope is shown to come from the data.
class ScopeComponentTest < ViewComponent::TestCase
  test "one target per step, in order, each a link to its step named for it" do
    render_scope

    targets = page.all("[data-playback-target=target]")
    assert_equal steps.map { |step| "##{step.key}" }, targets.map { |target| target[:href] }
    assert_equal "Go to step 1: /begin", targets.first[:"aria-label"]
    assert_equal "Go to step 8: /ship", targets.last[:"aria-label"]
    assert targets.all? { |target| target[:"data-action"] == "playback#jump" }
  end

  test "targets sit on a 270 degree arc, the first at 135 degrees and the last at 45" do
    render_scope

    targets = page.all("[data-playback-target=target]")
    assert_equal "135.0", targets.first[:"data-angle"]
    assert_equal "405.0", targets.last[:"data-angle"]
    assert_equal "left: 23.13%; top: 76.87%", targets.first[:style]
    assert_equal "left: 76.87%; top: 76.87%", targets.last[:style]
  end

  test "the arc is spaced by the thread's own length" do
    render_inline(ScopeComponent.new(steps: steps.first(4)))

    angles = page.all("[data-playback-target=target]").map { |target| target[:"data-angle"] }
    assert_equal %w[135.0 225.0 315.0 405.0], angles
  end

  test "a gate is a rotated square, a command a square, an optional step a dashed one" do
    render_scope

    assert_selector "[href='#gate'] span.rotate-45.border-human"
    assert_selector "[href='#begin'] span.border-command:not(.rotate-45)"
    assert_selector "[href='#aside'] span.border-dashed.border-quiet"
  end

  test "each target is a 44 px control and carries what the centre block reads" do
    render_scope

    target = page.find("[href='#plan']")
    assert_includes target[:class].split, "size-target"
    assert_equal [ "03", "/plan", "Agent · Todo", "command", "false" ],
      target.native.attributes.values_at("data-number", "data-name", "data-detail", "data-kind", "data-gate").map(&:value)
  end

  test "sweep, leader and centre block are hidden until playback connects; the controls with them" do
    render_scope

    %w[sweep leader readout].each do |part|
      assert_selector "[data-scope=#{part}][hidden][data-playback-target=live]", visible: :all
    end
    assert_selector "[data-scope=sweep][aria-hidden=true].animate-sweep.motion-reduce\\:hidden", visible: :all
    assert_selector "[aria-label=Play]", visible: :all
  end

  test "the sweep turns only while playing" do
    render_scope

    classes = page.find("[data-scope=sweep]", visible: :all)[:class].split
    assert_includes classes, "[animation-play-state:paused]"
    assert_includes classes, "in-data-playing:[animation-play-state:running]"
  end

  private

  def steps = DeliveryThread.load(file_fixture("threads/small.yml")).steps

  def render_scope = render_inline(ScopeComponent.new(steps:))
end

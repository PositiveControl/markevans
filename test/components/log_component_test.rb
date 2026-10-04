# frozen_string_literal: true

require "test_helper"

# Steps are built here, so the totals and words are shown to come from them.
class LogComponentTest < ViewComponent::TestCase
  test "an entry per step, newest first: number, name, the word its strip ends on, and outcome" do
    render_inline(LogComponent.new(steps:))

    entries = page.all("[data-playback-target=logEntry]", visible: :all)
    assert_equal %w[2 1 0], entries.map { |entry| entry[:"data-index"] }
    assert_equal "03 /ship done Shipped.", entries.first.text(:all).squish
    assert_equal "02 review cleared Approved.", entries[1].text(:all).squish
  end

  test "each entry says whether it is a gate and whether it made an artifact, for the counts" do
    render_inline(LogComponent.new(steps:))

    entries = page.all("[data-playback-target=logEntry]", visible: :all)
    assert_equal %w[false true false], entries.map { |entry| entry[:"data-gate"] }
    assert_equal %w[false false true], entries.map { |entry| entry[:"data-artifact"] }
  end

  test "the header counts gates out of the thread's own total, from zero" do
    render_inline(LogComponent.new(steps:))

    assert_selector "h2#log-heading", text: "Log", visible: :all
    assert_selector "[data-playback-target=gatesCleared]", exact_text: "0", visible: :all
    assert_text "Gates cleared 0 / 1", normalize_ws: true
    assert_selector "[data-playback-target=artifacts]", exact_text: "0", visible: :all
  end

  test "every entry starts hidden behind a one-line empty state" do
    render_inline(LogComponent.new(steps:))

    assert_selector "li[hidden]", count: 3, visible: :all
    assert_selector "p[data-playback-target=logEmpty]:not([hidden])", text: "Nothing completed yet.", visible: :all
  end

  test "the body scrolls inside 220 px and can be scrolled from the keyboard" do
    render_inline(LogComponent.new(steps:))

    assert_selector "[role=region][aria-label='Log entries'][tabindex='0'].max-h-\\[220px\\].overflow-y-auto", visible: :all
  end

  test "hidden until playback connects: without scripts nothing has finished" do
    render_inline(LogComponent.new(steps:))

    assert_selector "section[aria-labelledby=log-heading][hidden][data-playback-target=live]", visible: :all
  end

  private

  def steps
    [
      step(key: "plan", name: "/plan", kind: "command", outcome: "Planned.",
        artifact: DeliveryThread::Artifact.new(source: "plan.md", body: "Plan.")),
      step(key: "review", name: "review", kind: "human", outcome: "Approved."),
      step(key: "ship", name: "/ship", kind: "command", outcome: "Shipped.")
    ]
  end

  def step(key:, name:, kind:, outcome:, artifact: nil)
    DeliveryThread::Step.new(
      key:, name:, kind:, lane: "human", bay: "Todo", outcome:, body: "Body.",
      git: DeliveryThread::Git.new(on: "main", event: nil, from: nil, label: nil),
      groups: [], artifact:, note: nil, seconds: nil
    )
  end
end

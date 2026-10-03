# frozen_string_literal: true

require "test_helper"

# Steps are built here, not read from content/threads/home.yml, so every word
# the body shows is shown to come from the step (docs/rules/content-is-files.md).
class StepBodyComponentTest < ViewComponent::TestCase
  test "the body is one serif paragraph" do
    render_inline(StepBodyComponent.new(step: step(body: "The agent drafts a design doc.")))

    assert_selector "p.font-serif", text: "The agent drafts a design doc."
  end

  test "each group is a mono label over rows of mono key and serif value" do
    groups = [ group("Produces", [ "docs/plans/" ] => "A design doc."), group("Gate", [ "G1" ] => "Mark approves.") ]
    render_inline(StepBodyComponent.new(step: step(groups:)))

    assert_selector "h4.font-mono", count: 2
    assert_selector "h4", text: "Produces"
    assert_selector "dl dt.font-mono", text: "docs/plans/"
    assert_selector "dl dd.font-serif", text: "A design doc."
    assert_selector "dl dt", text: "G1"
  end

  test "an artifact shows its source and its body, in mono on the card ground" do
    artifact = DeliveryThread::Artifact.new(source: "docs/plans/2026-10-03-x.md", body: "# Design\nline two")
    render_inline(StepBodyComponent.new(step: step(artifact:)))

    assert_selector ".bg-card.font-mono", text: "docs/plans/2026-10-03-x.md"
    assert_selector ".bg-card pre", text: "# Design\nline two"
  end

  test "a note is italic serif" do
    render_inline(StepBodyComponent.new(step: step(note: "I read every one.")))

    assert_selector "p.font-serif.italic", text: "I read every one."
  end

  test "no artifact block and no note when the step has none" do
    render_inline(StepBodyComponent.new(step: step))

    assert_no_selector ".bg-card"
    assert_no_selector "p.italic"
    assert_no_selector "dl"
  end

  private

  def group(title, rows)
    DeliveryThread::Group.new(title:, rows: rows.map { |(key), value| DeliveryThread::Row.new(key:, value:) })
  end

  def step(body: "Body.", groups: [], artifact: nil, note: nil)
    DeliveryThread::Step.new(
      key: "pick", name: "/pick", kind: "command", lane: "human", bay: "Todo", outcome: "Routed.", body:,
      git: DeliveryThread::Git.new(on: "main", event: nil, from: nil, label: nil),
      groups:, artifact:, note:, seconds: nil
    )
  end
end

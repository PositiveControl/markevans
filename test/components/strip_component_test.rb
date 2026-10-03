# frozen_string_literal: true

require "test_helper"

# Steps are built here, not read from content/threads/home.yml, so every word
# the strip shows is shown to come from the step (docs/rules/content-is-files.md).
class StripComponentTest < ViewComponent::TestCase
  test "shows the number, name, controller, bay and outcome from the step" do
    render_inline(StripComponent.new(step: step(name: "/ship_it", lane: "ci", bay: "Up for Review", outcome: "Shipped."), number: 7))

    assert_selector "span", text: "07"
    assert_selector "h3", text: "/ship_it"
    assert_selector "div", text: /Ctl\s*CI/
    assert_selector "div", text: /Bay\s*Up for Review/
    assert_selector "p", text: "Rmk Shipped."
  end

  test "each kind takes its own tint, and an optional step a dashed border" do
    { "command" => "bg-command-tint", "human" => "bg-human-tint",
      "machine" => "bg-machine-tint", "optional" => "bg-scope" }.each do |kind, tint|
      render_inline(StripComponent.new(step: step(kind:), number: 1))

      assert_selector "[data-kind=#{kind}].#{tint}"
    end
    assert_selector "[data-kind=optional].border-dashed"
  end

  test "a strip without scripts carries no status word and is not a control" do
    render_inline(StripComponent.new(step: step, number: 1))

    assert_no_selector "button"
    assert_no_text(/pending|active|done|paused/i)
  end

  test "the command name is mono and the outcome is mono: both are the machine's" do
    render_inline(StripComponent.new(step: step, number: 1))

    assert_selector "[data-kind].font-mono h3.text-strip.font-medium"
    assert_no_selector "[data-kind] .font-serif"
  end

  private

  def step(name: "/pick", kind: "command", lane: "human", bay: "Todo", outcome: "Routed.")
    DeliveryThread::Step.new(
      key: "pick", name:, kind:, lane:, bay:, outcome:, body: "Body.",
      git: DeliveryThread::Git.new(on: "main", event: nil, from: nil, label: nil),
      groups: [], artifact: nil, note: nil, seconds: nil
    )
  end
end

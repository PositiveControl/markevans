# frozen_string_literal: true

require "test_helper"

# Steps are built here, not read from content/threads/home.yml, so every word
# the strip shows is shown to come from the step (docs/rules/content-is-files.md).
class StripComponentTest < ViewComponent::TestCase
  test "shows the number, name, controller, bay and outcome from the step" do
    render_inline(StripComponent.new(step: step(name: "/ship_it", lane: "ci", bay: "Up for Review", outcome: "Shipped."), number: 7))

    assert_selector "span", text: "07"
    assert_selector "h3 button", text: "/ship_it"
    assert_selector "span", text: /Ctl\s*CI/
    assert_selector "span", text: /Bay\s*Up for Review/
    assert_selector "span", text: "Rmk Shipped."
  end

  test "each kind takes its own tint, and an optional step a dashed border" do
    { "command" => "bg-command-tint", "human" => "bg-human-tint",
      "machine" => "bg-machine-tint", "optional" => "bg-scope" }.each do |kind, tint|
      render_inline(StripComponent.new(step: step(kind:), number: 1))

      assert_selector "[data-kind=#{kind}].#{tint}"
    end
    assert_selector "[data-kind=optional].border-dashed"
  end

  test "a strip is a button that names its body and opens it, inert until playback connects" do
    render_inline(StripComponent.new(step: step, number: 1))

    assert_selector "h3 > button[type=button][disabled][aria-expanded=true][aria-controls=pick-body]"
    assert_selector "button[data-playback-target=strip][data-action='playback#select']"
  end

  test "without scripts the status cell is empty: playback writes the word" do
    render_inline(StripComponent.new(step: step, number: 1))

    assert_selector "[data-playback-target=status]", text: ""
    assert_no_text(/pending|active|done|paused|hold|cleared/i)
  end

  test "pending strips drop to a quiet outline, and the outcome shows only when done" do
    render_inline(StripComponent.new(step: step, number: 1))

    assert_selector "button.in-data-\\[state\\=pending\\]\\:bg-transparent.in-data-\\[state\\=pending\\]\\:text-quiet"
    assert_selector "span.in-data-\\[state\\=pending\\]\\:hidden.in-data-\\[state\\=active\\]\\:hidden", text: "Routed."
  end

  test "the active strip is outlined, and its status word takes the kind's color" do
    { "command" => "text-command", "human" => "text-human",
      "machine" => "text-machine", "optional" => "text-quiet" }.each do |kind, color|
      render_inline(StripComponent.new(step: step(kind:), number: 1))

      assert_selector "button.in-data-\\[state\\=active\\]\\:outline-2"
      assert_selector "[data-playback-target=status].in-data-\\[state\\=active\\]\\:#{color}"
    end
  end

  test "the remaining-time line runs only on the active strip, and freezes when paused" do
    render_inline(StripComponent.new(step: step, number: 1))

    line = page.find("[data-playback-target=line]", visible: :all)
    assert_includes line[:class], "animate-remaining"
    assert_includes line[:class], "in-data-[state=active]:block"
    assert_includes line[:class], "in-data-playing:[animation-play-state:running]"
    assert_equal "true", line[:"aria-hidden"]
  end

  test "the command name is mono and the outcome is mono: both are the machine's" do
    render_inline(StripComponent.new(step: step, number: 1))

    assert_selector "button[data-kind].font-mono span.text-strip.font-medium", text: "/pick"
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

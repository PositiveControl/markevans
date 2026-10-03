# frozen_string_literal: true

require "test_helper"

class LegendComponentTest < ViewComponent::TestCase
  test "names the four fix symbols, then the three lines and the scope target" do
    render_inline(LegendComponent.new)

    labels = page.all("[aria-label=Legend] li").map(&:text).map(&:strip)
    assert_equal [ "command", "human gate", "automated gate", "optional",
                   "main", "feature branch", "side thread", "target on scope" ], labels
  end

  test "each symbol takes its role's color and is hidden from assistive tech" do
    render_inline(LegendComponent.new)

    assert_selector "li", text: "command" do |li|
      li.assert_selector "svg.text-command[aria-hidden=true] polygon[fill=none]"
    end
    assert_selector "li", text: "human gate" do |li|
      li.assert_selector "svg.text-human polygon[fill=currentColor]"
    end
    assert_selector "li", text: "automated gate" do |li|
      li.assert_selector "svg.text-machine polygon[fill=currentColor]"
    end
    assert_selector "li", text: "optional" do |li|
      li.assert_selector "svg.text-quiet polygon[stroke-dasharray]"
    end
  end

  test "the line styles match the chart's" do
    render_inline(LegendComponent.new)

    assert_selector "li", text: "main" do |li|
      li.assert_selector "span.border-ink.border-solid[aria-hidden=true]"
    end
    assert_selector "li", text: "feature branch" do |li|
      li.assert_selector "span.border-command.border-solid"
    end
    assert_selector "li", text: "side thread" do |li|
      li.assert_selector "span.border-quiet.border-dashed"
    end
  end
end

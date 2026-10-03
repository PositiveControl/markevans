# frozen_string_literal: true

require "test_helper"

class FixMarkComponentTest < ViewComponent::TestCase
  test "a gate is filled in its role's color; a command is open" do
    render_inline(FixMarkComponent.new(kind: "machine"))
    assert_selector "svg.text-machine[aria-hidden=true] polygon.fill-current[stroke=currentColor]"

    render_inline(FixMarkComponent.new(kind: "command"))
    assert_selector "svg.text-command polygon.fill-paper"
    assert_no_selector "polygon[stroke-dasharray]"
  end

  test "an optional step is open and dashed" do
    render_inline(FixMarkComponent.new(kind: "optional"))

    assert_selector "svg.text-quiet polygon.fill-paper[stroke-dasharray]"
  end

  test "an unknown kind raises rather than drawing nothing" do
    assert_raises(KeyError) { FixMarkComponent.new(kind: "robot") }
  end
end

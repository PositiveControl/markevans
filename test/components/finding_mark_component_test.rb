# frozen_string_literal: true

require "test_helper"

# The kinds are told apart by shape, never by color: each is drawn in ink, and
# none of them is a triangle or a square, which the chart and the scope draw
# (docs/rules/color-means-role.md, docs/rules/never-color-alone.md).
class FindingMarkComponentTest < ViewComponent::TestCase
  test "a learning is an open circle" do
    render_inline(FindingMarkComponent.new(kind: "learning"))

    assert_selector "svg.text-ink[aria-hidden=true][data-mark=learning] circle.fill-paper[stroke=currentColor]"
  end

  test "a surprise is a bar over a dot" do
    render_inline(FindingMarkComponent.new(kind: "surprise"))

    assert_selector "svg.text-ink[data-mark=surprise] line[stroke=currentColor]"
    assert_selector "svg[data-mark=surprise] circle[fill=currentColor]"
  end

  test "a takeaway is an arrow" do
    render_inline(FindingMarkComponent.new(kind: "takeaway"))

    assert_selector "svg.text-ink[data-mark=takeaway] path[stroke=currentColor][fill=none]"
  end

  test "every kind has a mark, and none is a polygon or a rect" do
    Portfolio::KINDS.each do |kind|
      render_inline(FindingMarkComponent.new(kind:))

      assert_selector "svg[data-mark=#{kind}]"
      assert_no_selector "polygon, rect"
    end
  end

  test "an unknown kind raises rather than drawing nothing" do
    assert_raises(KeyError) { FindingMarkComponent.new(kind: "insight") }
  end
end

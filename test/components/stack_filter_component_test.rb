# frozen_string_literal: true

require "test_helper"

class StackFilterComponentTest < ViewComponent::TestCase
  test "All, then a link per tag; the picked one is current and links back to the whole list" do
    render_inline(StackFilterComponent.new(tags: %w[Ruby Rails], current: "Rails"))

    assert_equal [ "All", "Ruby", "Rails, show all" ], page.all("a").map(&:text)
    assert_selector "a[href='/work?tag=Ruby']:not([aria-current])", text: "Ruby"
    assert_selector "a[href='/work'][aria-current=page]", text: "Rails"
    assert_selector "a[aria-current=page] .sr-only", text: "show all", visible: :all
  end

  test "with nothing picked, All is current" do
    render_inline(StackFilterComponent.new(tags: %w[Ruby]))

    assert_selector "a[href='/work'][aria-current=page]", text: "All"
  end
end

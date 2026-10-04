# frozen_string_literal: true

require "test_helper"

class ControllerFilterComponentTest < ViewComponent::TestCase
  test "four toggles in order: All, then each lane as the strips name it" do
    render_inline(ControllerFilterComponent.new)

    labels = page.all("button[type=button]", visible: :all).map { |button| button.text(:all) }
    assert_equal [ "All", "Human", "Agent", "CI" ], labels
    assert_equal %w[all human agent ci], page.all("button", visible: :all).map { |button| button[:"data-lane"] }
  end

  test "All is pressed and the others are not; each one calls filter#pick" do
    render_inline(ControllerFilterComponent.new)

    assert_selector "button[aria-pressed=true]", count: 1, text: "All", visible: :all
    assert_selector "button[aria-pressed=false]", count: 3, visible: :all
    assert_selector "button[data-action='filter#pick'][data-filter-target=option]", count: 4, visible: :all
  end

  test "a named group of 44 px targets; the pressed one is filled ink" do
    render_inline(ControllerFilterComponent.new)

    assert_selector "[role=group][aria-labelledby=controller-filter]", visible: :all
    assert_selector "#controller-filter", text: "Controller", visible: :all
    assert_selector "button.min-h-target.min-w-target.aria-pressed\\:bg-ink", count: 4, visible: :all
  end

  test "hidden until the filter connects: without scripts there is nothing to filter with" do
    render_inline(ControllerFilterComponent.new)

    assert_selector "[data-filter-target=live][hidden] button", count: 4, visible: :all
  end
end

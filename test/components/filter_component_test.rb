# frozen_string_literal: true

require "test_helper"

class FilterComponentTest < ViewComponent::TestCase
  test "toggles in order: All, then each option as given" do
    render_inline(lanes)

    labels = page.all("button[type=button]", visible: :all).map { |button| button.text(:all) }
    assert_equal [ "All", "Human", "Agent", "CI" ], labels
  end

  test "each toggle carries its value under the key, the attribute the rows carry too" do
    render_inline(lanes)
    assert_equal %w[all human agent ci], page.all("button", visible: :all).map { |button| button[:"data-lane"] }

    render_inline(FilterComponent.new(label: "Kind", key: "kind", options: { "surprise" => "Surprises" }))
    assert_equal %w[all surprise], page.all("button", visible: :all).map { |button| button[:"data-kind"] }
    assert_no_selector "button[data-lane]", visible: :all
  end

  test "All is pressed and the others are not; each one calls filter#pick" do
    render_inline(lanes)

    assert_selector "button[aria-pressed=true]", count: 1, text: "All", visible: :all
    assert_selector "button[aria-pressed=false]", count: 3, visible: :all
    assert_selector "button[data-action='filter#pick'][data-filter-target=option]", count: 4, visible: :all
  end

  test "a group named by its label; 44 px targets; the pressed one is filled ink" do
    render_inline(lanes)

    assert_selector "[role=group][aria-labelledby=controller-filter]", visible: :all
    assert_selector "#controller-filter", text: "Controller", visible: :all
    assert_selector "button.min-h-target.min-w-target.aria-pressed\\:bg-ink", count: 4, visible: :all
  end

  test "two filters on one page name their groups apart" do
    render_inline(FilterComponent.new(label: "Kind", key: "kind", options: {}))

    assert_selector "[role=group][aria-labelledby=kind-filter]", visible: :all
    assert_selector "#kind-filter", text: "Kind", visible: :all
  end

  test "hidden until the filter connects: without scripts there is nothing to filter with" do
    render_inline(lanes)

    assert_selector "[data-filter-target=live][hidden] button", count: 4, visible: :all
  end

  private

  def lanes = FilterComponent.new(label: "Controller", key: "lane", options: DeliveryThread::LANE_NAMES)
end

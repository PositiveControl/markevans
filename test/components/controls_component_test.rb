# frozen_string_literal: true

require "test_helper"

class ControlsComponentTest < ViewComponent::TestCase
  test "four named buttons, in order: restart, step back, play, step forward" do
    render_inline(ControlsComponent.new)

    labels = page.all("button", visible: :all).map { |button| button[:"aria-label"] }
    assert_equal [ "Restart", "Step back", "Play", "Step forward" ], labels
    assert_selector "button[type=button]", count: 4, visible: :all
  end

  test "each one calls its playback action" do
    render_inline(ControlsComponent.new)

    %w[restart back toggle forward].each do |action|
      assert_selector "button[data-action='playback##{action}']", visible: :all
    end
  end

  test "every button is a 44 px round target, and only play is filled" do
    render_inline(ControlsComponent.new)

    assert_selector "button.size-target.rounded-full", count: 4, visible: :all
    assert_selector "button.bg-ink", count: 1, visible: :all
    assert_selector "button[aria-label=Play][data-playback-target=play].bg-ink", visible: :all
  end

  test "icons are hidden from assistive tech; play swaps to pause while playing" do
    render_inline(ControlsComponent.new)

    assert_no_selector "svg:not([aria-hidden=true])", visible: :all
    assert_selector "[aria-label=Play] svg.in-data-playing\\:hidden", visible: :all
    assert_selector "[aria-label=Play] svg.hidden.in-data-playing\\:block", visible: :all
  end

  test "hidden until playback connects: without scripts there is nothing to press" do
    render_inline(ControlsComponent.new)

    assert_selector "[data-playback-target=live][hidden] button", count: 4, visible: :all
  end
end

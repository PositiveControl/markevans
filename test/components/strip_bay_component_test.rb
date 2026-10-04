# frozen_string_literal: true

require "test_helper"

class StripBayComponentTest < ViewComponent::TestCase
  test "four cells in order, named by the thread's bays" do
    render_inline(StripBayComponent.new)

    cells = page.all("[data-playback-target=bay]", visible: :all)
    assert_equal [ "Todo", "In Progress", "Up for Review", "Done" ], cells.map { |cell| cell.text(:all) }
    assert_equal DeliveryThread::BAYS, cells.map { |cell| cell[:"data-bay"] }
  end

  test "the current cell fills ink from its own attribute, which only playback writes" do
    render_inline(StripBayComponent.new)

    assert_selector "[data-bay].data-current\\:bg-ink.data-current\\:text-paper", count: 4, visible: :all
    assert_no_selector "[data-current]", visible: :all
  end

  test "hidden until playback connects: without scripts no step is active" do
    render_inline(StripBayComponent.new)

    assert_selector "[aria-label='Strip bay'][data-playback-target=live][hidden]", visible: :all
  end
end

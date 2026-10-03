# frozen_string_literal: true

require "application_system_test_case"

# The home thread in a browser: the playback controller and the views that
# render from it (docs/system/home-thread-playback.md). Rows of the design
# doc's event table (section 6) are named in each test.
class HomePlaybackTest < ApplicationSystemTestCase
  setup { @thread = DeliveryThread.fetch(:home) }

  test "without scripts the page passes axe, every strip open" do
    without_scripts do
      visit root_path

      assert_selector "##{@thread.steps.last.key} h3", text: @thread.steps.last.name
      assert_accessible
    end
  end
end

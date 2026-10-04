# frozen_string_literal: true

require "application_system_test_case"

# The budget gate's third-party check as the browser sees it: every request
# the home page made, including any a script or stylesheet starts on its own.
# The sizes are in test/integration/page_budget_test.rb.
class PageRequestsTest < ApplicationSystemTestCase
  test "the home page makes no request to another origin" do
    visit root_path
    assert_selector "[aria-label=Restart]" # playback connected: every script has loaded
    assert_selector "main[data-playing]" # and run

    origins = evaluate_script(<<~JS)
      performance.getEntriesByType("resource").map(entry => new URL(entry.name).origin)
    JS
    page_origin = evaluate_script("location.origin")

    assert_operator origins.size, :>, 1, "the browser recorded no requests"
    assert_equal [ page_origin ], origins.uniq, "third-party requests"
  end
end

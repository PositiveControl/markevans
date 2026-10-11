# frozen_string_literal: true

require "application_system_test_case"

# Work, Workflow, Background and Contact in a browser: axe finds nothing on
# any of them at desktop and phone widths, nothing scrolls sideways on a
# phone, and the CV prints to one page (docs/system/site-pages.md).
class OtherPagesTest < ApplicationSystemTestCase
  PHONE = [ 390, 844 ].freeze

  def pages = [ projects_path, project_path(Portfolio.all.first.key), workflow_path, background_path, contact_path ]

  test "every page is accessible at 1400 px" do
    pages.each do |path|
      visit path
      assert_selector "h1"
      assert_accessible
    end
  end

  test "at 390 px every page is accessible and nothing scrolls sideways" do
    at_size(*PHONE) do
      pages.each do |path|
        visit path
        assert_selector "h1"
        assert_no_sideways_scroll
        assert_accessible
      end
    end
  end

  test "the CV prints to one page, without the header and footer" do
    visit background_path
    assert_selector "h1", text: SitePage.fetch(:background).title

    pdf = Base64.decode64(page.driver.browser.print_page)
    assert_equal 1, pdf.scan(%r{/Type\s*/Page\b}).size, "the CV printed to more than one page"

    as_print do
      assert_no_selector "header"
      assert_no_selector "footer"
      assert_selector "h1", text: SitePage.fetch(:background).title
    end
  end
end

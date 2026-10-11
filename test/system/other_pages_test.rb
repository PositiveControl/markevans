# frozen_string_literal: true

require "application_system_test_case"

# Work, Workflow, Background and Contact in a browser: axe finds nothing on
# any of them at desktop and phone widths, nothing scrolls sideways on a
# phone, and the CV prints to one page (docs/system/site-pages.md).
class OtherPagesTest < ApplicationSystemTestCase
  PHONE = [ 390, 844 ].freeze

  def pages = [ projects_path, projects_path(tag: "Ruby"), project_path(Portfolio.all.first.key), workflow_path, background_path, contact_path ]

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

  test "a stack filter link is a 44 px target that narrows the list" do
    visit projects_path
    sizes = evaluate_script(<<~JS)
      [...document.querySelectorAll("nav[aria-label='Filter by stack'] a")].map(a => { const r = a.getBoundingClientRect(); return [a.textContent, r.width, r.height] })
    JS
    sizes.each { |name, width, height| assert_operator [ width, height ].min, :>=, 44, "#{name} is #{width}×#{height}" }

    within("nav[aria-label='Filter by stack']") { click_link "Swift" }
    assert_selector "a[aria-current=page]", text: "Swift"
    assert_selector "main section li[data-project]", count: 1
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

  private

  def as_print
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
    yield
  ensure
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
  end
end

# frozen_string_literal: true

require "test_helper"

class SiteFooterComponentTest < ViewComponent::TestCase
  test "it signs the page, with a page's own items between the two lines" do
    render_inline(SiteFooterComponent.new) { "<ul><li>extra</li></ul>".html_safe }

    assert_selector "footer span", text: "Mark Evans · PositiveControl"
    assert_selector "footer span", text: "This site is built with the workflow it describes."
    assert_selector "footer ul li", text: "extra"
  end

  test "it leaves the printed page" do
    render_inline(SiteFooterComponent.new)

    assert_selector "footer.print\\:hidden"
  end
end

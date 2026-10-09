# frozen_string_literal: true

require "test_helper"

class LinkListComponentTest < ViewComponent::TestCase
  test "each link is its label in mono beside the address, without its scheme" do
    render_inline(LinkListComponent.new(links: [ link("GitHub", "https://github.com/PositiveControl/"), link("Email", "mailto:a@example.com") ]))

    assert_selector "dt.font-mono", text: "GitHub"
    assert_selector "dd a[href='https://github.com/PositiveControl/']", text: "github.com/PositiveControl"
    assert_selector "dd a[href='mailto:a@example.com']", text: "a@example.com"
  end

  test "a link still to be written shows its placeholder as text, not as a link" do
    render_inline(LinkListComponent.new(links: [ link("Email", "[mailto:address]") ]))

    assert_selector "dd span", text: "[mailto:address]"
    assert_no_selector "a"
  end

  test "a link is at least 44 px tall to touch, and underlined, not told by color alone" do
    render_inline(LinkListComponent.new(links: [ link("GitHub", "https://github.com/x") ]))

    classes = page.find("a")[:class].split
    assert_includes classes, "min-h-8"
    assert_includes classes, "underline"
  end

  test "in print a link drops its touch height and takes the print scale" do
    render_inline(LinkListComponent.new(links: [ link("GitHub", "https://github.com/x") ]))

    assert_includes page.find("a")[:class].split, "print:min-h-0"
    assert_includes page.find("dt")[:class].split, "print:w-print-key"
  end

  test "the list is named by a group around it, not on the dl, and renders nothing when empty" do
    render_inline(LinkListComponent.new(links: [ link("GitHub", "https://github.com/x") ], label: "Contact routes"))
    assert_selector "[role=group][aria-label='Contact routes'] > dl"
    assert_no_selector "dl[aria-label]"

    render_inline(LinkListComponent.new(links: []))
    assert_no_selector "dl"
  end

  private

  def link(label, url) = SitePage::Link.new(label:, url:)
end

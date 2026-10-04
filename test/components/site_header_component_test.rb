# frozen_string_literal: true

require "test_helper"

class SiteHeaderComponentTest < ViewComponent::TestCase
  test "the name links home, and the four sections follow it in order" do
    render_inline(SiteHeaderComponent.new(current_path: "/"))

    assert_selector "header > div > a[href='/']", text: "Mark Evans"
    assert_equal %w[Work Workflow Background Contact], page.all("nav[aria-label=Site] a").map(&:text)
    assert_equal [ "/work", "/workflow", "/background", "/contact" ], page.all("nav a").map { |a| a[:href] }
  end

  test "no section is current on the home page" do
    render_inline(SiteHeaderComponent.new(current_path: "/"))

    assert_no_selector "[aria-current]"
  end

  test "a section is current on its own page and on the pages beneath it" do
    render_inline(SiteHeaderComponent.new(current_path: "/work/kram"))

    assert_selector "a[aria-current=page]", count: 1, text: "Work"
  end

  test "a section is not current on a page that only shares its prefix" do
    render_inline(SiteHeaderComponent.new(current_path: "/workflow"))

    assert_selector "a[aria-current=page]", count: 1, text: "Workflow"
  end

  test "the current section is underlined, not only colored" do
    render_inline(SiteHeaderComponent.new(current_path: "/contact"))

    assert_includes page.find("a[aria-current=page]")[:class], "aria-[current=page]:underline"
  end

  test "the header leaves the printed page" do
    render_inline(SiteHeaderComponent.new(current_path: "/background"))

    assert_selector "header.print\\:hidden"
  end
end

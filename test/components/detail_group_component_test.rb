# frozen_string_literal: true

require "test_helper"

class DetailGroupComponentTest < ViewComponent::TestCase
  test "a mono label over rows of mono key and serif value" do
    render_inline(DetailGroupComponent.new(group: group("Produces", "docs/plans/" => "A design doc.", "G1" => "Mark approves.")))

    assert_selector "h4.font-mono.uppercase", text: "Produces"
    assert_selector "dl dt.font-mono", text: "docs/plans/"
    assert_selector "dl dd.font-serif", text: "A design doc."
    assert_selector "dl > div", count: 2
  end

  test "a value never narrows below 180 px: it wraps under its key instead" do
    render_inline(DetailGroupComponent.new(group: group("Education", "Qualification" => "Institution")))

    assert_includes page.find("dd")[:class].split, "basis-30"
    assert_includes page.find("dl > div")[:class].split, "flex-wrap"
  end

  test "the label takes the heading level it is given" do
    render_inline(DetailGroupComponent.new(group: group("Experience", "Role" => "Company"), level: 3))

    assert_selector "h3", text: "Experience"
    assert_no_selector "h4"
  end

  test "it draws a page's group as it draws a step's" do
    page_group = SitePage::Group.new(title: "At a glance", rows: [ SitePage::Row.new(key: "Stack", value: "Rails") ])
    render_inline(DetailGroupComponent.new(group: page_group))

    assert_selector "dt", text: "Stack"
    assert_selector "dd", text: "Rails"
  end

  private

  def group(title, rows)
    DeliveryThread::Group.new(title:, rows: rows.map { |key, value| DeliveryThread::Row.new(key:, value:) })
  end
end

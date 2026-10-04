# frozen_string_literal: true

require "test_helper"

# Sections are built here, not read from content/, so every word shown is
# shown to come from the section (docs/rules/content-is-files.md).
class PageSectionsComponentTest < ViewComponent::TestCase
  test "each section is a mono heading over serif paragraphs, in order" do
    render_inline(PageSectionsComponent.new(sections: [ section("The gates", paragraphs: [ "One.", "Two." ]), section("Agents", paragraphs: [ "Three." ]) ]))

    assert_equal [ "The gates", "Agents" ], page.all("h2.font-mono").map(&:text)
    assert_selector "section:first-child p.font-serif", count: 2
    assert_selector "p", text: "Three."
  end

  test "a section's groups are drawn as detail rows, labelled one level below its heading" do
    group = SitePage::Group.new(title: "2020–2024", rows: [ SitePage::Row.new(key: "Engineer", value: "Somewhere") ])
    render_inline(PageSectionsComponent.new(sections: [ section("Experience", groups: [ group ]) ]))

    assert_selector "h3", text: "2020–2024"
    assert_selector "dt.font-mono", text: "Engineer"
    assert_selector "dd.font-serif", text: "Somewhere"
  end

  test "nothing renders when there are no sections" do
    render_inline(PageSectionsComponent.new(sections: []))

    assert_no_selector "div"
  end

  private

  def section(heading, paragraphs: [], groups: [])
    SitePage::Section.new(heading:, paragraphs:, groups:)
  end
end

# frozen_string_literal: true

require "test_helper"

# Findings are built here, not read from content/, so every word shown is
# shown to come from the finding (docs/rules/content-is-files.md).
class FindingsComponentTest < ViewComponent::TestCase
  test "a section headed Findings, its list named by the heading" do
    render_inline(FindingsComponent.new(findings: [ finding("learning") ]))

    assert_selector "section h2.font-mono#findings-heading", text: "Findings"
    assert_selector "ul[aria-labelledby=findings-heading] > li", count: 1
  end

  test "each finding is its kind in a word beside its mark, then a serif title and body" do
    render_inline(FindingsComponent.new(findings: [ finding("surprise") ]))

    assert_selector "li[data-kind=surprise] p.font-mono", text: "Surprise"
    assert_selector "li[data-kind=surprise] p.font-mono svg[data-mark=surprise]"
    assert_selector "li h3.font-serif", text: "A surprise."
    assert_selector "li p.font-serif", text: "Body of a surprise."
  end

  test "each finding is addressable as finding-n, in order" do
    render_inline(FindingsComponent.new(findings: [ finding("learning"), finding("takeaway") ]))

    assert_equal %w[finding-1 finding-2], page.all("li").map { |li| li[:id] }
    assert_selector "#finding-2[data-kind=takeaway]"
  end

  test "evidence is a mono link by its label" do
    evidence = SitePage::Link.new(label: "PR #142", url: "https://example.com/142")
    render_inline(FindingsComponent.new(findings: [ finding("learning", evidence:) ]))

    assert_selector "p.font-mono a[href='https://example.com/142']", text: "PR #142"
  end

  test "evidence still to be found is shown as text, never as a link to nowhere" do
    evidence = SitePage::Link.new(label: "[Evidence]", url: "[https://…]")
    render_inline(FindingsComponent.new(findings: [ finding("learning", evidence:) ]))

    assert_no_selector "a"
    assert_selector "p.font-mono", text: "[Evidence] [https://…]"
  end

  test "a long evidence address wraps rather than scrolling a phone sideways, as a link list's does" do
    evidence = SitePage::Link.new(label: "[Evidence]", url: "[https://github.com/PositiveControl/rails-rocket-sheep/pull/…]")
    render_inline(FindingsComponent.new(findings: [ finding("learning", evidence:) ]))

    assert_selector "p.font-mono.wrap-anywhere", text: evidence.url
  end

  test "a finding without evidence shows no evidence line" do
    render_inline(FindingsComponent.new(findings: [ finding("learning") ]))

    assert_selector "li p.font-mono", count: 1
  end

  test "the section filters its findings by kind: a toggle per kind after All, hidden until scripts run" do
    render_inline(FindingsComponent.new(findings: Portfolio::KINDS.map { |kind| finding(kind) }))

    assert_selector "section[data-controller=filter][data-filter-key-value=kind]"
    assert_selector "section [role=group][aria-labelledby=kind-filter][hidden][data-filter-target=live]", visible: :all
    labels = page.all("[data-filter-target=option]", visible: :all).map { |button| button.text(:all) }
    assert_equal [ "All", "Learnings", "Surprises", "Takeaways" ], labels
    assert_equal %w[all] + Portfolio::KINDS, page.all("[data-filter-target=option]", visible: :all).map { |button| button[:"data-kind"] }
  end

  test "a toggle for each kind the project has, in the kinds' order, so none dims every finding" do
    render_inline(FindingsComponent.new(findings: [ finding("takeaway"), finding("learning"), finding("takeaway") ]))

    labels = page.all("[data-filter-target=option]", visible: :all).map { |button| button.text(:all) }
    assert_equal [ "All", "Learnings", "Takeaways" ], labels
  end

  test "findings of one kind have nothing to narrow, so there are no toggles" do
    render_inline(FindingsComponent.new(findings: [ finding("surprise"), finding("surprise") ]))

    assert_selector "li", count: 2
    assert_no_selector "[role=group]", visible: :all
  end

  test "the toggles come after the heading and before the list, so the list still reads in order" do
    render_inline(FindingsComponent.new(findings: [ finding("learning"), finding("surprise") ]))

    order = page.all("h2, [role=group], ul", visible: :all).map(&:tag_name)
    assert_equal %w[h2 div ul], order
  end

  test "every finding is a row the filter dims by its kind, to quiet text, never hidden" do
    render_inline(FindingsComponent.new(findings: [ finding("learning"), finding("surprise") ]))

    assert_selector "li[data-filter-target=row][data-kind]", count: 2
    assert_selector "li.data-dim\\:text-quiet", count: 2
    assert_selector "li svg.in-data-dim\\:text-quiet", count: 2
    assert_no_selector "li[class*=opacity], li [class*=opacity], li[data-dim]"
  end

  test "nothing renders when there are no findings" do
    render_inline(FindingsComponent.new(findings: []))

    assert_no_selector "section"
  end

  private

  def finding(kind, evidence: nil)
    Portfolio::Finding.new(kind:, title: "A #{kind}.", body: "Body of a #{kind}.", evidence:)
  end
end

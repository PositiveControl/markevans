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

  test "a finding without evidence shows no evidence line" do
    render_inline(FindingsComponent.new(findings: [ finding("learning") ]))

    assert_selector "li p.font-mono", count: 1
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

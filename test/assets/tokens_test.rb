require "test_helper"

# The token file is the design doc's section 3 in CSS. Every value here is
# copied from that table; a token that drifts from it is a design change and
# belongs in the doc first (docs/rules/tokens-only.md).
class TokensTest < ActiveSupport::TestCase
  TOKENS = Rails.root.join("app/assets/tailwind/tokens.css").read

  COLORS = {
    "paper" => "#F7F6F0", "scope" => "#EFEEE6", "card" => "#FDFDFB",
    "ink" => "#1B2428", "quiet" => "#4A5763",
    "command" => "#0F7480", "command-tint" => "#E4EEF0",
    "human" => "#A6651A", "human-tint" => "#F6E9D8",
    "machine" => "#3E7C4F", "machine-tint" => "#E3EFE6",
    "rule" => "rgba(27, 36, 40, 0.3)", "rule-strong" => "rgba(27, 36, 40, 0.55)", "rule-faint" => "rgba(27, 36, 40, 0.15)",
    "sector-1" => "rgba(27, 36, 40, 0.05)", "sector-2" => "rgba(27, 36, 40, 0.1)"
  }.freeze

  # name => [size, line height, tracking]
  TYPE = {
    "headline" => [ "40px", "48px", "-0.01em" ],
    "prose" => [ "18px", "30px", nil ],
    "strip" => [ "16px", "24px", nil ],
    "key" => [ "14px", "30px", nil ],
    "artifact" => [ "14px", "24px", nil ],
    "label" => [ "12px", "18px", "0.04em" ],
    "cell" => [ "11px", "16px", nil ]
  }.freeze

  test "every color in the design doc is a token" do
    COLORS.each { |name, value| assert_token "--color-#{name}", value }
  end

  test "the type scale carries size, line height and tracking" do
    TYPE.each do |name, (size, leading, tracking)|
      assert_token "--text-#{name}", size
      assert_token "--text-#{name}--line-height", leading
      assert_token "--text-#{name}--letter-spacing", tracking if tracking
    end
  end

  test "faces, spacing unit, radius and widths" do
    assert_match(/--font-serif:\s*"Newsreader"/, TOKENS)
    assert_match(/--font-mono:\s*"IBM Plex Mono"/, TOKENS)
    assert_token "--spacing", "6px"
    assert_token "--radius-box", "2px"
    assert_token "--container-page", "1320px"
    assert_token "--container-column", "400px"
  end

  # Design doc, section 4: the strip's ruled cells and the detail row key.
  test "the strip anatomy widths are named" do
    { "step-number" => "44px", "step-control" => "92px", "step-bay" => "132px",
      "step-status" => "96px", "row-key" => "260px" }.each { |name, value| assert_token "--container-#{name}", value }
    assert_token "--spacing-strip-gap", "20px"
    { "measure" => "66ch", "artifact" => "80ch", "detail" => "880px" }.each { |name, value| assert_token "--container-#{name}", value }
  end

  # Design doc, sections 4 and 5: lanes, the fix, elbows, the loop bracket.
  test "the chart geometry is named" do
    { "lane-main" => "44px", "lane-feature" => "150px", "lane-side" => "256px", "fix" => "34px",
      "elbow" => "14px", "loop-inset" => "10px", "chart-label" => "20px" }.each { |name, value| assert_token "--spacing-#{name}", value }
  end

  # Design doc, section 4: below 900 px the chart narrows to a gutter.
  test "the narrow gutter and its lanes are named, under one breakpoint" do
    assert_token "--breakpoint-chart", "900px"
    assert_token "--container-gutter", "84px"
    { "lane-main" => "14px", "lane-feature" => "38px", "lane-side" => "62px" }.each { |name, value| assert_token "--spacing-#{name}", value }

    # The gutter's lanes are the default; the full column's sit under chart:.
    theme = TOKENS[/@theme \{.*?\n\}/m]
    wide = TOKENS[/@variant chart \{(.*?)\}/m, 1]
    assert_match(/--spacing-lane-main:\s*14px;/, theme)
    assert_match(/--spacing-lane-main:\s*44px;/, wide)
    assert_match(/--spacing-lane-side:\s*256px;/, wide)
  end

  test "the app stylesheet imports the tokens and defines no palette of its own" do
    app = Rails.root.join("app/assets/tailwind/application.css").read

    assert_match(/@import\s+"\.\/tokens\.css";/, app)
    assert_no_match(/--color-[\w-]+:|@font-face/, app)
  end

  test "every font file on disk is declared, and every declared font is on disk" do
    on_disk = Rails.root.join("app/assets/fonts").glob("*.woff2").map { |path| path.basename.to_s }.sort
    declared = TOKENS.scan(/url\("([\w-]+\.woff2)"\)/).flatten.sort

    assert_equal on_disk, declared
  end

  test "Tailwind's default palette, faces, sizes, radii, shadows and widths are cleared" do
    %w[color font text radius shadow inset-shadow drop-shadow container].each { |namespace| assert_token "--#{namespace}-*", "initial" }
  end

  test "no size token shares a name with a color token" do
    sizes = TOKENS.scan(/--text-([\w-]+?):/).flatten.reject { |name| name.include?("--") }

    assert_empty sizes & COLORS.keys
  end

  test "both Newsreader files are declared" do
    assert_includes TOKENS, %(url("newsreader-roman.woff2"))
    assert_includes TOKENS, %(url("newsreader-italic.woff2"))
  end

  private

  def assert_token(name, value)
    assert_match(/^\s*#{Regexp.escape(name)}:\s*#{Regexp.escape(value)};/i, TOKENS, "#{name} should be #{value}")
  end
end

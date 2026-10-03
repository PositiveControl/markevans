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

  test "Tailwind's default palette, faces, sizes, radii and shadows are cleared" do
    %w[color font text radius shadow].each { |namespace| assert_token "--#{namespace}-*", "initial" }
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

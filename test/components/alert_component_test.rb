# frozen_string_literal: true

require "test_helper"

class AlertComponentTest < ViewComponent::TestCase
  test "renders nothing without content" do
    render_inline(AlertComponent.new)

    assert_no_selector "[role=alert]"
  end

  test "renders content with the default variant" do
    render_inline(AlertComponent.new) { "Heads up" }

    assert_selector "[role=alert]", text: "Heads up"
    assert_selector "[role=alert] span", text: "Notice"
  end

  test "applies the requested variant" do
    render_inline(AlertComponent.new(variant: :success)) { "Saved" }

    assert_selector "[role=alert]", text: "Saved"
    assert_selector "[role=alert] span", text: "Done"
  end

  test "falls back to the default variant for an unknown one" do
    render_inline(AlertComponent.new(variant: :nonsense)) { "Hm" }

    assert_selector "[role=alert] span", text: "Notice"
  end

  # The variant is named in words, not color (docs/rules/never-color-alone.md),
  # and the box is drawn from the tokens (docs/rules/tokens-only.md).
  test "every variant looks the same and names itself" do
    AlertComponent::VARIANTS.each do |variant, label|
      render_inline(AlertComponent.new(variant:)) { "Message" }

      assert_selector "[role=alert].bg-card.border-rule", text: "#{label} Message"
    end
  end
end

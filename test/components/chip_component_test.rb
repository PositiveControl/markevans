# frozen_string_literal: true

require "test_helper"

class ChipComponentTest < ViewComponent::TestCase
  test "a language chip is ink on a strong rule" do
    render_inline(ChipComponent.new(name: "Ruby"))

    assert_selector "li.text-ink.border-rule-strong[data-kind=language]", text: "Ruby"
  end

  test "a stack or hosting chip is quiet on a faint rule" do
    render_inline(ChipComponent.new(name: "Rails"))
    assert_selector "li.text-quiet.border-rule[data-kind=framework]", text: "Rails"

    render_inline(ChipComponent.new(name: "Hetzner"))
    assert_selector "li.text-quiet.border-rule[data-kind=hosting]", text: "Hetzner"
  end

  test "an unknown chip raises" do
    assert_raises(KeyError) { ChipComponent.new(name: "COBOL") }
  end
end

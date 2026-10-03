# frozen_string_literal: true

# A single inline message: success, notice, warning, or error.
#
#   = render AlertComponent.new(variant: :success) do
#     | Order placed.
#
# Renders nothing when given no content, so call sites don't need a conditional.
#
# Every variant draws the same box from the tokens and names itself in words.
# The design has no success green or danger red: green and amber mean the two
# kinds of gate (docs/rules/color-means-role.md), and a meaning carried by color
# alone is lost to some readers (docs/rules/never-color-alone.md).
class AlertComponent < ApplicationComponent
  VARIANTS = {
    notice: "Notice",
    success: "Done",
    warning: "Warning",
    alert: "Error"
  }.freeze

  DEFAULT_VARIANT = :notice

  # @param variant [Symbol] one of VARIANTS' keys; unknown values fall back to :notice
  def initialize(variant: DEFAULT_VARIANT)
    @variant = variant.to_sym
  end

  # @return [Boolean] false when there is nothing to say
  def render?
    content.present?
  end

  private

  def label = VARIANTS.fetch(@variant, VARIANTS[DEFAULT_VARIANT])
end

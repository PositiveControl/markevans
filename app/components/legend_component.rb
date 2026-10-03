# frozen_string_literal: true

# The key to the chart and the scope: what each fix symbol and line style means.
#
#   = render LegendComponent.new
#
# Two columns, read top to bottom: the four fix symbols, then the three line
# styles and the scope target (design doc, section 3). Each symbol takes its
# role's token color (docs/rules/color-means-role.md) and is always paired with
# its name (docs/rules/never-color-alone.md).
class LegendComponent < ApplicationComponent
  Mark = Data.define(:label, :color, :filled, :dashed)
  Line = Data.define(:label, :classes)

  SYMBOLS = [
    Mark.new(label: "command", color: "text-command", filled: false, dashed: false),
    Mark.new(label: "human gate", color: "text-human", filled: true, dashed: false),
    Mark.new(label: "automated gate", color: "text-machine", filled: true, dashed: false),
    Mark.new(label: "optional", color: "text-quiet", filled: false, dashed: true)
  ].freeze

  LINES = [
    Line.new(label: "main", classes: "border-ink border-solid"),
    Line.new(label: "feature branch", classes: "border-command border-solid"),
    Line.new(label: "side thread", classes: "border-quiet border-dashed")
  ].freeze

  # The triangle every fix is drawn with, point down.
  TRIANGLE = "1,3 17,3 9,17"

  private

  def fill(mark) = mark.filled ? "currentColor" : "none"

  def dash(mark) = ("3 2" if mark.dashed)
end

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
  Line = Data.define(:label, :classes)

  # Each kind of fix, by the name the legend gives it.
  SYMBOLS = {
    "command" => "command",
    "human" => "human gate",
    "machine" => "automated gate",
    "optional" => "optional"
  }.freeze

  LINES = [
    Line.new(label: "main", classes: "border-ink border-solid"),
    Line.new(label: "feature branch", classes: "border-command border-solid"),
    Line.new(label: "side thread", classes: "border-quiet border-dashed")
  ].freeze
end

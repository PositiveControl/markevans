# frozen_string_literal: true

# The triangle a step's fix is drawn with, point down, in an 18 px slot (size-3).
#
#   = render FixMarkComponent.new(kind: step.kind)
#
# The legend names each one; the chart draws one per row. A gate is filled in
# its role's color, a command is open, an optional step is open and dashed
# (design doc, section 3; docs/rules/color-means-role.md). An open mark is
# filled with the page ground so a line behind it stops at its edge.
class FixMarkComponent < ApplicationComponent
  Mark = Data.define(:color, :fill, :dash)

  KINDS = {
    "command" => Mark.new(color: "text-command", fill: "fill-paper", dash: nil),
    "human" => Mark.new(color: "text-human", fill: "fill-current", dash: nil),
    "machine" => Mark.new(color: "text-machine", fill: "fill-current", dash: nil),
    "optional" => Mark.new(color: "text-quiet", fill: "fill-paper", dash: "3 2")
  }.freeze

  TRIANGLE = "1,3 17,3 9,17"

  # @param kind [String] one of DeliveryThread::KINDS
  def initialize(kind:)
    @mark = KINDS.fetch(kind)
  end

  private

  attr_reader :mark
end

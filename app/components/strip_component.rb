# frozen_string_literal: true

# One step's flight strip: a row of ruled cells naming the step, who controls
# it and which bay it sits in.
#
#   = render StripComponent.new(step:, number: 4)
#
# Anatomy and widths are the design doc's, section 4. This is the strip as it
# renders without scripts (section 6): open, in the done state's colors, with
# no status word, and not a control. Playback (slice 3) makes it a button and
# fills the status cell. Every word comes from the step.
class StripComponent < ApplicationComponent
  # The strip's ground, by what the step is (docs/rules/color-means-role.md).
  KINDS = {
    "command" => "bg-command-tint border-solid",
    "human" => "bg-human-tint border-solid",
    "machine" => "bg-machine-tint border-solid",
    "optional" => "bg-scope border-dashed"
  }.freeze

  LANES = { "human" => "Human", "agent" => "Agent", "ci" => "CI" }.freeze

  # @param step [DeliveryThread::Step]
  # @param number [Integer] the step's position, from 1
  def initialize(step:, number:)
    @step = step
    @number = number
  end

  private

  attr_reader :step

  def number = format("%02d", @number)

  def lane = LANES.fetch(step.lane)

  def classes
    class_names("flex min-h-9 flex-wrap items-center rounded-box border border-rule-strong font-mono text-artifact text-ink",
      KINDS.fetch(step.kind))
  end
end

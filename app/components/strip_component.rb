# frozen_string_literal: true

# One step's flight strip: a row of ruled cells naming the step, who controls
# it and which bay it sits in.
#
#   = render StripComponent.new(step:, number: 4)
#
# Anatomy and widths are the design doc's, section 4. The strip is the button
# that opens and closes the step's body, inside the step's heading. Without
# scripts (section 6) it renders open, in the done state's colors, with no
# status word, and disabled: the playback controller enables it.
#
# Its state comes from the row it sits in. The controller writes data-state
# (pending, active or done) on the row and data-playing on the page, and the
# in-data-* variants below style from them (docs/rules/one-playback-state.md).
# Every word comes from the step except the status word, which the controller
# writes.
class StripComponent < ApplicationComponent
  # The strip's ground, by what the step is (docs/rules/color-means-role.md).
  KINDS = {
    "command" => "bg-command-tint border-solid",
    "human" => "bg-human-tint border-solid",
    "machine" => "bg-machine-tint border-solid",
    "optional" => "bg-scope border-dashed"
  }.freeze

  # The status word takes the kind's color while its step is active.
  STATUS = {
    "command" => "in-data-[state=active]:text-command",
    "human" => "in-data-[state=active]:text-human",
    "machine" => "in-data-[state=active]:text-machine",
    "optional" => "in-data-[state=active]:text-quiet"
  }.freeze

  # Pending: no ground, a faint rule, quiet text. Active, playing or paused:
  # the 2 px ink outline.
  STATES = "in-data-[state=pending]:bg-transparent in-data-[state=pending]:border-rule " \
    "in-data-[state=pending]:text-quiet in-data-[state=active]:outline-2 " \
    "in-data-[state=active]:outline-ink in-data-[state=active]:-outline-offset-1"

  # @param step [DeliveryThread::Step]
  # @param number [Integer] the step's position, from 1
  def initialize(step:, number:)
    @step = step
    @number = number
  end

  private

  attr_reader :step

  def number = format("%02d", @number)

  def lane = DeliveryThread::LANE_NAMES.fetch(step.lane)

  def body_id = StepBodyComponent.id_for(step)

  def classes
    class_names("relative flex w-full min-h-9 flex-wrap items-center rounded-box border border-rule-strong",
      "text-left font-mono text-artifact text-ink enabled:cursor-pointer", KINDS.fetch(step.kind), STATES)
  end

  def status_classes
    class_names("flex w-step-status shrink-0 items-center justify-center self-stretch border-l border-rule",
      "text-label font-medium uppercase", STATUS.fetch(step.kind))
  end
end

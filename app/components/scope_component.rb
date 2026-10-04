# frozen_string_literal: true

# The radar scope: the console the thread is played from.
#
#   = render ScopeComponent.new(steps: @thread.steps)
#
# Design doc, section 4. A circle holding the dashed route ring, a crosshair,
# one target per step on a 270 degree arc (the first at 135 degrees, the last
# at 45, measured clockwise from three o'clock), the leader line from the
# centre to the active target, the centre block naming the active step, the
# sweep, and the controls.
#
# Each target is a link to its step, so without scripts the scope is a map of
# the thread. The playback controller turns a click into a jump, marks each
# target's data-state, and points the leader with --leader-angle from the
# active target's data-angle. Sweep, leader, centre block and controls only
# mean something while playback runs, so they render hidden until it
# connects. Every element states something (docs/rules/every-element-answers.md):
# the sweep turns only while playing.
class ScopeComponent < ApplicationComponent
  Target = Data.define(:step, :index, :number, :angle, :style)

  FIRST = 135.0
  ARC = 270.0
  RADIUS = 38.0 # percent of the scope, from its centre

  MARK = "size-1.5 border bg-scope"

  # A target's mark: a square for a command, a rotated square for a gate, a
  # dashed square for an optional step; filled once its step is reached.
  MARKS = {
    "command" => "border-command in-data-[state=active]:bg-command in-data-[state=done]:bg-command",
    "human" => "rotate-45 border-human in-data-[state=active]:bg-human in-data-[state=done]:bg-human",
    "machine" => "rotate-45 border-machine in-data-[state=active]:bg-machine in-data-[state=done]:bg-machine",
    "optional" => "border-dashed border-quiet in-data-[state=active]:bg-quiet in-data-[state=done]:bg-quiet"
  }.freeze

  # @param steps [Array<DeliveryThread::Step>]
  def initialize(steps:)
    @steps = steps
  end

  private

  def targets
    gaps = [ @steps.size - 1, 1 ].max
    @steps.each_with_index.map do |step, index|
      angle = FIRST + ARC * index / gaps
      Target.new(step:, index:, number: format("%02d", index + 1), angle:, style: position(angle))
    end
  end

  def position(angle)
    radians = angle * Math::PI / 180
    format("left: %.2f%%; top: %.2f%%", 50 + RADIUS * Math.cos(radians), 50 + RADIUS * Math.sin(radians))
  end

  def detail(step) = "#{DeliveryThread::LANE_NAMES.fetch(step.lane)} · #{step.bay}"

  def mark_classes(step) = class_names(MARK, MARKS.fetch(step.kind))
end

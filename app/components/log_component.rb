# frozen_string_literal: true

# What the thread has produced so far: the finished steps, newest first, with
# the gates cleared and the artifacts made.
#
#   = render LogComponent.new(steps: thread.steps)
#
# Every step renders as an entry, in reverse order, hidden; the playback
# controller shows the ones before the active step and writes the two counts
# (docs/rules/one-playback-state.md), so the log never holds state of its own.
# Each entry's status word is the one its strip ends on: cleared for a gate,
# done otherwise. The gate total is counted from the thread, not written down.
#
# The body scrolls inside 220 px (design doc, section 4). It holds no control,
# so it takes focus itself and can be scrolled from the keyboard.
#
# Rendered hidden: without scripts nothing has finished (section 6), so the
# controller reveals it on connect.
class LogComponent < ApplicationComponent
  Entry = Data.define(:index, :number, :step)

  # @param steps [Array<DeliveryThread::Step>]
  def initialize(steps:)
    @steps = steps
  end

  private

  attr_reader :steps

  def gates = steps.count(&:gate?)

  # Newest first: the last step's entry heads the list.
  def entries
    steps.each_with_index.map { |step, index| Entry.new(index:, number: format("%02d", index + 1), step:) }.reverse
  end

  def status(step) = step.gate? ? "cleared" : "done"
end

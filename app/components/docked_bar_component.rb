# frozen_string_literal: true

# A slim bar that docks at the top of the page once the scope is out of view.
#
#   = render DockedBarComponent.new(steps: @thread.steps)
#
# Design doc, section 4: the controls, the active step's number and name, the
# strip bay, and one mark per step for jumping. It is a second view of the
# playback controller's state, not a second player
# (docs/rules/one-playback-state.md): every part of it is a target the
# controller already renders, and each mark is a link to its step, like a
# scope target, drawn the same way.
#
# Rendered hidden: without scripts there is nothing to dock (section 6). Once
# playback connects, the bar still shows only while the controller marks the
# page data-docked, so while the scope is in view its copies of the controls
# are out of the tab order and the accessibility tree. It is one row at every
# width, under 96 px, the line the page follows the active strip to: below
# 1280 px the bay gives way, below 1024 px the marks, and the name is cut to
# one line. On a phone the strips are the way to jump (#19).
class DockedBarComponent < ApplicationComponent
  Mark = Data.define(:step, :index)

  # @param steps [Array<DeliveryThread::Step>]
  def initialize(steps:)
    @steps = steps
  end

  private

  def marks = @steps.each_with_index.map { |step, index| Mark.new(step:, index:) }

  def mark_classes(step) = class_names(ScopeComponent::MARK, ScopeComponent::MARKS.fetch(step.kind))
end

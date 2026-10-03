# frozen_string_literal: true

# What a step does, under its strip: the explanation, the detail rows, and the
# optional artifact and note.
#
#   = render StepBodyComponent.new(step:)
#
# The type says who is speaking (docs/rules/typeface-means-speaker.md): the
# explanation, each row's value and the note are a person, in serif; group
# labels, row keys and the artifact are the machine, in mono. Every word comes
# from the step.
class StepBodyComponent < ApplicationComponent
  # The body's id, which its strip's aria-controls names.
  def self.id_for(step) = "#{step.key}-body"

  # @param step [DeliveryThread::Step]
  def initialize(step:)
    @step = step
  end

  private

  attr_reader :step

  def body_id = self.class.id_for(step)
end

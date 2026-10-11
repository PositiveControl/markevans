# frozen_string_literal: true

# One chip naming a project's language or a piece of its stack, as a list item.
#
#   ul aria-label="Stack"
#     - project.tags.each do |tag|
#       = render ChipComponent.new(name: tag)
#
# What a chip may say, and its kind, is StackRegistry. A language is ink on a
# strong rule; every other kind is quiet on a faint one. Neither uses a role
# color (docs/rules/color-means-role.md).
class ChipComponent < ApplicationComponent
  LOOKS = {
    true => "border-rule-strong text-ink",
    false => "border-rule text-quiet"
  }.freeze

  # @param name [String] a chip in StackRegistry
  # @raise [KeyError] when it is not
  def initialize(name:)
    @chip = StackRegistry[name]
  end

  private

  attr_reader :chip

  def look = LOOKS.fetch(chip.language?)
end

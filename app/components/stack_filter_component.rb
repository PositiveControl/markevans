# frozen_string_literal: true

# Narrows /work to the projects carrying one tag: All, then a link per tag in
# use, languages first.
#
#   = render StackFilterComponent.new(tags: Portfolio.tags, current: @tag)
#
# Each is a link, not a button, so the filter works without scripts and a
# filtered list has its own URL. The picked one is aria-current and links back
# to the whole list, and says so to a screen reader. Every link is at least 44 px (docs/rules/real-controls.md)
# and wears its chip's look until picked, when it turns ink, as the home
# thread's controller filter does; no role color (docs/rules/color-means-role.md).
class StackFilterComponent < ApplicationComponent
  Option = Data.define(:label, :tag, :look)

  LINK = "flex min-h-target min-w-target items-center justify-center rounded-box border px-2 no-underline " \
    "aria-[current=page]:border-ink aria-[current=page]:bg-ink aria-[current=page]:text-paper"

  # @param tags [Array<String>] chips in StackRegistry
  # @param current [String, nil] the picked tag; nil is All
  def initialize(tags:, current: nil)
    @current = current
    @options = [ Option.new(label: "All", tag: nil, look: ChipComponent::LOOKS.fetch(:language)) ] +
      tags.map { |tag| Option.new(label: tag, tag:, look: ChipComponent.look_for(StackRegistry[tag])) }
  end

  private

  attr_reader :options, :current

  def current?(option) = option.tag == current

  def href(option) = option.tag.nil? || current?(option) ? helpers.projects_path : helpers.projects_path(tag: option.tag)
end

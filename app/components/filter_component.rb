# frozen_string_literal: true

# Narrows a list to one value of a key: the home thread to one controller's
# lane, a project's findings to one kind.
#
#   = render FilterComponent.new(label: "Controller", key: "lane", options: DeliveryThread::LANE_NAMES)
#
# Toggle buttons with aria-pressed, All first, each at least 44 px (home thread
# design doc, section 4; docs/rules/real-controls.md). Each button carries its
# value as data-<key>, the attribute the rows carry too. The filter controller,
# keyed on the same name, holds which one is pressed and marks every row that
# does not match data-dim, and the rows style from it: they drop back, never
# hide. The filter is not playback state, so it is not in the playback
# controller (docs/rules/one-playback-state.md).
#
# Rendered hidden: without scripts there is nothing to filter with (section
# 6), so the filter controller reveals it on connect.
class FilterComponent < ApplicationComponent
  Option = Data.define(:value, :label)

  BUTTON = "min-h-target min-w-target cursor-pointer rounded-box border border-rule-strong px-2 text-ink " \
    "aria-pressed:border-ink aria-pressed:bg-ink aria-pressed:text-paper"

  # @param label [String] names the group, shown before the toggles
  # @param key [String] the data attribute the toggles and rows carry
  # @param options [Hash{String => String}] value to label, after All
  def initialize(label:, key:, options:)
    @label = label
    @key = key
    @options = [ Option.new(value: "all", label: "All") ] + options.map { |value, label| Option.new(value:, label:) }
  end

  private

  attr_reader :label, :key, :options

  def heading_id = "#{label.parameterize}-filter"

  def value_attribute(option) = { "data-#{key}" => option.value }
end

# frozen_string_literal: true

# Narrows the thread to one controller: All, Human, Agent or CI.
#
#   = render ControllerFilterComponent.new
#
# Toggle buttons with aria-pressed, each at least 44 px (design doc, section 4;
# docs/rules/real-controls.md). The filter controller holds which one is
# pressed and marks every row whose lane does not match data-dim, and the rows
# style from it: they drop back, never hide. The filter is not playback state,
# so it is not in the playback controller (docs/rules/one-playback-state.md).
#
# Rendered hidden: without scripts there is nothing to filter with (section
# 6), so the filter controller reveals it on connect.
class ControllerFilterComponent < ApplicationComponent
  Option = Data.define(:lane, :label)

  OPTIONS = [ Option.new(lane: "all", label: "All") ] +
    DeliveryThread::LANE_NAMES.map { |lane, label| Option.new(lane:, label:) }

  BUTTON = "min-h-target min-w-target cursor-pointer rounded-box border border-rule-strong px-2 text-ink " \
    "aria-pressed:border-ink aria-pressed:bg-ink aria-pressed:text-paper"
end

# frozen_string_literal: true

# The four playback controls: restart, step back, play or pause, step forward.
#
#   = render ControlsComponent.new
#
# Icon buttons named by aria-label, each a 44 px round target (design doc,
# section 4; docs/rules/real-controls.md). Play is the only filled one. While
# the page is playing it shows the pause icon, and the playback controller
# renames it Pause, or Replay on the last step.
#
# Rendered hidden: without scripts there is no playback to control (section
# 6), so the controller reveals it on connect.
class ControlsComponent < ApplicationComponent
  Control = Data.define(:label, :action, :icon)

  # Icon paths from the mock, on a 20 px grid.
  CONTROLS = [
    Control.new(label: "Restart", action: "restart", icon: [ "M4 10a6 6 0 1 0 2-4.5", "M3 3v3.5h3.5" ]),
    Control.new(label: "Step back", action: "back", icon: [ "M14 4.5v11L6.5 10z", "M5 4.5v11" ]),
    Control.new(label: "Play", action: "toggle", icon: nil),
    Control.new(label: "Step forward", action: "forward", icon: [ "M6 4.5v11l7.5-5.5z", "M15 4.5v11" ])
  ].freeze

  PLAY = "M7 4.5v11l8.5-5.5z"
  PAUSE = [ "M7 4.5v11", "M13 4.5v11" ].freeze

  BUTTON = "flex size-target shrink-0 cursor-pointer items-center justify-center rounded-full border"
  PLAIN = "border-rule-strong bg-paper text-ink"
  FILLED = "border-ink bg-ink text-paper"

  private

  def classes(control) = class_names(BUTTON, control.icon ? PLAIN : FILLED)
end

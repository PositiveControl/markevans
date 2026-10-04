# frozen_string_literal: true

# Which bay the active step sits in: Todo, In Progress, Up for Review, Done.
#
#   = render StripBayComponent.new
#
# Four equal cells; the active step's bay is filled ink (design doc, section
# 4). The playback controller marks that cell data-current, and the cell styles
# from its own attribute, so no class name is written by script
# (docs/rules/one-playback-state.md). The fill is not the only signal: the
# controller also sets aria-current on that cell (docs/rules/never-color-alone.md).
#
# Rendered hidden: without scripts no step is active (section 6), so the
# controller reveals it on connect.
class StripBayComponent < ApplicationComponent
  BAYS = DeliveryThread::BAYS

  CELL = "flex-1 border-l border-rule-strong px-0.5 py-2 text-quiet transition-colors duration-150 ease-out " \
    "first:border-l-0 in-data-settling:transition-none motion-reduce:transition-none " \
    "data-current:bg-ink data-current:text-paper"
end

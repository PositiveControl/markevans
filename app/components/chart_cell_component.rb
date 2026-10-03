# frozen_string_literal: true

# One row of the git graph, drawn beside the step's strip from its git block.
#
#   - @thread.cells.each do |cell|
#     = render ChartCellComponent.new(cell:)
#
# What the row draws comes from the step's git block (design doc, section 5)
# and from the cell's context: the branches running through it and whether it
# starts a sector (DeliveryThread::Sequence#cells). No row index or step key
# appears here, so the graph follows the file (docs/rules/topology-from-data.md).
#
# Lines are 2 px borders, absolutely placed. Their positions are composed from
# the chart tokens in tokens.css with var() and calc(), so no pixel value lives
# here (docs/rules/tokens-only.md). Tops and bottoms are set from the row's
# edges, so every line stretches when the row grows. Decoration only: the
# strip beside it says everything in words. While playback runs, an upcoming
# row's lines and fix dim, and the active step's fix wears a ring.
class ChartCellComponent < ApplicationComponent
  # One positioned line: what it is, its classes, its inline position.
  Piece = Data.define(:part, :classes, :style)

  LANES = {
    "main" => "var(--spacing-lane-main)",
    "feature" => "var(--spacing-lane-feature)",
    "side" => "var(--spacing-lane-side)"
  }.freeze

  # Each line's colour and style, as the legend shows it.
  LINES = {
    "main" => "border-ink",
    "feature" => "border-command",
    "side" => "border-quiet border-dashed"
  }.freeze

  LABELS = { "main" => "text-ink", "feature" => "text-command", "side" => "text-quiet" }.freeze

  # Sector bands: In Progress and Done share the light band (design doc, section 3).
  SECTORS = {
    "Todo" => nil,
    "In Progress" => "bg-sector-1",
    "Up for Review" => "bg-sector-2",
    "Done" => "bg-sector-1"
  }.freeze

  # The active step's ring, in its kind's color (design doc, section 3).
  RINGS = {
    "command" => "border-command",
    "human" => "border-human",
    "machine" => "border-machine",
    "optional" => "border-quiet"
  }.freeze

  # Playback writes data-state on the row (docs/system/home-thread-playback.md).
  # An upcoming row's graph dims; its words do not, since text at 35 percent
  # fails contrast. Without scripts nothing is set and every row is full.
  GRAPH = "absolute inset-0 transition-opacity duration-150 ease-out in-data-settling:transition-none " \
    "in-data-[state=pending]:opacity-35"

  FIX = "var(--spacing-fix)"
  ELBOW = "var(--spacing-elbow)"
  INSET = "var(--spacing-loop-inset)"
  # An elbow box's top: its bottom border, 2 px tall, is centred on the fix.
  ELBOW_TOP = "calc(#{FIX} - #{ELBOW} + var(--spacing-line-half))"

  VERTICAL = "absolute -translate-x-1/2 border-l-2"
  # Offset by the line's half-width so each elbow's leg sits on its lane;
  # ELBOW_TOP does the same for its arm and the fix.
  FORK_ELBOW = "absolute -translate-x-px border-b-2 border-l-2"
  MERGE_ELBOW = "absolute translate-x-px border-r-2 border-b-2"
  BRACKET = "absolute translate-x-px border-2 border-l-0 border-dashed"

  # @param cell [DeliveryThread::Cell]
  def initialize(cell:)
    @cell = cell
  end

  private

  attr_reader :cell

  def step = cell.step

  def git = step.git

  def classes
    class_names("relative w-column shrink-0 self-stretch", SECTORS.fetch(step.bay))
  end

  def pieces
    [ main, *cell.through.map { |branch| vertical("through", branch, top: "0", bottom: "0") }, *event ]
  end

  def main
    case git.event
    when "start" then vertical("main", "main", top: FIX, bottom: "0")
    when "end" then vertical("main", "main", top: "0", height: FIX)
    else vertical("main", "main", top: "0", bottom: "0")
    end
  end

  def event
    case git.event
    when "fork"
      [ elbow(FORK_ELBOW, git.from, git.on, git.on, "border-bottom-left-radius"),
        vertical("branch", git.on, top: FIX, bottom: "0") ]
    when "merge"
      [ vertical("branch", git.from, top: "0", height: ELBOW_TOP),
        elbow(MERGE_ELBOW, git.on, git.from, git.from, "border-bottom-right-radius") ]
    when "loop"
      [ Piece.new("loop", "#{BRACKET} #{LINES.fetch('side')}",
          position(left: lane(git.from), width: span(git.from, "side"), top: INSET, bottom: INSET,
            "border-top-right-radius": ELBOW, "border-bottom-right-radius": ELBOW)) ]
    else []
    end
  end

  def vertical(part, branch, **edges)
    Piece.new(part, "#{VERTICAL} #{LINES.fetch(branch)}", position(left: lane(branch), **edges))
  end

  # A corner from the left lane to the right one, meeting the fix's row.
  def elbow(classes, left, right, branch, corner)
    Piece.new("elbow", "#{classes} #{LINES.fetch(branch)}",
      position(left: lane(left), width: span(left, right), top: ELBOW_TOP, height: ELBOW, corner => ELBOW))
  end

  def lane(branch) = LANES.fetch(branch)

  def span(from, to) = "calc(#{lane(to)} - #{lane(from)})"

  def position(**edges) = edges.map { |edge, value| "#{edge}: #{value}" }.join("; ")

  def fix_style = position(left: lane(git.on), top: FIX)

  # Beside the fix, except on a merge, where the elbow crosses at the fix's
  # height: there the label drops below it, by the same offset.
  def label_style
    top = git.event == "merge" ? "calc(#{FIX} + var(--spacing-chart-label))" : FIX
    position(left: "calc(#{lane(git.on)} + var(--spacing-chart-label))", top:)
  end

  def ring_classes
    class_names("absolute hidden size-ring -translate-1/2 rounded-full border-2 bg-paper in-data-[state=active]:block",
      RINGS.fetch(step.kind))
  end

  def label_classes = "absolute -translate-y-1/2 whitespace-nowrap font-mono text-label #{LABELS.fetch(git.on)}"
end

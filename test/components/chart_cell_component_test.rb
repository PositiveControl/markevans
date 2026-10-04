# frozen_string_literal: true

require "test_helper"

# Rows come from the fixture threads in test/fixtures/files/threads, not from
# content/threads/home.yml, so the graph is shown to follow whatever the file
# says (docs/rules/topology-from-data.md). Steps are looked up by key here, in
# the test; the component itself never sees one.
class ChartCellComponentTest < ViewComponent::TestCase
  MAIN = "var(--spacing-lane-main)"
  FEATURE = "var(--spacing-lane-feature)"
  SIDE = "var(--spacing-lane-side)"
  FIX = "var(--spacing-fix)"
  # The elbow box's top, set so its 2 px arm is centred on the fix.
  ELBOW_TOP = "calc(#{FIX} - var(--spacing-elbow) + var(--spacing-line-half))"

  test "the cell is decoration: hidden from assistive technology" do
    render_cell "build"

    assert_selector "div[aria-hidden=true]"
  end

  test "main runs the full height of a plain row, from the fix down on start, and to the fix on end" do
    render_cell "build"
    assert_line "main", left: MAIN, top: "0", bottom: "0"

    render_cell "begin"
    assert_line "main", left: MAIN, top: FIX, bottom: "0"

    render_cell "ship"
    assert_line "main", left: MAIN, top: "0", height: FIX
  end

  test "a fork draws a rounded elbow from its parent into the fix, and the branch on from there" do
    render_cell "plan"

    assert_selector "div[data-git-event=fork]"
    elbow = piece("elbow")
    assert_includes elbow[:style], "left: #{MAIN}"
    assert_includes elbow[:style], "width: calc(#{FEATURE} - #{MAIN})"
    assert_includes elbow[:style], "height: var(--spacing-elbow)"
    assert_includes elbow[:style], "top: #{ELBOW_TOP}"
    assert_includes elbow[:style], "border-bottom-left-radius: var(--spacing-elbow)"
    assert_includes elbow[:class], "border-command"
    assert_line "branch", left: FEATURE, top: FIX, bottom: "0"
    assert_fix_on FEATURE
  end

  test "a merge brings the branch down to a mirrored elbow into its parent" do
    render_cell "land"

    assert_selector "div[data-git-event=merge]"
    assert_line "branch", left: FEATURE, top: "0", height: ELBOW_TOP
    elbow = piece("elbow")
    assert_includes elbow[:style], "left: #{MAIN}"
    assert_includes elbow[:style], "width: calc(#{FEATURE} - #{MAIN})"
    assert_includes elbow[:style], "border-bottom-right-radius: var(--spacing-elbow)"
    assert_includes elbow[:style], "top: #{ELBOW_TOP}"
    assert_includes elbow[:class], "border-command"
    assert_no_selector "[data-chart=through]"
    assert_fix_on MAIN
  end

  test "a loop draws a dashed bracket out to the side lane, inset so it stretches with the row" do
    render_cell "aside"

    loop = piece("loop")
    assert_includes loop[:style], "left: #{MAIN}"
    assert_includes loop[:style], "width: calc(#{SIDE} - #{MAIN})"
    assert_includes loop[:style], "top: var(--spacing-loop-inset)"
    assert_includes loop[:style], "bottom: var(--spacing-loop-inset)"
    assert_includes loop[:class], "border-dashed"
    assert_includes loop[:class], "border-quiet"
    assert_fix_on SIDE
  end

  test "a loop off the feature leaves the feature line, which runs on through the row" do
    render_cell "check"

    assert_includes piece("loop")[:style], "left: #{FEATURE}"
    assert_line "through", left: FEATURE, top: "0", bottom: "0"
  end

  test "a branch that is open runs through a plain row, and nothing else does" do
    render_cell "build"
    assert_line "through", left: FEATURE, top: "0", bottom: "0"

    render_cell "begin"
    assert_no_selector "[data-chart=through]"
  end

  test "a branch label sits beside the fix, in its line's colour, only where the file gives one" do
    render_cell "plan"
    label = piece("label")
    assert_equal "feature/x", label.text
    assert_includes label[:style], "left: calc(#{FEATURE} + var(--spacing-chart-label))"
    assert_includes label[:class], "text-command"

    render_cell "aside"
    assert_includes piece("label")[:class], "text-quiet"

    render_cell "build"
    assert_no_selector "[data-chart=label]"
  end

  test "on a merge the label drops below the fix, clear of the elbow that runs across at its height" do
    render_cell "land"
    label = piece("label")
    assert_equal "merge to main", label.text
    assert_includes label[:style], "left: calc(#{MAIN} + var(--spacing-chart-label))"
    assert_includes label[:style], "top: calc(#{FIX} + var(--spacing-chart-label))"

    render_cell "plan"
    assert_includes piece("label")[:style], "top: #{FIX}"
  end

  test "a row that starts a sector carries its label and a dashed top border; the next does not" do
    render_cell "build"
    assert_selector "div[aria-hidden].bg-sector-1"
    assert_selector "[data-chart=sector-edge].border-t.border-dashed"
    assert_selector "[data-chart=sector]", text: "Sector · In Progress"

    render_cell "check"
    assert_selector "div[aria-hidden].bg-sector-1"
    assert_no_selector "[data-chart=sector-edge]"
    assert_no_selector "[data-chart=sector]"
  end

  test "the cell has no border of its own, so lines meet the row above without a gap" do
    render_cell "build"

    assert_no_selector "div[aria-hidden][class*=border]"
  end

  test "each bay takes its own sector tint" do
    render_cell "begin"
    assert_no_selector "div[aria-hidden][class*=bg-sector]"

    render_cell "land", thread: "small"
    assert_selector "div[aria-hidden].bg-sector-1"

    render_inline(ChartCellComponent.new(cell: cell("build").with(sector: "Up for Review", step: cell("build").step.with(bay: "Up for Review"))))
    assert_selector "div[aria-hidden].bg-sector-2"
  end

  test "the fix takes its kind's symbol" do
    render_cell "gate"
    assert_selector "[data-chart=fix] svg.text-human polygon.fill-current"

    render_cell "aside"
    assert_selector "[data-chart=fix] svg.text-quiet polygon[stroke-dasharray]"
  end

  test "the ring marks the active step's fix, in its kind's color, behind the fix" do
    render_cell "gate"

    ring = page.find("[data-chart=ring]", visible: :all)
    assert_equal piece("fix")[:style], ring[:style]
    assert_includes ring[:class].split, "border-human"
    assert_includes ring[:class].split, "size-ring"
    assert_includes ring[:class].split, "in-data-[state=active]:block"
    assert_selector "[data-chart=ring] ~ [data-chart=fix]", visible: :all
  end

  test "an upcoming row's lines and fix dim to 35 percent; its words stay legible" do
    render_cell "plan"

    assert_selector "[data-chart=graph].in-data-\\[state\\=pending\\]\\:not-in-data-dim\\:opacity-35 [data-chart=fix]"
    assert_selector "[data-chart=graph] [data-chart=main]"
    assert_no_selector "[data-chart=graph] [data-chart=label]"
  end

  test "a done or active row the filter drops back dims its lines and fix to 40 percent" do
    render_cell "plan"

    assert_selector "[data-chart=graph].in-data-\\[state\\=done\\]\\:in-data-dim\\:opacity-40" \
      ".in-data-\\[state\\=active\\]\\:in-data-dim\\:opacity-40 [data-chart=fix]"
    assert_no_selector "[data-chart=graph].in-data-dim\\:opacity-40"
  end

  test "an upcoming row the filter drops back dims below 35 percent, so filtering shows" do
    render_cell "plan"

    assert_selector "[data-chart=graph].in-data-\\[state\\=pending\\]\\:in-data-dim\\:opacity-15"
  end

  test "reordering the file redraws the graph: the loop off main follows its step, not its row" do
    small = rows("small")
    reordered = rows("reordered")

    assert_equal 1, small.index { |row| row[:name] == "/aside" }
    assert_equal 6, reordered.index { |row| row[:name] == "/aside" }
    [ small, reordered ].each do |thread|
      aside = thread.find { |row| row[:name] == "/aside" }
      assert aside[:loop], "the loop is drawn on /aside's row"
      assert_equal 1, thread.count { |row| row[:loop] && row[:from_main] }
    end
    assert_equal [ "Todo", "In Progress", "Done", "Todo", "Done" ], reordered.filter_map { |row| row[:sector] }
  end

  private

  def thread(name) = DeliveryThread.load(file_fixture("threads/#{name}.yml"))

  def cell(key, thread: "small") = thread(thread).cells.find { |cell| cell.step.key == key }

  def render_cell(key, thread: "small") = render_inline(ChartCellComponent.new(cell: cell(key, thread:)))

  def piece(part)
    assert_selector "[data-chart=#{part}]", count: 1
    page.find("[data-chart=#{part}]")
  end

  def assert_line(part, **edges)
    style = piece(part)[:style]
    edges.each { |edge, value| assert_includes style, "#{edge}: #{value}", "#{part} #{edge}" }
  end

  def assert_fix_on(lane)
    assert_includes piece("fix")[:style], "left: #{lane}"
  end

  # Each row as drawn, paired with its step's name from the strip it sits beside.
  def rows(name)
    thread(name).cells.map do |cell|
      render_inline(ChartCellComponent.new(cell:))
      loop = page.first("[data-chart=loop]", minimum: 0)
      { name: cell.step.name, loop: loop.present?, from_main: loop&.[](:style)&.include?("left: #{MAIN}"),
        sector: page.first("[data-chart=sector]", minimum: 0)&.text&.delete_prefix("Sector · ") }
    end
  end
end

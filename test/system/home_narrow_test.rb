# frozen_string_literal: true

require "application_system_test_case"

# The home thread on a narrow screen (design doc, section 4; #19): below
# 900 px the chart is an 84 px gutter, the top row stacks, every control keeps
# a 44 px target and nothing scrolls sideways. The docked bar holds one row,
# under the 96 px line the page follows to, at every width.
class HomeNarrowTest < ApplicationSystemTestCase
  PLAYER = "[data-controller~=playback]"
  DOCK = "[aria-label='Docked playback']"
  PHONE = [ 390, 844 ].freeze

  setup do
    @steps = DeliveryThread.fetch(:home).steps
  end

  test "at 390 px nothing scrolls sideways: playing, docked, and with every strip reopened" do
    at_size(*PHONE) do
      visit root_path
      scroll_to find("##{@steps.first.key}"), align: :top
      assert_selector "#{PLAYER}[data-playing]"
      assert_no_sideways_scroll

      assert_selector DOCK
      assert_no_sideways_scroll

      find("[aria-label=Scope] [data-playback-target=target][href='##{@steps.last.key}']", visible: :all)
        .execute_script("this.click()")
      @steps[0...-1].each { |step| find("##{step.key} h3 button").execute_script("this.click()") }
      assert_selector "[data-open=true]", count: @steps.size
      assert_no_sideways_scroll
    end
  end

  test "at 390 px nothing scrolls sideways without scripts, every strip open" do
    at_size(*PHONE) do
      without_scripts do
        visit root_path
        assert_selector "##{@steps.last.key} h3", text: @steps.last.name
        assert_no_sideways_scroll
      end
    end
  end

  test "below 900 px the chart is an 84 px gutter, lanes at 14, 38 and 62 px, with no sector or branch labels" do
    at_size(899, 1000) do
      visit root_path
      fork = @steps.find { |step| step.git.event == "fork" }
      loop_step = @steps.find { |step| step.git.event == "loop" }

      assert_equal 84, cell_box(fork.key)["width"]
      assert_equal 14, line_centre(fork.key, "main")
      assert_equal 38, line_centre(fork.key, "branch")
      assert_equal 62, cell_box(loop_step.key, "[data-chart=loop]")["right"] - cell_box(loop_step.key)["left"] - 1
      assert_no_selector "[data-chart=label]"
      assert_no_selector "[data-chart=sector]"
    end
  end

  test "from 900 px the chart is the full 400 px column with its labels" do
    at_size(900, 1000) do
      visit root_path
      fork = @steps.find { |step| step.git.event == "fork" }

      assert_equal 400, cell_box(fork.key)["width"]
      assert_equal 44, line_centre(fork.key, "main")
      assert_selector "[data-chart=label]"
      assert_selector "[data-chart=sector]"
    end
  end

  test "the top row stacks: the scope above the headline, as wide as the page allows" do
    at_size(*PHONE) do
      visit root_path

      scope = box("[aria-label=Scope]")
      assert_operator scope["bottom"], :<=, box("h1")["top"]
      assert_operator scope["width"], :<=, 400
    end
  end

  test "at 390 px every control and docked control is a named target of at least 44 px" do
    at_size(*PHONE) do
      visit root_path
      assert_selector "[aria-label=Restart]"
      assert_targets "main button, main [data-playback-target=target]", 4 + 4 + @steps.size * 2

      execute_script("window.scrollTo(0, document.querySelector('##{@steps.first.key}').offsetTop)")
      assert_selector DOCK
      assert_targets "#{DOCK} button, #{DOCK} a", 4
      assert_selector "#{DOCK} [data-playback-target=readoutName]", text: @steps.first.name
      assert_no_selector "#{DOCK} [data-playback-target=bay]"
    end
  end

  [ 390, 1024, 1100, 1400 ].each do |width|
    test "docked bar: one row, under the 96 px line, at #{width} px wide" do
      at_size(width, 1000) do
        visit root_path
        assert_selector "[aria-label=Restart]"
        execute_script("window.scrollTo(0, document.querySelector('[aria-label=Scope]').getBoundingClientRect().bottom + window.scrollY + 1)")

        assert_selector DOCK
        assert_operator box(DOCK)["bottom"], :<=, 96
      end
    end
  end

  test "the wheel that scrolls the thread into view starts it, and the rest of that scroll does not pause it" do
    at_size(*PHONE) do
      visit root_path
      assert_selector "[aria-label=Restart]"

      # One gesture, as a wheel sends it: ticks 50 ms apart, sent as one chain
      # so the driver's own round trips cannot open gaps in it. It starts
      # above the thread and runs on past where it comes into view.
      gesture = page.driver.browser.action
      30.times { gesture.scroll_by(0, 120).pause(duration: 0.05) }
      gesture.perform
      assert playing?, "the scroll that brought the thread into view paused it"

      sleep 0.5 # the reader stops; their next scroll is a new one
      wheel
      assert_no_selector "#{PLAYER}[data-playing]"
    end
  end

  private

  # The viewport at that size. Headless Chrome will not size a window under
  # about 500 px, so the page is emulated at it, as DevTools' device mode does.
  def at_size(width, height)
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height:, deviceScaleFactor: 1, mobile: false)
    yield
  ensure
    browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  def wheel = page.driver.browser.action.scroll_by(0, 120).perform

  def playing? = has_selector?("#{PLAYER}[data-playing]", wait: 0)

  def assert_no_sideways_scroll
    widths = evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")
    assert_operator widths.first, :<=, widths.last, "the page is #{widths.first} px wide in a #{widths.last} px viewport"
  end

  def box(selector)
    evaluate_script("(r => ({ top: r.top, bottom: r.bottom, left: r.left, right: r.right, width: r.width }))" \
      "(document.querySelector(\"#{selector}\").getBoundingClientRect())")
  end

  def cell_box(key, inner = "") = box("##{key} > [aria-hidden=true] #{inner}".strip)

  # A vertical line's centre, from its cell's left edge.
  def line_centre(key, part)
    line = cell_box(key, "[data-chart=#{part}]")
    (line["left"] + line["width"] / 2.0 - cell_box(key)["left"]).round
  end

  def assert_targets(selector, count)
    sizes = evaluate_script(<<~JS)
      [...document.querySelectorAll("#{selector}")]
        .filter(el => el.offsetParent)
        .map(el => { const r = el.getBoundingClientRect(); return [el.getAttribute("aria-label") || el.textContent.trim(), r.width, r.height] })
    JS
    assert_equal count, sizes.size
    sizes.each do |name, width, height|
      assert name.present?, "a control has no name"
      assert_operator [ width, height ].min, :>=, 44, "#{name} is #{width}×#{height}"
    end
  end
end

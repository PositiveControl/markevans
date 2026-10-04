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

  [ 390, 1024, 1100, 1280, 1400 ].each do |width|
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
      gesture = wheel_gesture
      30.times { gesture.scroll_by(0, 120).pause(duration: 0.05) }
      gesture.perform
      assert playing?, "the scroll that brought the thread into view paused it"

      sleep 0.5 # the reader stops; their next scroll is a new one
      wheel
      assert_no_selector "#{PLAYER}[data-playing]"
    end
  end

  test "the arriving scroll still drops a g waiting for its number, though it does not pause" do
    gate = @steps.index(&:gate?)
    at_size(*PHONE) do
      visit root_path
      assert_selector "[aria-label=Restart]"

      # g pressed once the thread is playing, mid-gesture, and the scroll goes
      # on. Played inside the page, 50 ms a tick: Selenium drops wheel ticks
      # that follow a key in one action chain.
      evaluate_async_script(<<~JS)
        const done = arguments[0], tick = () => new Promise(resolve => setTimeout(resolve, 50))
        const press = key => document.body.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true }))
        ;(async () => {
          for (let i = 0; i < 24; i++) {
            if (i === 20) press("g")
            window.scrollBy(0, 120)
            window.dispatchEvent(new WheelEvent("wheel", { deltaY: 120 }))
            await tick()
          }
          done()
        })()
      JS
      assert playing?, "the arriving scroll paused it"

      page.driver.browser.action.send_keys("1").perform
      assert_no_selector "##{@steps[gate].key}[data-state=active]", wait: 0.5
    end
  end

  test "the arriving scroll still drops the follow to a step the clock moves to, though it does not pause" do
    at_size(*PHONE) do
      visit root_path
      assert_selector "[aria-label=Restart]"
      # A 6 s step lasts 300 ms, so steps advance mid-gesture. A follow waits
      # out the 200 ms roll-up, and a tick every 50 ms lands inside that.
      execute_script("document.querySelector('#{PLAYER}').dataset.playbackPaceValue = 50")

      # A follow moves the page with scrollIntoView and nothing else does, so
      # the gesture counts its calls. Played inside the page, as above.
      followed, advanced = using_wait_time(5) { evaluate_async_script(<<~JS) }
        const done = arguments[0], tick = () => new Promise(resolve => setTimeout(resolve, 50))
        const rows = [...document.querySelectorAll("#{PLAYER} [data-playback-target=row]")]
        const active = () => rows.findIndex(row => row.dataset.state === "active")
        const scrollIntoView = Element.prototype.scrollIntoView
        let followed = 0
        Element.prototype.scrollIntoView = function (...args) {
          followed++
          return scrollIntoView.apply(this, args)
        }
        ;(async () => {
          for (let i = 0; i < 40; i++) {
            window.scrollBy(0, 120)
            window.dispatchEvent(new WheelEvent("wheel", { deltaY: 120 }))
            await tick()
          }
          Element.prototype.scrollIntoView = scrollIntoView
          done([followed, active()])
        })()
      JS
      assert playing?, "the arriving scroll paused it"
      assert_operator advanced, :>=, 2, "no step advanced during the gesture, so nothing was there to follow"
      assert_equal 0, followed, "a follow scrolled the page during the arriving scroll"
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

  # Ticks with no duration of their own, so each lands as one wheel event, as
  # a real wheel sends them. Selenium's default spreads each over 250 ms.
  def wheel_gesture = page.driver.browser.action.tap { |action| action.default_scroll_duration = 0 }

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

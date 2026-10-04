# frozen_string_literal: true

require "application_system_test_case"

# The home thread in a browser: the playback controller and the views that
# render from it (docs/system/home-thread-playback.md). Each test names the row
# of the design doc's event table (section 6) it covers. Steps are picked by
# position or kind, never by key, so the tests follow the thread file.
class HomePlaybackTest < ApplicationSystemTestCase
  # Milliseconds per second of step time: a 6 s step takes 300 ms here.
  FAST = 50

  setup do
    @thread = DeliveryThread.fetch(:home)
    @steps = @thread.steps
    @gate = @steps.index { |step| step.kind == "human" }
  end

  test "without scripts the page passes axe, every strip open" do
    without_scripts do
      visit root_path

      assert_selector "##{@steps.last.key} h3", text: @steps.last.name
      assert_no_selector "[data-state]"
      assert_accessible
    end
  end

  test "page loads: the first render settles at once, and only a change of state animates" do
    visit root_path
    assert_selector "[aria-label=Restart]"

    assert_equal 0, evaluate_script("document.getAnimations().filter(a => a instanceof CSSTransition).length")
    assert_no_selector "main[data-settling]"
  end

  test "thread first scrolls into view: it starts playing on step 1" do
    resize_to(400) do
      visit root_path
      assert_selector "[aria-label=Restart]"
      assert_not playing?

      scroll_to find("##{@steps.first.key}"), align: :center

      assert_selector "main[data-playing]"
      assert_step 0, status: active_word(0)
    end
  end

  test "play or pause pressed: toggles playing" do
    open_thread

    click_control "Pause"
    assert_not playing?
    assert_step 0, status: "paused"
    assert_selector "[aria-label=Play]"

    click_control "Play"
    assert_selector "main[data-playing]"
    assert_step 0, status: "active"
  end

  test "step back, step forward: moves one step and pauses" do
    open_thread

    click_control "Step forward"
    assert_not playing?
    assert_step 1, status: "paused"
    assert_row 0, state: "done", open: "false", status: "done"

    click_control "Step back"
    assert_step 0, status: "paused"
    assert_row 1, state: "pending", status: "pending"
  end

  test "a target selected: jumps there and pauses, and the leader points at it" do
    open_thread

    target(@gate).click

    assert_not playing?
    assert_step @gate, status: "paused"
    assert_row @gate - 1, state: "done", status: "done"
    assert_selector "[data-playback-target=target][aria-current=step]", count: 1
    assert_equal "#{target(@gate)[:"data-angle"]}deg", evaluate_script("document.querySelector('main').style.getPropertyValue('--leader-angle')")
    assert_equal root_path, URI(current_url).request_uri, "a jump moves no hash"
  end

  test "the active step selected: pauses, keeping the time it has left" do
    open_thread
    sleep 0.5 # let the clock run

    target(0).click

    assert_not playing?
    assert_step 0, status: "paused"
    assert_operator line_time(0), :>=, 400, "the line was rewound"
  end

  test "a pending strip selected: jumps there and pauses" do
    open_thread

    strip(3).click

    assert_not playing?
    assert_step 3, status: "paused"
  end

  test "a done strip selected: opens or closes it, playback unchanged" do
    open_thread
    target(3).click
    click_control "Play"

    strip(1).click
    assert_row 1, state: "done", open: "true"
    assert_selector "##{@steps[1].key} h3 button[aria-expanded=true]"
    assert playing?
    assert_step 3, status: active_word(3)

    strip(1).click
    assert_row 1, state: "done", open: "false"
    assert_selector "##{@steps[1].key} h3 button[aria-expanded=false]"
    assert_selector "##{@steps[1].key}-body", visible: :hidden
  end

  test "restart: step 1, reopened strips cleared, paused" do
    open_thread
    target(4).click
    strip(1).click
    assert_row 1, open: "true"

    click_control "Restart"

    assert_not playing?
    assert_step 0, status: "paused"
    assert_row 1, state: "pending", open: "false"
  end

  test "tab becomes hidden: pauses, and does not resume by itself" do
    open_thread(pace: FAST)

    execute_script(<<~JS)
      Object.defineProperty(document, "visibilityState", { value: "hidden", configurable: true })
      document.dispatchEvent(new Event("visibilitychange"))
    JS

    assert_not playing?
    step = current_step
    sleep FAST * 6 * 2 / 1000.0 # two steps' time: nothing may advance or resume
    assert_not playing?
    assert_equal step, current_step
  end

  test "a page restored from Turbo's cache comes back paused: nothing resumes by itself" do
    resize_to(400) do # the thread out of view, so only the restored value could start it
      visit root_path
      click_control "Play"
      assert_selector "main[data-playing]"

      restore_from_cache

      assert_no_selector "main[data-playing]"
      assert_selector "[aria-label=Play]"
    end
  end

  test "a restored page the reader had paused stays paused with the thread in view" do
    open_thread
    click_control "Pause"

    restore_from_cache
    sleep 0.5 # the reconnect, and the first view it would have taken for a fresh load

    assert_not playing?
    assert_step 0, status: "paused"
  end

  test "a restored page whose thread had played out still counts the last step" do
    open_thread
    target(@steps.size - 2).click
    pace FAST
    click_control "Play"
    assert_selector "[aria-label=Replay]"

    restore_from_cache
    sleep 0.5 # the reconnect

    assert_selector "[aria-label=Replay]"
    assert_selector "[data-playback-target=logEntry]", count: @steps.size
    assert_log_counts @steps.count(&:gate?), @steps.count(&:artifact)
  end

  test "step timer ends: next step active, previous strip rolls up" do
    open_thread(pace: FAST)

    assert_step 1, status: "active"
    assert_row 0, state: "done", open: "false", status: "done"
  end

  test "a gate holds while active and reads cleared once passed" do
    open_thread
    target(@gate).click
    click_control "Play"

    assert_step @gate, status: "hold"
    click_control "Step forward"
    assert_row @gate, state: "done", status: "cleared"
  end

  test "timer ends on the last step: stops, the log counts it, and Play becomes Replay, which restarts from step 1" do
    open_thread
    target(@steps.size - 2).click
    pace FAST
    click_control "Play"

    assert_selector "[aria-label=Replay]"
    assert_not playing?
    assert_step @steps.size - 1
    assert_selector "[data-playback-target=logEntry]", count: @steps.size
    assert_equal @steps.last.name, first("[data-playback-target=logEntry] span.font-medium").text
    assert_log_counts @steps.count(&:gate?), @steps.count(&:artifact)

    click_control "Replay"
    assert_selector "main[data-playing]"
    assert_step 0, status: "active"
    assert_selector "[data-playback-target=logEmpty]"
  end

  test "the strip bay fills the active step's bay, and follows a jump into the next" do
    open_thread
    assert_bay @steps[0].bay

    later = @steps.index { |step| step.bay != @steps[0].bay }
    target(later).click

    assert_bay @steps[later].bay
  end

  test "the controller filter drops other controllers' rows back, never hides them, and leaves playback alone" do
    open_thread
    human = @steps.each_index.select { |index| @steps[index].lane == "human" }
    others = @steps.each_index.to_a - human
    target(others.first).click # a passed or active row: an upcoming one is dimmer still
    click_control "Play"

    click_filter "Human"

    assert_equal "true", filter("Human")[:"aria-pressed"]
    assert_equal "false", filter("All")[:"aria-pressed"]
    assert_selector "[data-filter-target=row][data-dim]", count: others.size
    others.each { |index| assert_selector "##{@steps[index].key}[data-dim]" }
    human.each { |index| assert_selector "##{@steps[index].key}:not([data-dim])" }
    @steps.each { |step| assert_selector "##{step.key} h3", visible: true }
    assert_computed "0.4", @steps[others.first].key, "[data-chart=graph]", "opacity"
    upcoming = others.find { |index| index > others.first }
    kept = human.find { |index| index > others.first }
    assert_computed "0.35", @steps[kept].key, "[data-chart=graph]", "opacity"
    assert_computed "0.15", @steps[upcoming].key, "[data-chart=graph]", "opacity" # below an upcoming row it keeps
    assert playing?

    click_filter "All"

    assert_no_selector "[data-dim]"
    assert_selector "[data-filter-target=option][aria-pressed=true]", count: 1, text: "All"
  end

  test "the log is one line on step 1, then lists finished steps newest first with what they add up to" do
    open_thread
    assert_selector "[data-playback-target=logEmpty]", text: "Nothing completed yet."
    assert_no_selector "[data-playback-target=logEntry]"
    assert_log_counts 0, 0

    target(@gate + 1).click

    finished = @steps.first(@gate + 1)
    names = all("[data-playback-target=logEntry]").map { |entry| entry.find("span.font-medium").text }
    assert_equal finished.map(&:name).reverse, names
    assert_selector "[data-playback-target=logEntry]", text: "CLEARED", count: finished.count(&:gate?)
    assert_no_selector "[data-playback-target=logEmpty]"
    assert_log_counts finished.count(&:gate?), finished.count(&:artifact)

    click_control "Restart"
    assert_selector "[data-playback-target=logEmpty]"
    assert_log_counts 0, 0
  end

  test "the log scrolls inside 220 px once it fills" do
    open_thread
    target(@steps.size - 1).click

    height, scroll = evaluate_script(<<~JS)
      (r => [r.clientHeight, r.scrollHeight])(document.querySelector("[aria-label='Log entries']"))
    JS
    assert_operator height, :<=, 220
    assert_operator scroll, :>, height
    finished = @steps[0...-1]
    assert_log_counts finished.count(&:gate?), finished.count(&:artifact)
  end

  test "the remaining-time line runs on the active strip and freezes when paused" do
    open_thread

    assert_equal "running", line_state(0)
    click_control "Pause"
    assert_equal "paused", line_state(0)
  end

  test "upcoming chart rows are dimmed, and the active fix wears the ring" do
    open_thread
    click_control "Pause"

    assert_computed "0.35", @steps[1].key, "[data-chart=graph]", "opacity"
    assert_computed "1", @steps[0].key, "[data-chart=graph]", "opacity"
    assert_selector "##{@steps[0].key} [data-chart=ring]"
    assert_no_selector "##{@steps[1].key} [data-chart=ring]"
  end

  test "every control is a named target of at least 44 px" do
    open_thread
    click_control "Pause"

    sizes = evaluate_script(<<~JS)
      [...document.querySelectorAll("main button, main [data-playback-target=target]")]
        .filter(el => el.offsetParent)
        .map(el => { const r = el.getBoundingClientRect(); return [el.getAttribute("aria-label") || el.textContent.trim(), r.width, r.height] })
    JS
    assert_equal 4 + 4 + @steps.size * 2, sizes.size
    sizes.each do |name, width, height|
      assert name.present?, "a control has no name"
      assert_operator [ width, height ].min, :>=, 44, "#{name} is #{width}×#{height}"
    end
  end

  test "axe passes while playing, while paused, and with a filter on" do
    open_thread
    assert_accessible

    click_control "Pause"
    assert_accessible

    click_filter "Agent"
    assert_accessible
  end

  private

  # Opens the page and waits for the thread to start playing on step 1.
  def open_thread(pace: nil)
    visit root_path
    assert_selector "main[data-playing]"
    self.pace(pace) if pace
  end

  # Sets the playback pace. The controller restarts the current step's clock.
  def pace(ms)
    execute_script("document.querySelector('[data-controller~=playback]').dataset.playbackPaceValue = #{ms}")
  end

  # What a cache restore does: the controller reconnects to markup that an
  # earlier render wrote, value attributes included.
  def restore_from_cache
    execute_script(<<~JS)
      const main = document.querySelector("main")
      const controllers = main.dataset.controller
      main.removeAttribute("data-controller")
      setTimeout(() => main.setAttribute("data-controller", controllers), 50)
    JS
  end

  def playing? = has_selector?("main[data-playing]", wait: 0)

  def click_control(label) = find("[aria-label='#{label}']").click

  def filter(label) = find("[data-filter-target=option]", exact_text: label)

  def click_filter(label) = filter(label).click

  def target(index) = find("[data-playback-target=target][href='##{@steps[index].key}']")

  # A strip, once the bodies above it have finished opening or closing: a
  # click while they move lands on whichever strip has slid under the pointer.
  def strip(index)
    assert_no_transitions
    find("##{@steps[index].key} h3 button")
  end

  def assert_no_transitions
    assert_selector("main") { evaluate_script("document.getAnimations().filter(a => a instanceof CSSTransition).length").zero? }
  end

  # What an active step's strip reads while playing: a gate holds.
  def active_word(index) = %w[human machine].include?(@steps[index].kind) ? "hold" : "active"

  def current_step = @steps.index { |step| has_selector?("##{step.key}[data-state=active]", wait: 0) }

  def assert_step(index, status: nil)
    assert_row(index, state: "active", open: "true", status:)
    assert_selector "[data-playback-target=readoutName]", text: @steps[index].name
    assert_selector "[data-playback-target=readoutStatus]", text: status.upcase if status
  end

  def assert_bay(name)
    assert_selector "[data-playback-target=bay][data-current][aria-current=true]", count: 1, text: name.upcase
  end

  def assert_log_counts(gates, artifacts)
    assert_selector "[data-playback-target=gatesCleared]", exact_text: gates.to_s
    assert_selector "[data-playback-target=artifacts]", exact_text: artifacts.to_s
  end

  def assert_row(index, state: nil, open: nil, status: nil)
    key = @steps[index].key
    assert_selector "##{key}#{"[data-state=#{state}]" if state}#{"[data-open=#{open}]" if open}"
    assert_selector "##{key} [data-playback-target=status]", text: status.upcase if status
  end

  def line_time(index)
    evaluate_script("document.querySelector('##{@steps[index].key} [data-playback-target=line]').getAnimations()[0].currentTime")
  end

  def line_state(index)
    evaluate_script("document.querySelector('##{@steps[index].key} [data-playback-target=line]').getAnimations()[0].playState")
  end

  # Waits out a transition: retries until the computed value settles.
  def assert_computed(expected, key, selector, property)
    script = "getComputedStyle(document.querySelector('##{key} #{selector}')).#{property}"
    page.document.synchronize do
      actual = evaluate_script(script)
      raise Capybara::ExpectationNotMet, "#{property} of ##{key} #{selector} is #{actual}" unless actual == expected
    end
  end

  def resize_to(height)
    window = page.driver.browser.manage.window
    original = window.size
    window.resize_to(original.width, height)
    yield
  ensure
    window.resize_to(original.width, original.height)
  end
end

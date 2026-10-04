# frozen_string_literal: true

require "application_system_test_case"

# The home thread in a browser: the playback controller and the views that
# render from it (docs/system/home-thread-playback.md). Each test names the row
# of the design doc's event table (section 6) it covers. Steps are picked by
# position or kind, never by key, so the tests follow the thread file.
class HomePlaybackTest < ApplicationSystemTestCase
  # Milliseconds per second of step time: a 6 s step takes 300 ms here.
  FAST = 50

  # The element the playback and filter controllers sit on: a wrapper around
  # main and the footer.
  PLAYER = "[data-controller~=playback]"

  DOCK = "[aria-label='Docked playback']"

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
    assert_no_selector "#{PLAYER}[data-settling]"
  end

  test "thread first scrolls into view: it starts playing on step 1" do
    resize_to(400) do
      visit root_path
      assert_selector "[aria-label=Restart]"
      assert_not playing?

      scroll_to find("##{@steps.first.key}"), align: :center

      assert_selector "#{PLAYER}[data-playing]"
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
    assert_selector "#{PLAYER}[data-playing]"
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
    assert_equal "#{target(@gate)[:"data-angle"]}deg", evaluate_script("document.querySelector('#{PLAYER}').style.getPropertyValue('--leader-angle')")
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

  test "reader scrolls by wheel: pauses, and nothing resumes it" do
    open_thread(pace: FAST)

    page.driver.browser.action.scroll_by(0, 300).perform

    assert_stays_paused
  end

  test "reader scrolls by touch: pauses, and nothing resumes it" do
    open_thread(pace: FAST)

    execute_script("window.dispatchEvent(new Event('touchmove'))")

    assert_stays_paused
  end

  test "reader scrolls by keys: pauses, and nothing resumes it" do
    open_thread(pace: FAST)

    page.driver.browser.action.send_keys(:page_down).perform

    assert_stays_paused
  end

  test "a reader's scroll before the thread is in view is how it comes into view, and still starts it" do
    resize_to(400) do
      visit root_path
      assert_selector "[aria-label=Restart]"

      page.driver.browser.action.scroll_by(0, 50).perform # the reader's wheel, the thread still below
      assert_not playing?
      scroll_to find("##{@steps.first.key}"), align: :center

      assert_selector "#{PLAYER}[data-playing]"
    end
  end

  test "resuming scrolls back to the active strip first" do
    open_thread

    page.driver.browser.action.scroll_by(0, 4000).perform
    assert_not playing?
    assert_selector DOCK

    find("#{DOCK} [aria-label=Play]").click

    assert_strip_top 0
    assert_selector "#{PLAYER}[data-playing]"
  end

  test "each step has a hash: a step change writes it in place, and a fresh load writes none" do
    open_thread
    assert_nil URI(current_url).fragment
    entries = evaluate_script("history.length")

    pace FAST

    assert_step 1, status: active_word(1)
    assert_equal @steps[1].key, URI(current_url).fragment
    assert_equal entries, evaluate_script("history.length"), "written with replaceState, not pushed"
    target(@gate).click
    assert_equal @steps[@gate].key, URI(current_url).fragment
  end

  test "page loads with a step hash: that step active, paused, scrolled into view" do
    visit root_path(anchor: @steps[@gate].key)

    assert_step @gate, status: "paused"
    assert_strip_top @gate
    sleep 0.5 # the thread is in view: it must not start by itself
    assert_not playing?
  end

  test "keys: Space plays and pauses, j steps forward, k steps back" do
    open_thread

    press :space
    assert_not playing?
    assert_step 0, status: "paused"
    press :space
    assert_selector "#{PLAYER}[data-playing]"

    press "j"
    assert_step 1, status: "paused"
    press "k"
    assert_step 0, status: "paused"
  end

  test "keys: g then a number jumps to that gate, and the page goes to it" do
    open_thread
    gates = @steps.each_index.select { |index| @steps[index].gate? }

    press "g", "3"

    assert_step gates[2], status: "paused"
    assert_strip_top gates[2]
  end

  test "keys: g then anything else is dropped, and that key keeps its meaning" do
    open_thread
    click_control "Pause"

    press "g", "j", "2"

    assert_step 1, status: "paused"
  end

  test "keys: Space on a focused control presses it, and keys in a text field are the field's" do
    open_thread
    click_control "Pause"

    find("[aria-label=Scope] [aria-label='Step forward']").send_keys(:space)
    assert_step 1, status: "paused"

    execute_script("document.querySelector('footer').insertAdjacentHTML('beforeend', '<input aria-label=Note>')")
    find("[aria-label=Note]").send_keys("jk g1 ")
    sleep 0.2
    assert_step 1, status: "paused"
  end

  test "the footer lists the keys once playback runs" do
    open_thread

    assert_selector "footer [aria-label=Keyboard]", text: "Space play or pause"
    assert_selector "footer [aria-label=Keyboard]", text: "g then 1 – #{@steps.count(&:gate?)} a gate"
  end

  test "reduced motion: loads paused, with no sweep, an instant roll-up and an instant follow" do
    reduced_motion do
      visit root_path
      assert_selector "[aria-label=Restart]"
      sleep 0.5 # the thread is in view: it must not start by itself
      assert_not playing?
      assert_no_selector "[data-scope=sweep]"

      click_control "Step forward"
      assert_step 1, status: "paused"
      # Only motion that moves layout stops (docs/rules/motion-budget.md); a fade may stay.
      assert_equal 0, evaluate_script("document.getAnimations().filter(a => a.transitionProperty === 'grid-template-rows').length")

      click_control "Play"
      top = evaluate_async_script(<<~JS)
        const done = arguments[0]
        const frame = () => new Promise(requestAnimationFrame)
        frame().then(frame).then(frame).then(() => done(document.querySelector("##{@steps[1].key} h3 button").getBoundingClientRect().top))
      JS
      assert_in_delta 96, top, 2, "landed within three frames: no smooth scroll"
    end
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
      assert_selector "#{PLAYER}[data-playing]"

      restore_from_cache

      assert_no_selector "#{PLAYER}[data-playing]"
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

  test "step timer ends: the page follows, the active strip's top 96 px from the viewport's" do
    open_thread(pace: 150) # a 6 s step takes 900 ms

    assert_step 1, status: active_word(1)
    assert_strip_top 1
    assert_selector DOCK # the scope has scrolled out of view
  end

  test "a target selected is an explicit jump: the page goes to it; step back and forward leave the page where it is" do
    open_thread
    click_control "Pause"

    target(@gate).click
    assert_strip_top @gate

    scroll_to_top
    sleep 0.5 # let the jump's smooth scroll come to rest
    before = evaluate_script("window.scrollY")
    click_control "Step forward"
    assert_step @gate + 1, status: "paused"
    click_control "Step back"
    assert_step @gate, status: "paused"
    sleep 0.5 # the time a follow would take to start and land
    assert_equal before, evaluate_script("window.scrollY")
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
    assert_selector "#{PLAYER}[data-playing]"
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

  test "docked bar: shows once the scope leaves view, under the 96 px line, and drives the same state" do
    open_thread
    assert_no_selector DOCK

    scroll_past_scope

    assert_selector DOCK
    assert_operator evaluate_script("document.querySelector(\"#{DOCK}\").getBoundingClientRect().bottom"), :<=, 96
    find("#{DOCK} [aria-label=Pause]").click
    assert_not playing?
    assert_step 0, status: "paused"

    find("#{DOCK} [data-playback-target=mark][href='##{@steps[@gate].key}']").click
    assert_step @gate, status: "paused"
    assert_selector "#{DOCK} [data-playback-target=readoutName]", text: "#{format("%02d", @gate + 1)} #{@steps[@gate].name}"
    assert_selector "#{DOCK} [data-playback-target=mark][aria-current=step][href='##{@steps[@gate].key}']"
    assert_selector "#{DOCK} [data-playback-target=bay][data-current]", text: @steps[@gate].bay.upcase

    find("#{DOCK} [aria-label=Play]").click
    assert_selector "#{PLAYER}[data-playing]"

    scroll_to_top
    assert_no_selector DOCK
  end

  test "every docked control is a named target of at least 44 px, and axe passes while docked" do
    open_thread
    scroll_past_scope
    assert_selector DOCK

    sizes = evaluate_script(<<~JS)
      [...document.querySelectorAll("#{DOCK} button, #{DOCK} a")]
        .map(el => { const r = el.getBoundingClientRect(); return [el.getAttribute("aria-label"), r.width, r.height] })
    JS
    assert_equal 4 + @steps.size, sizes.size
    sizes.each do |name, width, height|
      assert name.present?, "a docked control has no name"
      assert_operator [ width, height ].min, :>=, 44, "#{name} is #{width}×#{height}"
    end
    assert_accessible
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
    assert_selector "#{PLAYER}[data-playing]"
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
      const player = document.querySelector("#{PLAYER}")
      const controllers = player.dataset.controller
      player.removeAttribute("data-controller")
      setTimeout(() => player.setAttribute("data-controller", controllers), 50)
    JS
    assert_selector PLAYER # reconnected: until then, no assertion on it means anything
  end

  # Scrolls the page, as a script and not as a reader, until the scope is out of view.
  def scroll_past_scope
    execute_script("window.scrollTo(0, document.querySelector('[aria-label=Scope]').getBoundingClientRect().bottom + window.scrollY + 1)")
  end

  # Paused, and still paused on the same step after two steps' time: no timer
  # may resume it (docs/rules/playback-yields.md).
  def assert_stays_paused
    assert_no_selector "#{PLAYER}[data-playing]"
    step = current_step
    sleep FAST * 6 * 2 / 1000.0
    assert_not playing?
    assert_equal step, current_step
  end

  # Keys pressed with focus on the page itself, not on a control.
  def press(*keys)
    execute_script("document.activeElement?.blur()")
    keys.each { |key| page.driver.browser.action.send_keys(key).perform }
  end

  # Runs the block as a reader who asked for reduced motion.
  def reduced_motion
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    yield
  ensure
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  def scroll_to_top = execute_script("window.scrollTo(0, 0)")

  # The followed line (design doc, section 6): a strip's top 96 px below the
  # viewport's. Retries while a smooth scroll is still on its way.
  def assert_strip_top(index, expected = 96)
    script = "document.querySelector('##{@steps[index].key} h3 button').getBoundingClientRect().top"
    page.document.synchronize do
      actual = evaluate_script(script)
      raise Capybara::ExpectationNotMet, "step #{index + 1}'s strip is #{actual} px from the top" unless (actual - expected).abs <= 2
    end
  end

  def playing? = has_selector?("#{PLAYER}[data-playing]", wait: 0)

  def click_control(label)
    assert_scroll_at_rest
    find("[aria-label=Scope] [aria-label='#{label}']").click
  end

  def filter(label) = find("[data-filter-target=option]", exact_text: label)

  def click_filter(label) = filter(label).click

  def target(index)
    assert_scroll_at_rest
    find("[data-playback-target=target][href='##{@steps[index].key}']")
  end

  # A strip, once the bodies above it have finished opening or closing and a
  # follow has landed: a click while they move lands on whichever strip has
  # slid under the pointer.
  def strip(index)
    assert_no_transitions
    assert_scroll_at_rest
    find("##{@steps[index].key} h3 button")
  end

  # The page has stopped moving: two reads a few frames apart agree.
  def assert_scroll_at_rest
    last = nil
    page.document.synchronize do
      sleep 0.05
      now = evaluate_script("window.scrollY")
      at_rest = now == last
      last = now
      raise Capybara::ExpectationNotMet, "the page is still scrolling" unless at_rest
    end
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

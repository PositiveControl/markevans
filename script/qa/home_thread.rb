# frozen_string_literal: true

# The home thread (#21): headline and intro, the legend, every strip with its
# body, the git graph drawn beside the strips (#15), playback from the scope
# (#16), the strip bay, controller filter and log (#17), and follow, yield,
# the docked bar, the step hash and the keyboard (#18), and narrow screens
# (#19). The page starts
# playing as the thread comes into view, so the walk pauses it first and the
# reading steps run on a still page.
#
# Builds no data: everything shown comes from content/threads/home.yml, read
# here through DeliveryThread so the captions follow the file. Steps are picked
# by what they are (the first, a loop, a fork, a sector change, a human gate, a
# merge, the last), never by key. Spotlights use text, the step's row id (its
# key, from the file), an ARIA label, data-state, or the chart's data-git-event
# and data-chart names: hooks that survive a restyle, never utility classes.
# Clicks are the change being shown: a control, a target, a strip, a mark; so
# are the wheel and the keys. Controls are pressed on the scope, or on the
# docked bar where it is the point: once a jump has scrolled the scope away,
# both are on screen.
#
# The follow step waits out one step's time (6 s) once, since following is
# what happens when the timer runs out. Not walked: the page without scripts
# and under reduced motion (the system tests cover both, axe included), and
# what is not built yet: the other pages (7). The page
# budget is a test, not a page to walk.
require Rails.root.join("lib/qa_walkthrough")

thread = DeliveryThread.fetch(:home)
first = thread.steps.first
fork = thread.steps.find { |step| step.git.event == "fork" }
gate = thread.steps.find { |step| step.kind == "human" }
side = thread.steps.find { |step| step.git.event == "loop" }
merge = thread.steps.find { |step| step.git.event == "merge" }
sector = thread.cells.drop(1).find(&:sector)
last = thread.steps.last
review = thread.steps.find { |step| step.bay == "Up for Review" }
agent = thread.steps.find { |step| step.lane == "agent" }
second = thread.steps.second
gates = thread.steps.select(&:gate?)

SCOPE = "[aria-label=Scope]"
DOCK = "[aria-label='Docked playback']"
PLAYER = "[data-controller~=playback]"

QaWalkthrough.run("home_thread") do
  step "The page opens on the headline and the positive-control paragraph" do
    # Desktop width first; the phone steps come last.
    page.current_window.resize_to(1400, 1000)
    visit root_path
    spotlight text: thread.headline, note: "headline and intro in content/threads/home.yml"
  end

  step "As the thread comes into view it plays: the sweep turns and step 1 is outlined" do
    spotlight "##{first.key}"
    find("#{PLAYER}[data-playing]")
    spotlight "[aria-label=Scope]", note: "the centre block names the active step; the leader points at its target"
  end

  step "Pause: the sweep and step 1's remaining-time line freeze, and its status reads paused" do
    find("#{SCOPE} [aria-label=Pause]").click
    spotlight "##{first.key} [data-playback-target=status]", note: "the 2 px line along the strip's bottom edge is the time left"
  end

  step "The strip bay fills step 1's bay, #{first.bay}, and the log is still empty" do
    spotlight "[aria-label='Strip bay'] [data-current]", note: "Todo, In Progress, Up for Review, Done"
    spotlight "[aria-labelledby=log-heading]", note: "one line until a step finishes"
  end

  step "The legend names every symbol the chart and scope draw" do
    spotlight "[aria-label=Legend]", note: "four fix symbols, then three lines and the scope target"
  end

  step "Step 1, #{first.name}: the strip, then its body, open because it is the active step" do
    spotlight "##{first.key}", note: "#{first.groups.size} detail groups; later strips are pending, their bodies rolled up"
  end

  step "Beside it, main starts at the first fix, labelled #{first.git.label}" do
    spotlight "##{first.key} [data-git-event=start]", note: "the chart cell is drawn from the step's git block"
  end

  step "#{side.name} is a loop: a dashed bracket out to the side lane and back" do
    spotlight "##{side.key} [data-chart=loop]", note: "inset from the row's edges, so it stretches with the row"
  end

  step "#{fork.name} forks onto #{fork.git.on}: an elbow from #{fork.git.from}, then the branch runs down" do
    spotlight "##{fork.key} [data-git-event=fork]", note: "labelled #{fork.git.label}"
  end

  step "Selecting #{fork.name}'s target on the scope jumps there and pauses; its artifact is mono on the card ground" do
    find("[data-playback-target=target][href='##{fork.key}']").click
    spotlight "##{fork.key}"
    spotlight text: fork.artifact.source, note: "the rows above it are done, and the chart below it dims" if fork.artifact
  end

  step "Step forward: #{fork.name}'s strip rolls up and shows its outcome on the Rmk line" do
    find("#{SCOPE} [aria-label='Step forward']").click
    spotlight "##{fork.key}[data-state=done] h3", note: "status: done; the next step is active and paused"
  end

  step "#{gate.name} is a human gate: amber tint, controller #{gate.lane}; its target is a rotated square" do
    find("[data-playback-target=target][href='##{gate.key}']").click
    spotlight "##{gate.key}", note: "the leader swings to its target; the status reads paused, and hold while playing"
  end

  step "Jump to #{review.name}: the bay moves to #{review.bay}, and the log lists every finished step, newest first" do
    find("[data-playback-target=target][href='##{review.key}']").click
    spotlight "[aria-label='Strip bay'] [data-current]", note: review.bay
    spotlight "[aria-labelledby=log-heading]", note: "gates cleared out of #{thread.steps.count(&:gate?)}, and the artifacts made; it scrolls inside 220 px"
  end

  step "Controller filter, Human: every Agent and CI row drops back, none hidden" do
    find("[data-filter-target=option]", exact_text: "Human").click
    spotlight "##{agent.key}[data-dim]", note: "graph at 40 percent, strip ground gone, text quiet; playback state unchanged"
  end

  step "Controller filter, All: every row comes back" do
    find("[data-filter-target=option]", exact_text: "All").click
    spotlight "##{agent.key}:not([data-dim])"
  end

  step "#{sector.step.name} opens the #{sector.sector} sector: a dashed edge and a darker band" do
    spotlight "##{sector.step.key} [data-chart=sector]", note: "where the bay changes from the row above"
  end

  step "#{merge.name} merges #{merge.git.from} back into #{merge.git.on} with a mirrored elbow" do
    spotlight "##{merge.key} [data-git-event=merge]", note: "labelled #{merge.git.label}"
  end

  step "The last step, #{last.name}, closes the thread (#{thread.steps.size} steps)" do
    spotlight "##{last.key}"
  end

  step "Selecting a done strip reopens it; playback does not move" do
    find("##{first.key} h3 button").click
    spotlight "##{first.key}[data-open=true]", note: "the active step is still #{review.name}, paused"
  end

  step "Restart: step 1, reopened strips closed, paused" do
    find("#{SCOPE} [aria-label=Restart]").click
    spotlight "##{first.key}[data-state=active]", note: "the bay is back on #{first.bay} and the log is empty; press Play to run the thread from the top"
  end

  step "Play: the page follows the active strip, its top 96 px from the top of the window, as each step comes up" do
    find("#{SCOPE} [aria-label=Play]").click
    find("##{second.key}[data-state=active]", wait: 10) # one step's time
    # The bar is fixed, so its spotlight leaves the followed page where it is.
    spotlight "#{DOCK} [data-playback-target=readoutName]", note: "the scope has scrolled away, and the docked bar holds the controls"
  end

  step "Scroll with the wheel: playback pauses, and nothing resumes it" do
    page.driver.browser.action.scroll_by(0, 600).perform
    find("#{PLAYER}:not([data-playing])")
    spotlight "#{DOCK} [aria-label=Play]", note: "the reader has the page; Play reads Play, and stays so"
  end

  step "A mark on the docked bar jumps to #{gate.name} and the page goes to it" do
    find("#{DOCK} [data-playback-target=mark][href='##{gate.key}']").click
    spotlight "#{DOCK} [data-playback-target=mark][aria-current=step]", note: "the bar's name and bay follow the step; it is a second view of one state"
  end

  step "Scroll away, then Play on the docked bar: the page returns to #{gate.name} before it plays" do
    page.driver.browser.action.scroll_by(0, 1500).perform
    find("#{DOCK} [aria-label=Play]").click
    find("#{PLAYER}[data-playing]")
    spotlight "#{DOCK} [data-playback-target=readoutName]", note: "#{gate.name}'s strip is back 96 px from the top, and holds"
  end

  step "Keys: Space pauses, j steps forward, k steps back, g then 2 jumps to #{gates.second.name}" do
    execute_script("document.activeElement.blur()") # keys on the page, not on the Play just pressed
    [ :space, "j", "k", "g", "2" ].each { |key| page.driver.browser.action.send_keys(key).perform }
    find("##{gates.second.key}[data-state=active]")
    sleep 1 # the follow waits out the roll-up, then glides
    spotlight "#{DOCK} [data-playback-target=readoutName]", note: "the page footer lists these keys, g with 1 to #{gates.size}, the thread's gate count"
  end

  step "The URL names the active step; loading it opens #{gates.second.name}, paused" do
    visit current_url
    find("##{gates.second.key}[data-state=active]")
    spotlight "#{DOCK} [data-playback-target=readoutName]", note: "URL ends ##{gates.second.key}; the page did not start by itself"
  end

  # A phone, emulated as DevTools' device mode does: a desktop Chrome window
  # will not size under about 500 px.
  step "On a phone (390 px) the top row stacks: the scope above the headline" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false)
    visit root_path
    spotlight SCOPE, note: "full width, at most 400 px; the headline, intro and log follow below"
  end

  step "Wheel the thread into view: it starts playing, and the rest of that scroll leaves it playing" do
    # One gesture, ticks 50 ms apart, sent as one chain as the system test does.
    gesture = page.driver.browser.action.tap { |action| action.default_scroll_duration = 0 }
    30.times { gesture.scroll_by(0, 120).pause(duration: 0.05) }
    gesture.perform
    find("#{PLAYER}[data-playing]")
    spotlight "[data-playback-target=row][data-state=active]", note: "still playing: the scroll that arrived is not a new one until it stops for 300 ms"
  end

  step "The chart is an 84 px gutter, lanes at 14, 38 and 62 px, no labels; each strip wraps to two lines" do
    find("#{DOCK} [aria-label=Pause]").click
    spotlight "##{fork.key}", note: "#{fork.name}'s fork elbow in the gutter; Ctl, Bay and status in thirds under the name"
  end

  step "The docked bar is one row: the controls and the step's name, and nothing scrolls sideways" do
    page_width, viewport = evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")
    spotlight "#{DOCK} [data-playback-target=readoutName]", note: "page #{page_width} px wide in a #{viewport} px viewport; jump from the strips"
  end

  step "At 1024 px the docked bar keeps its marks, drops the bay, and stays above the followed strip" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 1024, height: 900, deviceScaleFactor: 1, mobile: false)
    bottom = evaluate_script("document.querySelector(\"#{DOCK}\").getBoundingClientRect().bottom")
    spotlight "#{DOCK} [aria-label=Steps]", note: "bar bottom at #{bottom.round} px, above the 96 px line"
  ensure
    # Every step runs even after one fails, so this one always ends the emulation.
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end
end

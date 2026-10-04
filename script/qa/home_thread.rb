# frozen_string_literal: true

# The home thread (#21): headline and intro, the legend, every strip with its
# body, the git graph drawn beside the strips (#15), playback from the scope
# (#16), and the strip bay, controller filter and log (#17). The page starts playing as the thread comes into view, so the
# walk pauses it first and the reading steps run on a still page.
#
# Builds no data: everything shown comes from content/threads/home.yml, read
# here through DeliveryThread so the captions follow the file. Steps are picked
# by what they are (the first, a loop, a fork, a sector change, a human gate, a
# merge, the last), never by key. Spotlights use text, the step's row id (its
# key, from the file), an ARIA label, data-state, or the chart's data-git-event
# and data-chart names: hooks that survive a restyle, never utility classes.
# Clicks are the change being shown: a control, a target, a strip.
#
# Not walked: the page without scripts (the system tests cover it, axe
# included), the step timer running out (it would make the walk wait), and
# what is not built yet: follow and the docked bar (5), narrow screens (6),
# and the other pages (7). The page budget is a test, not a page to walk.
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

QaWalkthrough.run("home_thread") do
  step "The page opens on the headline and the positive-control paragraph" do
    visit root_path
    spotlight text: thread.headline, note: "headline and intro in content/threads/home.yml"
  end

  step "As the thread comes into view it plays: the sweep turns and step 1 is outlined" do
    spotlight "##{first.key}"
    find("main[data-playing]")
    spotlight "[aria-label=Scope]", note: "the centre block names the active step; the leader points at its target"
  end

  step "Pause: the sweep and step 1's remaining-time line freeze, and its status reads paused" do
    find("[aria-label=Pause]").click
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
    find("[aria-label='Step forward']").click
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
    find("[aria-label=Restart]").click
    spotlight "##{first.key}[data-state=active]", note: "the bay is back on #{first.bay} and the log is empty; press Play to run the thread from the top"
  end
end

# frozen_string_literal: true

# The home thread as it reads without scripts (#21): headline and intro, the
# legend, and every strip open with its body, with the git graph drawn beside
# the strips (#15).
#
# Builds no data: everything shown comes from content/threads/home.yml, read
# here through DeliveryThread so the captions follow the file. Steps are picked
# by what they are (the first, a loop, a fork, a sector change, a human gate, a
# merge, the last), never by key. Spotlights use text, the step's row id (its
# key, from the file), an ARIA label, or the chart's data-git-event and
# data-chart names: hooks that survive a restyle, never utility classes.
#
# Not walked, because it is not built yet: playback, the scope and strip
# states (3), the bay, filter and log (4), follow and the docked bar (5),
# narrow screens (6), and the other pages (7).
require Rails.root.join("lib/qa_walkthrough")

thread = DeliveryThread.fetch(:home)
first = thread.steps.first
fork = thread.steps.find { |step| step.git.event == "fork" }
gate = thread.steps.find { |step| step.kind == "human" }
side = thread.steps.find { |step| step.git.event == "loop" }
merge = thread.steps.find { |step| step.git.event == "merge" }
sector = thread.cells.drop(1).find(&:sector)
last = thread.steps.last

QaWalkthrough.run("home_thread") do
  step "The page opens on the headline and the positive-control paragraph" do
    visit root_path
    spotlight text: thread.headline, note: "headline and intro in content/threads/home.yml"
  end

  step "The legend names every symbol the chart and scope will draw" do
    spotlight "[aria-label=Legend]", note: "four fix symbols, then three lines and the scope target"
  end

  step "Step 1, #{first.name}: the strip, then its body, open without scripts" do
    spotlight "##{first.key}", note: "#{first.groups.size} detail groups; no status word until playback"
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

  step "#{fork.name}'s artifact is mono on the card ground" do
    spotlight "##{fork.key}"
    spotlight text: fork.artifact.source, note: "artifact source and body from the step" if fork.artifact
  end

  step "#{gate.name} is a human gate: amber tint, controller #{gate.lane}" do
    spotlight text: gate.name, exact: true, note: "the strip's ground is set by its kind"
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
end

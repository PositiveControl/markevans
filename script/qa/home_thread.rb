# frozen_string_literal: true

# The home thread as it reads without scripts (#21): headline and intro, the
# legend, and every strip open with its body.
#
# Builds no data: everything shown comes from content/threads/home.yml, read
# here through DeliveryThread so the captions follow the file. Steps are picked
# by what they are (the first, a fork, a human gate, the last), never by key.
#
# Not walked, because it is not built yet: the chart (slice 2), playback, the
# scope and strip states (3), the bay, filter and log (4), follow and the docked
# bar (5), narrow screens (6), and the other pages (7).
require Rails.root.join("lib/qa_walkthrough")

thread = DeliveryThread.fetch(:home)
first = thread.steps.first
fork = thread.steps.find { |step| step.git.event == "fork" }
gate = thread.steps.find { |step| step.kind == "human" }
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

  step "#{fork.name} forks onto #{fork.git.on}: its artifact is mono on the card ground" do
    spotlight "##{fork.key}"
    spotlight text: fork.artifact.source, note: "artifact source and body from the step" if fork.artifact
  end

  step "#{gate.name} is a human gate: amber tint, controller #{gate.lane}" do
    spotlight text: gate.name, exact: true, note: "the strip's ground is set by its kind"
  end

  step "The last step, #{last.name}, closes the thread (#{thread.steps.size} steps)" do
    spotlight "##{last.key}"
  end
end

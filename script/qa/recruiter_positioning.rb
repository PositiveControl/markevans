# frozen_string_literal: true

# Recruiter positioning (#57): the search terms in each page's <title>, and
# /contact as the page a recruiter lands on, with the facts they screen for
# At a glance.
#
# Builds no data: every caption reads content/ through SitePage, DeliveryThread
# and Portfolio. The project is picked by what it is (the first with a
# repository), never by literal. A <title> is not on the page to spotlight, so
# each step's caption quotes the one the browser was given.
#
# Not walked: the meta descriptions, the Person's jobTitle and knowsAbout, the
# ContactPage's mainEntity and the projects' SoftwareSourceCode are all in
# <head>; seo_test.rb reads each one, and Google's Rich Results Test shows
# them on the live site. The 60- and 155-character limits are tests, not
# something to look at.
require Rails.root.join("lib/qa_walkthrough")

home = DeliveryThread.fetch(:home)
contact = SitePage.fetch(:contact)
glance = contact.sections.find { |section| section.heading == "At a glance" }
rows = glance.groups.flat_map(&:rows)
project = Portfolio.all.find(&:repository)

QaWalkthrough.run("recruiter_positioning") do
  step "The home page's title names the role; its headline does not change" do
    page.current_window.resize_to(1400, 1000)
    visit root_path
    spotlight "h1", note: "tab title: “#{page.title}”"
  end

  step "Contact is the page a recruiter lands on, and its title carries the search term" do
    visit contact_path
    spotlight "h1", note: "tab title: “#{page.title}”; the heading stays “#{contact.title}”"
  end

  step "At a glance: the #{rows.size} things a recruiter screens for, in their order" do
    spotlight text: glance.heading, note: rows.map(&:key).join(" · ")
    spotlight text: rows.last.value, note: "the stack row: Rails is the strongest, not the only one"
  end

  step "At 390 px At a glance stays readable: each value drops under its key" do
    # A window resize, not a device-metrics override: the screenshot is taken
    # after the step, and an override cleared in an ensure is gone by then.
    page.current_window.resize_to(390, 844)
    visit contact_path
    page_width, viewport = evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")
    spotlight text: glance.heading, note: "page #{page_width} px wide in a #{viewport} px viewport"
  end

  step "Background and Workflow name the role and AI coding agents in their titles" do
    page.current_window.resize_to(1400, 1000)
    visit background_path
    spotlight "h1", note: "tab title: “#{page.title}”"
    visit workflow_path
    spotlight "h1", note: "tab title: “#{page.title}”"
  end

  step "#{project.name} has a repository, so search engines are told it is source code" do
    visit project_path(project.key)
    spotlight "[role=group][aria-label=Links]", note: "its Repository link becomes SoftwareSourceCode in the JSON-LD, written in #{project.tags.select { |tag| StackRegistry[tag].language? }.join(', ')}"
  end
end

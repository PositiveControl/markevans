# frozen_string_literal: true

# Work, Workflow, Background and Contact (#20): the header nav on every page,
# the projects from content/work.yml under their categories, the stack
# filter, a project page, the Workflow chain
# drawn from the home thread, the CV and the contact routes, and the phone
# width. Since #38 the copy is cut from Mark's CV: a project's summary and
# At a glance rows, the Work intro, the CV with its print scale, and the
# contact routes.
#
# Builds no data: every caption reads content/ through Portfolio, SitePage and
# DeliveryThread, so it follows the files. Projects are picked by what they are
# (the first, one whose copy is written, one whose copy is still a
# placeholder), never by literal. Once every summary is written the
# placeholder step has nothing to show and is left out.
# Spotlights use text, ARIA labels and aria-current, never utility classes.
# Clicks are the change being shown: a nav link, a project.
#
# Not walked: the one-page print (test/system/other_pages_test.rb prints the
# CV through Chrome and counts the pages; a print dialog cannot be driven
# here), axe (the same system test), and the 404 for an unknown project
# (test/integration/other_pages_test.rb).
require Rails.root.join("lib/qa_walkthrough")

projects = Portfolio.all
first = projects.first
unwritten = projects.find { |project| project.summary.start_with?("[") }
written = (projects - [ first ]).find { |project| !project.summary.start_with?("[") && project.links.none?(&:placeholder?) }
work = SitePage.fetch(:work)
# The tag carried by the fewest projects, so filtering visibly narrows the list.
filter_tag = Portfolio.tags.min_by { |tag| projects.count { |project| project.tags.include?(tag) } }
filtered = projects.select { |project| project.tags.include?(filter_tag) }
thread = DeliveryThread.fetch(:home)
gate = thread.steps.find { |step| step.kind == "human" }
background = SitePage.fetch(:background)
contact = SitePage.fetch(:contact)
NAV = "nav[aria-label=Site]"

QaWalkthrough.run("site_pages") do
  step "The header carries the site's four sections on every page, the home page included" do
    page.current_window.resize_to(1400, 1000)
    visit root_path
    spotlight NAV, note: "Work, Workflow, Background, Contact; none is current on the home page"
  end

  step "Work lists the #{projects.size} projects under their categories, and Work is current" do
    click_on "Work"
    spotlight "#{NAV} [aria-current=page]", note: "underlined, not only colored"
    spotlight text: work.intro, note: "the intro, from the CV's note on how the projects were built"
    Portfolio.grouped.each do |category, members|
      spotlight "ul[aria-label='#{category}']", note: "#{category}: #{members.map(&:name).join(', ')}, each with its stack chips"
    end
  end

  step "A stack chip filters the list: #{filter_tag} keeps #{filtered.map(&:name).join(', ')}" do
    within("nav[aria-label='Filter by stack']") { click_on filter_tag }
    spotlight "nav[aria-label='Filter by stack'] [aria-current=page]", note: "the picked chip is ink; clicking it again shows every project"
    spotlight "main section", note: "categories with no #{filter_tag} project drop out"
    visit projects_path
  end

  step "A project page: #{first.name}, its links and its sections" do
    click_on first.name
    spotlight "[role=group][aria-label=Links]", note: first.links.map(&:label).join(", ")
    spotlight text: first.sections.first.heading, note: "#{first.sections.size} sections from the file"
  end

  if written
    step "A project cut from the CV: #{written.name}, its summary and what it is at a glance" do
      visit project_path(written.key)
      spotlight text: written.summary, note: "the summary is also the page's meta description"
      spotlight text: "At a glance", note: "Role, Stack and Status"
    end
  end

  if unwritten
    step "Copy not yet written shows as its [placeholder], and an unknown address is text, not a link" do
      visit project_path(unwritten.key)
      spotlight text: unwritten.summary, note: "the production build fails until it is written"
    end
  end

  step "Workflow draws the chain from the home thread: #{thread.steps.size} steps, each kind named in words" do
    click_on "Workflow"
    spotlight "[aria-label=Steps]", note: "the steps / plays, linking to each strip"
    spotlight text: gate.name, note: "#{gate.name} is a human gate"
  end

  step "Background is the CV: #{background.sections.map(&:heading).join(', ')}" do
    click_on "Background"
    spotlight text: background.sections.first.heading, note: "a cut of the master resume: no phone, no clearance, the Navy undated"
    spotlight "main", note: "prints to one page at its own smaller print scale, without the header and footer; the system test counts the pages"
  end

  step "Contact gives the routes: #{contact.links.map(&:label).join(', ')}" do
    click_on "Contact"
    spotlight "[aria-label='Contact routes']", note: "#{contact.links.count(&:placeholder?)} still a placeholder, shown as text"
  end

  step "At 390 px nothing scrolls sideways, and a detail row's value drops under its key" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false)
    visit background_path
    page_width, viewport = evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")
    spotlight text: background.sections.first.heading, note: "page #{page_width} px wide in a #{viewport} px viewport"
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  step "The name in the header goes home" do
    click_on "Mark Evans"
    spotlight text: thread.headline
  end
end

# frozen_string_literal: true

# Work, Workflow, Background and Contact (#20): the header nav on every page,
# the six projects from content/work.yml, a project page, the Workflow chain
# drawn from the home thread, the CV and the contact routes, and the phone
# width.
#
# Builds no data: every caption reads content/ through Portfolio, SitePage and
# DeliveryThread, so it follows the files. Projects are picked by what they are
# (the first, one whose copy is still a placeholder), never by literal.
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

  step "Work lists the #{projects.size} projects in the file's order, and Work is current" do
    click_on "Work"
    spotlight "#{NAV} [aria-current=page]", note: "underlined, not only colored"
    spotlight "[aria-label=Projects]", note: "#{projects.map(&:name).join(', ')}: content/work.yml"
  end

  step "A project page: #{first.name}, its links and its sections" do
    click_on first.name
    spotlight "dl[aria-label=Links]", note: first.links.map(&:label).join(", ")
    spotlight text: first.sections.first.heading, note: "#{first.sections.size} sections from the file"
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
    spotlight "main", note: "prints to one page without the header and footer; the system test counts the pages"
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

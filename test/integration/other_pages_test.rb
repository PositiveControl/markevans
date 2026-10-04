# frozen_string_literal: true

require "test_helper"

# Work, Workflow, Background and Contact (design doc, section 2). Every word
# is read back from content/, so a test fails if a template starts writing
# copy of its own (docs/rules/content-is-files.md).
class OtherPagesTest < ActionDispatch::IntegrationTest
  test "/work lists every project in the file's order, each linking to its page with its summary" do
    get projects_url

    assert_response :success
    assert_select "h1", SitePage.fetch(:work).title
    links = css_select("ul[aria-label=Projects] a")
    assert_equal Portfolio.all.map { |project| project_path(project.key) }, links.map { |a| a["href"] }
    Portfolio.all.each do |project|
      assert_select "a[href=?]", project_path(project.key) do
        assert_select "span.font-mono", project.name
        assert_select "span.font-serif", project.summary
      end
    end
  end

  test "a project page shows its name, summary, links and sections from the file" do
    project = Portfolio.fetch("rails-rocket-sheep")
    get project_url(project.key)

    assert_response :success
    assert_select "h1.font-mono", project.name
    assert_select "main > p", project.summary
    assert_select "[role=group][aria-label=Links] dl a[href=?]", project.links.first.url
    assert_equal project.sections.map(&:heading), css_select("main h2").map(&:text)
  end

  test "copy not yet written shows as its [placeholder], as written" do
    project = Portfolio.fetch("dopeempire")
    get project_url(project.key)

    assert_match(/\A\[.+\]\z/, project.summary)
    assert_select "main > p", project.summary
    assert_select "[role=group][aria-label=Links] dl a", count: 0
    assert_select "[role=group][aria-label=Links] dl span", project.links.first.url
  end

  test "an unknown project is a 404" do
    get "/work/nope"

    assert_response :not_found
  end

  test "/workflow lists every step of the home thread, in order, with its kind in words" do
    thread = DeliveryThread.fetch(:home)
    get workflow_url

    assert_response :success
    assert_select "h1", SitePage.fetch(:workflow).title
    assert_equal thread.steps.map(&:name), css_select("ol[aria-label=Steps] li a").map(&:text)
    assert_equal thread.steps.map { |step| root_path(anchor: step.key) }, css_select("ol[aria-label=Steps] li a").map { |a| a["href"] }
    assert_select "ol[aria-label=Steps] li[data-kind=human]", count: thread.steps.count { |step| step.kind == "human" }
    assert_select "ol[aria-label=Steps] li[data-kind=human]", text: /human gate/
    assert_select "ol[aria-label=Steps] li[data-kind=machine]", text: /automated gate/
    assert_equal SitePage.fetch(:workflow).sections.map(&:heading), css_select("main section > h2").map(&:text) - [ "The chain" ]
  end

  test "/background shows the CV's sections and its groups of rows" do
    page = SitePage.fetch(:background)
    get background_url

    assert_response :success
    assert_select "h1", page.title
    assert_equal page.sections.map(&:heading), css_select("main h2").map(&:text)
    assert_select "main h3", count: page.sections.sum { |section| section.groups.size }
  end

  test "/contact gives each route, linking those whose address is known" do
    page = SitePage.fetch(:contact)
    get contact_url

    assert_response :success
    assert_select "[role=group][aria-label='Contact routes'] dt", count: page.links.size
    page.links.reject(&:placeholder?).each { |link| assert_select "dl a[href=?]", link.url }
    page.links.select(&:placeholder?).each { |link| assert_select "dl span", link.url }
  end

  test "each page marks its own section current in the header, and only that one" do
    { projects_url => "Work", project_url("kram") => "Work", workflow_url => "Workflow",
      background_url => "Background", contact_url => "Contact" }.each do |url, current|
      get url

      assert_select "header nav a[aria-current=page]", { count: 1, text: current }, "on #{url}"
    end
  end

  test "each page signs off with the shared footer" do
    [ projects_url, project_url("kram"), workflow_url, background_url, contact_url ].each do |url|
      get url

      assert_select "footer", /Mark Evans · PositiveControl/
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class HomePageTest < ActionDispatch::IntegrationTest
  test "renders the hero identity" do
    get root_url

    assert_response :success
    assert_select "h1", /Mark Evans/
    assert_select "title", /Mark Evans/
  end

  test "renders every metric, project and role" do
    get root_url

    Portfolio.metrics.each { |metric| assert_includes response.body, metric.label }
    Portfolio.projects.each { |project| assert_includes response.body, project.name }
    Portfolio.roles.each { |role| assert_includes response.body, role.company }
  end

  test "every project links out to its live site or repo" do
    get root_url

    Portfolio.projects.each do |project|
      assert_select "a[href=?]", project.url
    end
  end

  test "contact section links email and profiles" do
    get root_url

    assert_select "a[href=?]", "mailto:#{Portfolio.profile.email}"
    assert_select "a[href=?]", Portfolio.profile.github
    assert_select "a[href=?]", Portfolio.profile.linkedin
  end

  test "does not publish a personal phone number" do
    get root_url

    refute_includes response.body, "720-289-3911"
  end

  test "publishes Person structured data" do
    get root_url

    person = css_select('script[type="application/ld+json"]').filter_map do |script|
      JSON.parse(script.text)
    rescue JSON::ParserError
      nil
    end.find { |data| data["@type"] == "Person" }

    assert person, "Expected Person JSON-LD"
    assert_equal Portfolio.profile.name, person["name"]
  end

  test "sections are landmarked and labelled for assistive tech" do
    get root_url

    %w[impact work projects skills contact].each do |id|
      assert_select "section##{id}[aria-labelledby]"
    end
  end

  test "the command palette ships a row for every section and project" do
    get root_url

    assert_select "[role=dialog][aria-label=?]", "Command palette"
    assert_select "[role=listbox] [role=option]", minimum: Portfolio.projects.size + 5

    Portfolio.projects.each do |project|
      assert_select "[role=option][href=?]", project.url
    end
  end

  test "the palette dialog starts hidden so it cannot trap a reader without JavaScript" do
    get root_url

    assert_select "[role=dialog][hidden]"
  end

  test "self-hosted fonts are preloaded, not fetched from a third party" do
    get root_url

    assert_select "link[rel=preload][as=font]", 3
    refute_includes response.body, "fonts.googleapis.com"
    refute_includes response.body, "fonts.gstatic.com"
  end

  # The page was rebuilt to drop the stock aurora/gradient/marquee treatment.
  # These names coming back means the old look came back with them.
  test "none of the retired decoration is rendered" do
    get root_url

    %w[aurora spotlight gradient-text marquee dot-grid].each do |name|
      refute_includes response.body, name, "#{name} is back on the page"
    end
  end
end

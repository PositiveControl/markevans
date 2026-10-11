# frozen_string_literal: true

require "application_system_test_case"

# A project's findings, filtered by kind in a browser: a toggle drops the
# other kinds back to quiet text and never hides them, and without scripts
# there are no toggles and every finding reads at full strength
# (docs/system/project-entries.md).
class ProjectFindingsTest < ApplicationSystemTestCase
  setup do
    # The test narrows to Surprises, so it needs a surprise and something to dim.
    @project = Portfolio.all.find do |project|
      kinds = project.findings.map(&:kind)
      kinds.include?("surprise") && kinds.uniq.size > 1
    end
    @findings = @project.findings
  end

  test "a kind toggle drops the other kinds back to quiet, keeps every finding in place, and All brings them back" do
    visit project_path(@project.key)
    surprises, others = (1..@findings.size).partition { |n| @findings[n - 1].kind == "surprise" }
    order = finding_ids

    click_toggle "Surprises"

    assert_equal "true", toggle("Surprises")[:"aria-pressed"]
    assert_equal "false", toggle("All")[:"aria-pressed"]
    others.each { |n| assert_selector "#finding-#{n}[data-dim]" }
    surprises.each { |n| assert_selector "#finding-#{n}:not([data-dim])" }
    @findings.each_index { |index| assert_selector "#finding-#{index + 1} h3", visible: true }
    assert_equal order, finding_ids
    assert_equal color("#findings-heading"), color("#finding-#{others.first} h3") # the quiet the heading wears
    assert_not_equal color("#findings-heading"), color("#finding-#{surprises.first} h3")
    assert_accessible

    click_toggle "All"

    assert_no_selector "[data-dim]"
    assert_selector "[data-filter-target=option][aria-pressed=true]", count: 1, text: "All"
  end

  test "on paper the toggles are left out and a narrowed list prints every finding in ink" do
    visit project_path(@project.key)
    surprise = @findings.index { |finding| finding.kind == "surprise" } + 1
    other = @findings.index { |finding| finding.kind != "surprise" } + 1
    click_toggle "Surprises"
    assert_selector "#finding-#{other}[data-dim]"

    as_print do
      assert_no_selector "[aria-labelledby=kind-filter]"
      assert_equal color("#finding-#{surprise} h3"), color("#finding-#{other} h3")
    end
  end

  test "the home page's lane toggles stay out of a project page" do
    visit project_path(@project.key)

    assert_selector "[data-filter-target=option]", count: 1 + @findings.map(&:kind).uniq.size
    assert_no_selector "[data-lane]"
  end

  test "without scripts there are no toggles, nothing is dimmed, and the page passes axe" do
    without_scripts do
      visit project_path(@project.key)

      assert_selector "#finding-#{@findings.size} h3", text: @findings.last.title
      assert_no_selector "[aria-labelledby=kind-filter]"
      assert_selector "[aria-labelledby=kind-filter]", visible: :hidden
      assert_no_selector "[data-dim]"
      assert_accessible
    end
  end

  private

  def toggle(label) = find("[data-filter-target=option]", exact_text: label)

  def click_toggle(label) = toggle(label).click

  def finding_ids = all("[data-filter-target=row]").map { |row| row[:id] }

  def color(selector) = evaluate_script("getComputedStyle(document.querySelector('#{selector}')).color")
end

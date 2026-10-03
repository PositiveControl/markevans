# frozen_string_literal: true

require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "profile carries the contact surface the page renders" do
    profile = Portfolio.profile

    assert_equal "Mark Evans", profile.name
    assert_equal "msteven.evans@gmail.com", profile.email
    assert profile.github.start_with?("https://github.com/")
    assert profile.linkedin.start_with?("https://www.linkedin.com/")
  end

  test "every metric has a value and a label" do
    assert Portfolio.metrics.any?

    Portfolio.metrics.each do |metric|
      assert metric.value.present?, "#{metric.key} has no value"
      assert metric.label.present?, "#{metric.key} has no label"
      assert metric.detail.present?, "#{metric.key} has no detail"
    end
  end

  test "every project has a name, blurb and reachable link" do
    assert Portfolio.projects.any?

    Portfolio.projects.each do |project|
      assert project.name.present?, "#{project.key} has no name"
      assert project.blurb.present?, "#{project.key} has no blurb"
      assert project.url.start_with?("https://"), "#{project.key} link is not absolute"
      assert project.stack.any?, "#{project.key} has no stack"
    end
  end

  test "projects never link a repo held back for hygiene" do
    withheld = %w[spamsandwich myrelay rails-rocket-sheep]

    Portfolio.projects.each do |project|
      withheld.each do |repo|
        refute_includes project.url, "github.com/PositiveControl/#{repo}",
                        "#{project.key} links a repo that is not cleared for linking"
      end
    end
  end

  test "roles are ordered newest first and each has highlights" do
    roles = Portfolio.roles

    assert roles.any?
    assert_equal "present", roles.first.period.split(" – ").last

    roles.each do |role|
      assert role.company.present?, "#{role.key} has no company"
      assert role.highlights.any?, "#{role.key} has no highlights"
    end
  end

  test "skill groups are non-empty" do
    assert Portfolio.skill_groups.any?

    Portfolio.skill_groups.each do |group|
      assert group.title.present?
      assert group.items.any?, "#{group.title} has no items"
    end
  end

  test "years shipping is derived from the start year, not hardcoded" do
    assert_equal 2014, Portfolio.profile.started
    assert_equal 11, Portfolio.years_shipping(Date.new(2025, 1, 1))
    assert_equal 12, Portfolio.years_shipping(Date.new(2026, 6, 1))
  end

  test "copy carries no em dashes" do
    offenders = copy_strings.select { |text| text.include?("—") }

    assert_empty offenders, "em dash found in registry copy: #{offenders.first(3).inspect}"
  end

  test "copy carries no middot separators" do
    offenders = copy_strings.select { |text| text.include?(" · ") }

    assert_empty offenders, "middot separator found in registry copy: #{offenders.first(3).inspect}"
  end

  private

  # Every human-readable string the page renders, flattened.
  def copy_strings
    profile = Portfolio.profile.to_h.values.grep(String)
    metrics = Portfolio.metrics.flat_map { |m| [ m.value, m.label, m.detail ] }
    roles = Portfolio.roles.flat_map { |r| [ r.company, r.title, r.period, r.context, *r.highlights ] }
    projects = Portfolio.projects.flat_map { |p| [ p.name, p.kind, p.link_label, p.blurb, *p.points, *p.stack ] }
    skills = Portfolio.skill_groups.flat_map { |g| [ g.title, *g.items ] }

    profile + metrics + roles + projects + skills
  end

  test "fetch lookups raise on an unknown key" do
    assert_equal "harness", Portfolio.project(:harness).name
    assert_raises(KeyError) { Portfolio.project(:nope) }
  end
end

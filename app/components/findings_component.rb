# frozen_string_literal: true

# What a project taught: its findings, each a kind, a title, a body and,
# optionally, its evidence (docs/system/project-entries.md).
#
#   = render FindingsComponent.new(findings: @project.findings)
#
# The kind is a mono word beside its shape, never a color
# (docs/rules/never-color-alone.md). The title and body are Mark explaining, so
# serif. Each finding is finding-<n> in file order, for a link to land on.
#
# A row of toggles, one per kind, narrows the list: the findings of other kinds
# drop to quiet text and are never hidden. The toggles are hidden until the
# filter controller connects, so without scripts every finding reads at full
# strength.
class FindingsComponent < ApplicationComponent
  # The toggles' words, from the kinds themselves: Learnings, Surprises, Takeaways.
  KIND_LABELS = Portfolio::KINDS.to_h { |kind| [ kind, kind.pluralize.capitalize ] }.freeze

  # @param findings [Array<Portfolio::Finding>]
  def initialize(findings:)
    @findings = findings
  end

  def render? = @findings.any?

  private

  attr_reader :findings
end

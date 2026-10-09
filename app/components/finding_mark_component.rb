# frozen_string_literal: true

# The shape a finding's kind is drawn with, in an 18 px slot (size-3), always
# beside the kind's word.
#
#   = render FindingMarkComponent.new(kind: finding.kind)
#
# All three are ink: command, human and machine already own the site's colors
# (docs/rules/color-means-role.md). A learning is an open circle, a surprise a
# bar over a dot, a takeaway an arrow, none of which the chart's triangles or
# the scope's squares can be taken for in greyscale
# (docs/system/project-entries.md).
class FindingMarkComponent < ApplicationComponent
  # The kinds the template draws. Its own list, not Portfolio::KINDS, so a kind
  # added there without a shape here raises instead of drawing an empty slot.
  KINDS = %w[learning surprise takeaway].freeze

  # @param kind [String] one of KINDS
  # @raise [KeyError] for any other kind
  def initialize(kind:)
    raise KeyError, "no mark for finding kind #{kind}" unless KINDS.include?(kind)

    @kind = kind
  end

  private

  attr_reader :kind
end

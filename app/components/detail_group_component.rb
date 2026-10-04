# frozen_string_literal: true

# A group of detail rows: a mono label over a hairline, then rows of mono key
# and serif value (design doc, section 4).
#
#   = render DetailGroupComponent.new(group:)
#   = render DetailGroupComponent.new(group:, level: 3)
#
# A step's body shows these, and so do the project, Background and Contact
# pages. The group is anything with a title and rows of key and value:
# DeliveryThread::Group or SitePage::Group. The key is the machine, in mono;
# the value is a person, in serif (docs/rules/typeface-means-speaker.md).
class DetailGroupComponent < ApplicationComponent
  # @param group [#title, #rows] rows respond to key and value
  # @param level [Integer] the heading level of the label, under the heading it sits beneath
  def initialize(group:, level: 4)
    @group = group
    @level = level
  end

  private

  attr_reader :group

  def heading_tag = :"h#{@level}"
end

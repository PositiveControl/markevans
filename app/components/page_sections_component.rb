# frozen_string_literal: true

# A page's sections, in order: each a heading over serif paragraphs and groups
# of detail rows. The project, Workflow, Background and Contact pages draw
# their content/ sections with it (docs/system/site-pages.md).
#
#   = render PageSectionsComponent.new(sections: @page.sections)
#
# Headings are h2 under the page's h1; a group's label is h3 beneath them.
class PageSectionsComponent < ApplicationComponent
  # @param sections [Array<SitePage::Section>]
  def initialize(sections:)
    @sections = sections
  end

  def render? = @sections.any?

  private

  attr_reader :sections
end

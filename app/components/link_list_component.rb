# frozen_string_literal: true

# Where a project lives, or how to reach Mark: each link's label in mono beside
# where it goes (docs/system/site-pages.md).
#
#   = render LinkListComponent.new(links: @page.links)
#
# A link whose url is still a [placeholder] is shown as text, never as a link
# to nowhere, so the gap stays visible (docs/rules/no-invented-content.md).
class LinkListComponent < ApplicationComponent
  # @param links [Array<SitePage::Link>]
  # @param label [String] the list's accessible name
  def initialize(links:, label: "Links")
    @links = links
    @label = label
  end

  def render? = @links.any?

  private

  attr_reader :links, :label

  # The address as a reader would type it: no scheme, no trailing slash.
  def shown(link) = link.url.delete_prefix("https://").delete_prefix("mailto:").delete_suffix("/")
end

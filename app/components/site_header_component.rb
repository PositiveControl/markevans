# frozen_string_literal: true

# The header every page shares: the name on the left, linking home, and the
# site's sections on the right (design doc, section 4).
#
#   = render SiteHeaderComponent.new(current_path: request.path)
#
# The section the reader is in, its own page or one beneath it, is marked
# aria-current="page" and underlined, never told by color alone
# (docs/rules/never-color-alone.md).
class SiteHeaderComponent < ApplicationComponent
  Section = Data.define(:label, :path)

  # @param current_path [String] the request's path
  def initialize(current_path:)
    @current_path = current_path
  end

  private

  def sections
    [
      Section.new(label: "Work", path: projects_path),
      Section.new(label: "Workflow", path: workflow_path),
      Section.new(label: "Background", path: background_path),
      Section.new(label: "Contact", path: contact_path)
    ]
  end

  def current?(section) = @current_path == section.path || @current_path.start_with?("#{section.path}/")
end

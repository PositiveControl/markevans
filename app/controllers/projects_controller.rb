# The projects, from content/work.yml (docs/system/site-pages.md).
class ProjectsController < ApplicationController
  # Not paginated: eight entries from a content file, which grow by an edit to
  # that file and never with usage (docs/rules/pagination.md).
  def index
    @page = SitePage.fetch(:work)
    @groups = Portfolio.grouped
  end

  # An unknown key raises Portfolio::NotFound, which Rails answers with a 404.
  def show
    @project = Portfolio.fetch(params[:id])
  end
end

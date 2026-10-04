# The CV, from content/pages/background.yml. Prints to one page
# (docs/system/site-pages.md).
class BackgroundsController < ApplicationController
  def show
    @page = SitePage.fetch(:background)
  end
end

# The delivery chain explained: the copy from content/pages/workflow.yml around
# the chain drawn from the home thread (docs/system/site-pages.md).
class WorkflowsController < ApplicationController
  def show
    @page = SitePage.fetch(:workflow)
    @thread = DeliveryThread.fetch(:home)
  end
end

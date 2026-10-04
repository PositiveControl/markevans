# The ways to reach Mark, from content/pages/contact.yml
# (docs/system/site-pages.md).
class ContactsController < ApplicationController
  def show
    @page = SitePage.fetch(:contact)
  end
end

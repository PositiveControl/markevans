# frozen_string_literal: true

# What the layout's <head> says about the page: its title, description and
# canonical URL, each set by the view with content_for or falling back to the
# site's. The meta tags and the link card read the same three, so a page's
# card cannot disagree with its search snippet (docs/sop/add-seo-to-a-page.md).
module PageMetaHelper
  SITE_NAME = "Mark Evans"

  def page_title = content_for(:title) || SITE_NAME

  def page_description = content_for(:meta_description) || SITE_NAME

  # The request's URL without its query string, unless the page names one.
  def page_canonical_url = content_for(:canonical_url) || request.original_url.split("?").first
end

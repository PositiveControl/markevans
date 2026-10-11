module ApplicationHelper
  # A link off the site opens in a new tab, so the reader keeps their place
  # here. noopener keeps the new page from reaching back through window.opener.
  def external_link_to(text, url, **options)
    link_to text, url, target: "_blank", rel: "noopener noreferrer", **options
  end
end

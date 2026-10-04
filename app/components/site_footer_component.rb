# frozen_string_literal: true

# The footer every page shares: the signature, and the line about how the site
# is built. A page may put its own items between them, as the home page puts
# its keyboard list.
#
#   = render SiteFooterComponent.new
#   = render SiteFooterComponent.new do
#     ul ...
#
# It leaves the printed page, so the CV prints as one (docs/system/site-pages.md).
class SiteFooterComponent < ApplicationComponent
end

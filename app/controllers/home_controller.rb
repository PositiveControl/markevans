class HomeController < ApplicationController
  def index
  end

  def sitemap
    require "builder"
    expires_in 1.hour, public: true

    builder = Builder::XmlMarkup.new(indent: 2)
    builder.instruct!

    xml = builder.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do |urlset|
      # Homepage
      urlset.url do |url|
        url.loc root_url
        url.changefreq "daily"
        url.priority "1.0"
      end

      # Add your pages here — see docs/sop/add-seo-to-a-page.md
    end

    render xml: xml
  end
end

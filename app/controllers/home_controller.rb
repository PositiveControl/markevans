class HomeController < ApplicationController
  def index
    @thread = DeliveryThread.fetch(:home)
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

      # The site's other pages, then each project from content/work.yml, so a
      # project added to the file is listed with no edit here
      # (docs/sop/add-seo-to-a-page.md).
      [ projects_url, workflow_url, background_url, contact_url ].each do |loc|
        urlset.url do |url|
          url.loc loc
          url.changefreq "monthly"
          url.priority "0.8"
        end
      end

      Portfolio.all.each do |project|
        urlset.url do |url|
          url.loc project_url(project.key)
          url.changefreq "monthly"
          url.priority "0.6"
        end
      end
    end

    render xml: xml
  end
end

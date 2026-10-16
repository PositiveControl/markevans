# /robots.txt, from a route so its Sitemap line names the host it was asked
# for and can never point at another (docs/system/site-pages.md, SEO).
class RobotsController < ApplicationController
  RULES = <<~ROBOTS
    # https://www.robotstxt.org/robotstxt.html
    User-agent: *
    Allow: /
    Disallow: /admin/
    Disallow: /api/
    Disallow: /users/sign_in
    Disallow: /users/sign_up
  ROBOTS

  def show
    expires_in 1.hour, public: true
    render plain: "#{RULES}\nSitemap: #{sitemap_url(format: :xml)}\n"
  end
end

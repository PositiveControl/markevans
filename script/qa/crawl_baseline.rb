# frozen_string_literal: true

# The crawl baseline (#56): what a crawler and a share now see. robots.txt is
# served by a route and names this host's sitemap; every page shares one link
# card image.
#
# Builds no data. The host and the card's path are read from the running
# server and the asset pipeline, never written as literals.
#
# Not walked: the head tags and JSON-LD (og:*, twitter:card, the Person and
# each page's @id reference) are not on the page to spotlight; seo_test.rb
# reads them on every page. The www redirect needs the real www host and its
# certificate; www_redirect_test.rb covers it, and after deploy
# `curl -sI https://www.markevans.io/work` shows the 301.
require Rails.root.join("lib/qa_walkthrough")

card = ActionController::Base.helpers.asset_path("card.png")

QaWalkthrough.run("crawl_baseline") do
  step "robots.txt comes from a route, and its Sitemap line names this host" do
    page.current_window.resize_to(1400, 1000)
    visit "/robots.txt"
    spotlight text: "Sitemap: #{page.current_host}", note: "the host this page was asked on; it was https://YOURAPP.com"
  end

  step "The link card every page shares when pasted into LinkedIn, Slack or an ATS" do
    visit card
    spotlight "img", note: "1200×630, rendered from card.svg in the tokens' colours"
  end
end

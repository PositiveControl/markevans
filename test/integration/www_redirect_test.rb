# frozen_string_literal: true

require "test_helper"

# www.markevans.io is a second name for the site. It answers only with a
# permanent redirect to the apex, so the site's ranking never splits across
# two hosts (docs/system/site-pages.md, SEO).
class WwwRedirectTest < ActionDispatch::IntegrationTest
  setup { host! "www.markevans.io" }

  test "the root moves permanently to the apex" do
    get "/"

    assert_response :moved_permanently
    assert_redirected_to "https://markevans.io/"
  end

  test "a page keeps its path and query on the apex" do
    get "/work?tag=Ruby"

    assert_redirected_to "https://markevans.io/work?tag=Ruby"
  end

  test "files keep their extension, so robots.txt and the sitemap move too" do
    get "/sitemap.xml"

    assert_redirected_to "https://markevans.io/sitemap.xml"
  end

  test "the apex itself is served, not redirected" do
    host! "markevans.io"
    get "/work"

    assert_response :success
  end
end

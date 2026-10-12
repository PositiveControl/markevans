# frozen_string_literal: true

require "test_helper"

class PageMetaHelperTest < ActionView::TestCase
  test "a page that sets nothing falls back to the site's name and its own URL, without the query" do
    request.path = "/users/sign_in"
    request.set_header("QUERY_STRING", "a=1")

    assert_equal "Mark Evans", page_title
    assert_equal "Mark Evans", page_description
    assert_equal "http://test.host/users/sign_in", page_canonical_url
  end

  test "a page's own title, description and canonical URL win" do
    content_for :title, "Work · Mark Evans"
    content_for :meta_description, "The projects."
    content_for :canonical_url, "https://markevans.io/work"

    assert_equal [ "Work · Mark Evans", "The projects.", "https://markevans.io/work" ], [ page_title, page_description, page_canonical_url ]
  end
end

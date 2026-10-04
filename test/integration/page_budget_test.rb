# frozen_string_literal: true

require "test_helper"
require "zlib"

# The budget gate (design doc, section 7): what the home page asks the browser
# to load. Everything is measured as served, by following the page's own
# references: the importmap for scripts, the stylesheets' url()s for fonts. A
# new pin, controller or font counts the moment it is referenced, and a file
# that sits in the repo unreferenced does not.
#
# A kB here is 1,000 bytes. Scripts are measured gzipped, as they travel;
# fonts as they are, since woff2 is compressed already.
#
# The browser's own view, every request the page makes, is in
# test/system/page_requests_test.rb.
class PageBudgetTest < ActionDispatch::IntegrationTest
  SCRIPTS_LIMIT = 60_000
  FONTS_LIMIT = 120_000

  test "the scripts the page can import come to 60 kB gzipped or less" do
    sizes = scripts.to_h { |url| [ url, Zlib.gzip(fetch(url)).bytesize ] }

    assert_operator sizes.size, :>, 1, "no scripts found in the importmap"
    assert_operator sizes.values.sum, :<=, SCRIPTS_LIMIT,
      "scripts are #{sizes.values.sum} bytes gzipped, over #{SCRIPTS_LIMIT}. Largest: #{largest(sizes)}"
  end

  test "the fonts the stylesheets load come to 120 kB or less" do
    sizes = fonts.to_h { |url| [ url, fetch(url).bytesize ] }

    assert_operator sizes.size, :>, 0, "no fonts found in the stylesheets"
    assert_operator sizes.values.sum, :<=, FONTS_LIMIT,
      "fonts are #{sizes.values.sum} bytes, over #{FONTS_LIMIT}. Largest: #{largest(sizes)}"
  end

  test "nothing the page loads comes from another host" do
    foreign = (references + scripts + fonts).reject { |url| local?(url) }

    assert_empty foreign, "third-party requests"
  end

  private

  # Every URL an element on the page loads by itself: links to pages do not
  # count, stylesheets, preloads, scripts, images and frames do.
  def references
    page = Nokogiri::HTML(home)
    page.css("link[href]:not([rel=canonical])").map { |link| link["href"] } +
      page.css("script[src], img[src], iframe[src], source[src], video[src], audio[src]").map { |element| element["src"] }
  end

  def scripts
    map = Nokogiri::HTML(home).at_css("script[type=importmap]")
    JSON.parse(map.text).fetch("imports").values.uniq
  end

  def stylesheets
    Nokogiri::HTML(home).css("link[rel=stylesheet]").map { |link| link["href"] }
  end

  def fonts
    stylesheets.select { |url| local?(url) }.flat_map do |sheet|
      fetch(sheet).scan(/url\(\s*["']?([^"')]+\.woff2?)["']?\s*\)/).flatten.map { |font| URI.join(root_url, sheet, font).to_s }
    end.uniq
  end

  def home
    @home ||= begin
      get root_url
      response.body
    end
  end

  def fetch(url)
    get url
    assert_response :success, "#{url} did not load"
    response.body
  end

  def local?(url)
    host = URI(url).host
    host.nil? || host == URI(root_url).host
  end

  def largest(sizes) = sizes.max_by(&:last).then { |url, size| "#{url} (#{size})" }
end

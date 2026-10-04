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
    foreign = (references + scripts + stylesheet_urls).reject { |url| local?(url) }

    assert_empty foreign, "third-party requests"
  end

  test "the gate reads every url() and @import in a stylesheet, not only fonts" do
    css = <<~CSS
      @import "https://fonts.example/a.css";
      @import url(https://fonts.example/b.css) screen;
      .x { background: url('https://cdn.example/x.png'); src: url(local.woff2) }
    CSS

    assert_equal %w[https://fonts.example/a.css https://fonts.example/b.css https://cdn.example/x.png local.woff2], urls_in(css)
  end

  test "an inline data: url is no request, so the gate leaves it out" do
    css = %(.x { background: url("data:image/svg+xml;utf8,<svg/>") } .y { background: url(https://cdn.example/y.png) })

    assert_equal %w[https://cdn.example/y.png], urls_in(css)
  end

  test "the gate counts a plain script tag as well as the importmap" do
    html = <<~HTML
      <script type="importmap">{"imports": {"app": "/assets/app.js"}}</script>
      <script src="/assets/shim.js"></script>
    HTML

    assert_equal %w[/assets/app.js /assets/shim.js], scripts_in(html)
  end

  private

  # Every URL an element on the page loads by itself: links to pages do not
  # count, stylesheets, preloads, scripts, images and frames do.
  def references
    page = Nokogiri::HTML(home)
    page.css("link[href]:not([rel=canonical])").map { |link| link["href"] } +
      page.css("script[src], img[src], iframe[src], source[src], video[src], audio[src]").map { |element| element["src"] }
  end

  # The importmap's entries and every plain script tag: all of them load.
  def scripts = scripts_in(home)

  def scripts_in(html)
    page = Nokogiri::HTML(html)
    imports = page.css("script[type=importmap]").flat_map { |map| JSON.parse(map.text).fetch("imports").values }
    (imports + page.css("script[src]").map { |script| script["src"] }).uniq
  end

  def stylesheets
    Nokogiri::HTML(home).css("link[rel=stylesheet]").map { |link| link["href"] }
  end

  # Every url() and @import in the page's own stylesheets, resolved.
  def stylesheet_urls
    stylesheets.select { |url| local?(url) }.flat_map do |sheet|
      urls_in(fetch(sheet)).map { |url| URI.join(root_url, sheet, url).to_s }
    end.uniq
  end

  def fonts = stylesheet_urls.select { |url| url.match?(/\.woff2?\z/) }

  # A quoted url() runs to its closing quote, so quotes inside it do not cut it
  # short. An inline data: url is no request and is left out.
  def urls_in(css)
    css.scan(/url\(\s*(?:"([^"]*)"|'([^']*)'|([^)\s]+))\s*\)|@import\s+["']([^"']+)["']/)
      .map { |groups| groups.compact.first }.reject { |url| url.start_with?("data:") }
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

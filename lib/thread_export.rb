# frozen_string_literal: true

require "base64"

# The root page as one HTML file that needs nothing else: no server and no
# network. It is for stepping through the thread by hand on a
# shared screen (docs/plans/2026-10-07-static-thread-export-design.md).
#
#   ThreadExport.new.call # => String of HTML
#
# The page is requested from the app as a browser would, so the file is
# whatever the page shows from content/threads/home.yml at the moment it runs.
# Nothing is rebuilt here; the page is only reduced to its no-script reading
# (docs/system/home-thread-playback.md, Without scripts):
#
#   - each stylesheet becomes a <style>, its fonts data: URIs
#   - every script and link goes, so the page loads nothing; one inline
#     script folds the strips (STRIPS)
#   - what only playback or the filter reveal goes, and so does their wiring
#   - the header keeps the site name as text and drops its links to pages the
#     file does not have
#   - the headline, intro and scope go, so the thread starts the page
#   - the file declares UTF-8 itself: the server said so in a header, and a
#     file opened from disk has none
#
# Run it under RAILS_ENV=test (bin/export-thread): the page queries nothing,
# but development's pending-migration check opens a database connection on
# every request.
class ThreadExport
  # A reference left in the result: the file would load it, and fail to.
  class NotSelfContained < StandardError; end

  # Rendered hidden, and shown only once playback or the filter connects.
  LIVE = "[data-playback-target~=live], [data-filter-target~=live]"

  # Attributes that only hook the page to Turbo and its Stimulus controllers.
  WIRING = /\Adata-(controller|action|turbo-track|playback-|filter-)/

  # The file's one script. Every strip starts collapsed, and each opens or
  # closes its own row. It writes what playback writes (data-open on the row,
  # aria-expanded on the strip), so the page's own roll-up does the folding,
  # and the chart cell, whose lines hang off the row's edges, folds with it.
  # data-settling on <html> holds the first draw still, as playback does.
  # Without it the file stays the no-script reading, every strip open.
  STRIPS = <<~JS
    (() => {
      const root = document.documentElement
      const fold = (strip, open) => {
        strip.closest("[data-lane]").dataset.open = open
        strip.setAttribute("aria-expanded", open)
      }
      root.dataset.settling = ""
      document.querySelectorAll("h3 button[aria-controls]").forEach(strip => {
        strip.disabled = false
        fold(strip, false)
        strip.addEventListener("click", () => fold(strip, strip.getAttribute("aria-expanded") !== "true"))
      })
      requestAnimationFrame(() => requestAnimationFrame(() => delete root.dataset.settling))
    })()
  JS

  # A quoted url() runs to its closing quote; @import may name its sheet bare.
  URL = /url\(\s*(?:"([^"]*)"|'([^']*)'|([^)\s]+))\s*\)/
  IMPORT = /@import\s+["']([^"']+)["']/

  # The attributes a browser loads a URL from. srcset lists candidates, each a
  # URL and a size; a style attribute holds url()s like a stylesheet. CSS
  # image-set() with bare strings is not read: Tailwind does not write it.
  LOADS = %w[href xlink:href src poster data background].freeze

  # Between srcset candidates: a comma before whitespace, or straight after a
  # descriptor ("2x,", "640w,"). Not every comma: a data: URI holds one.
  CANDIDATES = /,\s+|(?<=\d[xw]),/

  # Every reference in the HTML a browser would load that is neither a data:
  # URI nor a link within the page: in attributes, inline styles and <style>.
  def self.foreign_references(html)
    page = Nokogiri::HTML5(html)
    markup = page.css("*").flat_map do |element|
      element.attribute_nodes.flat_map do |attribute|
        case attribute.name
        when *LOADS then [ attribute.value ]
        when "srcset" then attribute.value.split(CANDIDATES).map { |candidate| candidate.split.first&.delete_suffix(",") }
        when "style" then css_references(attribute.value)
        else []
        end
      end
    end
    styles = page.css("style").flat_map { |style| css_references(style.text) }

    (markup + styles).compact.reject { |url| url.start_with?("data:", "#") }
  end

  def self.css_references(css) = css.scan(Regexp.union(URL, IMPORT)).map { |groups| groups.compact.first }

  def call
    page = Nokogiri::HTML5(render)
    inline_stylesheets(page)
    page.css("script, link, meta[name^=csrf], meta[name=csp-nonce]").each(&:remove)
    page.css(LIVE).each(&:remove)
    unwire(page)
    unlink_header(page)
    drop_above_thread(page)
    page.at_css("body").add_child(page.create_element("script", STRIPS))
    page.at_css("head").prepend_child(page.create_element("meta", charset: "utf-8"))

    page.to_html.tap { |html| verify!(html) }
  end

  private

  def render = fetch("/").body

  def inline_stylesheets(page)
    page.css("link[rel=stylesheet]").each do |link|
      sheet = link["href"]
      css = fetch(sheet).body.gsub(URL) do |match|
        url = Regexp.last_match.captures.compact.first
        url.start_with?("data:") ? match : "url(#{data_uri(URI.join("http://localhost#{sheet}", url).request_uri)})"
      end
      link.replace(page.create_element("style", css))
    end
  end

  def data_uri(path)
    response = fetch(path)
    "data:#{response.media_type};base64,#{Base64.strict_encode64(response.body)}"
  end

  def unwire(page)
    page.css("*").each do |element|
      element.attributes.each_key { |name| element.remove_attribute(name) if name.match?(WIRING) }
    end
  end

  def unlink_header(page)
    page.css("header nav").each(&:remove)
    page.css("header a").each do |link|
      link.name = "span"
      link.remove_attribute("href")
    end
  end

  # The thread starts the page: the headline and intro go, with the section
  # that held them, and so does the scope, with the legend's key to its marks
  # and the label of the column it shared with the legend.
  def drop_above_thread(page)
    page.css("main h1").each { |headline| headline.parent.remove }
    page.css("[aria-label=Scope]").each(&:remove)
    page.css("[aria-label=Legend] li").select { |item| item.text.strip == "target on scope" }.each(&:remove)
    page.css("aside[aria-label]").each { |aside| aside.remove_attribute("aria-label") }
  end

  def verify!(html)
    foreign = self.class.foreign_references(html)
    raise NotSelfContained, "the export still references: #{foreign.join(", ")}" if foreign.any?
  end

  def fetch(path)
    session.get(path)
    response = session.response
    raise "GET #{path} returned #{response.status}" unless response.successful?

    response
  end

  def session
    @session ||= ActionDispatch::Integration::Session.new(Rails.application).tap { |session| session.host!("localhost") }
  end
end

require "test_helper"

# The root page as one self-contained file, for stepping through the thread by
# hand on a shared screen (docs/plans/2026-10-07-static-thread-export-design.md).
# Steps are read from the thread file, never named, so the test follows it.
class ThreadExportTest < ActiveSupport::TestCase
  # Rendering the page and fetching its stylesheets and fonts is the slow part,
  # and no test changes the result, so it is built once.
  TITLE = "A thread, exported"

  def self.html = @html ||= ThreadExport.new(title: TITLE).call

  setup do
    @thread = DeliveryThread.fetch(:home)
    @page = Nokogiri::HTML5(self.class.html)
  end

  test "every word each step shows from the thread file is in the export" do
    text = @page.text

    @thread.steps.each do |step|
      words = [ step.name, step.body, step.outcome, step.note, step.artifact&.source, step.artifact&.body ] +
        step.groups.flat_map { |group| [ group.title, *group.rows.flat_map { |row| [ row.key, row.value ] } ] }
      words.compact.each { |phrase| assert_includes text, phrase, step.key }
    end
  end

  test "without scripts every strip is open, in the thread's order, and waits for the script to work" do
    rows = @page.css("[aria-labelledby=thread-heading] > div[id]")

    assert_equal @thread.steps.map(&:key), rows.map { |row| row["id"] }
    assert_empty @page.css("[data-open], [data-state]")
    rows.each do |row|
      strip = row.at_css("h3 button")
      assert strip.key?("disabled"), "#{row["id"]}: a strip that does nothing without scripts is disabled"
      assert @page.at_css("##{strip["aria-controls"]}"), "#{row["id"]}: the strip controls no body"
    end
  end

  test "the title takes the headline's place and the tab's, with no intro or scope beside it" do
    text = @page.text

    assert_equal [ TITLE ], @page.css("h1").map(&:text)
    assert_equal TITLE, @page.at_css("title").text
    refute_includes text, @thread.headline
    refute_includes text, @thread.intro
    assert_nil @page.at_css("[aria-label=Scope]")
    assert_empty @page.css("a[href^='#']")
    refute_includes @page.at_css("[aria-label=Legend]").text, "target on scope"
  end

  test "what only playback or the filter reveal is left out, and so is their wiring" do
    assert_empty @page.css("[data-playback-target~=live], [data-filter-target~=live]")
    assert_nil @page.at_css("[aria-label='Docked playback']")
    assert_nil @page.at_css("[aria-label=Keyboard]")
    assert_empty @page.css("[data-controller], [data-action], [data-turbo-track]")
    assert_empty @page.css("*").flat_map { |element| element.attributes.keys.grep(/\Adata-(playback|filter)-/) }
  end

  test "the file declares UTF-8 itself, since from disk there is no header to say so" do
    assert_equal "utf-8", @page.at_css("head > meta:first-child")&.[]("charset")
  end

  test "the site header and footer go: the file is the thread, not a page of the site" do
    assert_nil @page.at_css("header")
    assert_nil @page.at_css("nav")
    assert_nil @page.at_css("footer")
  end

  test "the file runs one inline script, the strips', and loads nothing: no link, no url but data: and #" do
    scripts = @page.css("script")

    assert_equal 1, scripts.size
    assert_nil scripts.first["src"]
    assert_includes scripts.first.text, "aria-expanded"
    assert_empty @page.css("link")
    assert_empty ThreadExport.foreign_references(self.class.html)
    assert_includes @page.css("style").text, "url(data:font/woff2;base64,"
  end

  test "a reference left outside the file is caught, in markup or in a stylesheet" do
    html = <<~HTML
      <style>.x { src: url(/assets/a.woff2) } .y { background: url("data:image/png;base64,AA") }</style>
      <style>@import "https://cdn.example/b.css";</style>
      <a href="#pick">ok</a> <a href="/work">no</a> <img src="https://cdn.example/c.png">
    HTML

    assert_equal %w[/work https://cdn.example/c.png /assets/a.woff2 https://cdn.example/b.css],
      ThreadExport.foreign_references(html)
  end

  test "every attribute a browser loads from is read, inline styles too" do
    html = <<~HTML
      <img srcset="/a.png 2x, data:image/png;base64,AA 3x"> <img srcset="/b.png 1x,/c.png 2x"> <img srcset="/d.png, /e.png"> <video poster="/p.png"></video>
      <object data="/o.svg"></object> <div style="background: url('/s.png')"></div>
      <svg><use xlink:href="/sprite.svg#x"></use></svg> <div data-href="/not-loaded"></div>
      <table background="/bg.png"></table>
    HTML

    assert_equal %w[/a.png /b.png /c.png /d.png /e.png /p.png /o.svg /s.png /sprite.svg#x /bg.png], ThreadExport.foreign_references(html)
  end

  test "the export refuses to hand back a file that is not self-contained" do
    export = ThreadExport.new(title: TITLE)
    export.define_singleton_method(:render) do
      "<html><head><title></title></head><body><main><section><h1></h1></section></main><img src='/icon.png'></body></html>"
    end

    error = assert_raises(ThreadExport::NotSelfContained) { export.call }
    assert_includes error.message, "/icon.png"
  end
end

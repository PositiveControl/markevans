require "test_helper"

# The root page as one self-contained file, for stepping through the thread by
# hand on a shared screen (docs/plans/2026-10-07-static-thread-export-design.md).
# Steps are read from the thread file, never named, so the test follows it.
class ThreadExportTest < ActiveSupport::TestCase
  # Rendering the page and fetching its stylesheets and fonts is the slow part,
  # and no test changes the result, so it is built once.
  def self.html = @html ||= ThreadExport.new.call

  setup do
    @thread = DeliveryThread.fetch(:home)
    @page = Nokogiri::HTML(self.class.html)
  end

  test "every word the page shows from the thread file is in the export" do
    text = @page.text

    assert_includes text, @thread.headline
    assert_includes text, @thread.intro
    @thread.steps.each do |step|
      words = [ step.name, step.body, step.outcome, step.note, step.artifact&.source, step.artifact&.body ] +
        step.groups.flat_map { |group| [ group.title, *group.rows.flat_map { |row| [ row.key, row.value ] } ] }
      words.compact.each { |phrase| assert_includes text, phrase, step.key }
    end
  end

  test "every strip is open, and each scope target links to its step's row" do
    targets = @page.css("[aria-label='Scope and playback'] a[href^='#']")

    assert_equal @thread.steps.map { |step| "##{step.key}" }, targets.map { |a| a["href"] }
    @thread.steps.each { |step| assert @page.at_css("##{step.key}"), "no row for #{step.key}" }
    assert_empty @page.css("[data-open], [data-state]")
  end

  test "what only playback or the filter reveal is left out, and so is their wiring" do
    assert_empty @page.css("[data-playback-target~=live], [data-filter-target~=live]")
    assert_nil @page.at_css("[aria-label='Docked playback']")
    assert_nil @page.at_css("[aria-label=Keyboard]")
    assert_empty @page.css("[data-controller], [data-action], [data-turbo-track]")
    assert_empty @page.css("*").flat_map { |element| element.attributes.keys.grep(/\Adata-(playback|filter)-/) }
  end

  test "the header keeps the site name as text, with no links to pages the file does not have" do
    header = @page.at_css("header")

    assert_includes header.text, "Mark Evans"
    assert_nil header.at_css("nav")
    assert_empty header.css("a")
  end

  test "the file runs no script and loads nothing: no link, no url but data: and #" do
    assert_empty @page.css("script, link")
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
    HTML

    assert_equal %w[/a.png /b.png /c.png /d.png /e.png /p.png /o.svg /s.png /sprite.svg#x], ThreadExport.foreign_references(html)
  end

  test "the export refuses to hand back a file that is not self-contained" do
    export = ThreadExport.new
    export.define_singleton_method(:render) { "<html><body><img src='/icon.png'></body></html>" }

    error = assert_raises(ThreadExport::NotSelfContained) { export.call }
    assert_includes error.message, "/icon.png"
  end
end

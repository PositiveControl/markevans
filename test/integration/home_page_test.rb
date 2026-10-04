# frozen_string_literal: true

require "test_helper"

# The home page without scripts: every strip open, in order (design doc,
# section 6). What playback adds is tested with playback.
class HomePageTest < ActionDispatch::IntegrationTest
  setup { @thread = DeliveryThread.fetch(:home) }

  test "the headline and intro come from the thread file" do
    get root_url

    assert_response :success
    assert_select "h1", text: @thread.headline
    assert_select "main p", text: @thread.intro
    assert_select "meta[name=description][content=?]", @thread.headline
  end

  test "a long headline is cut to a search snippet's length in the meta description" do
    long = @thread.with(headline: "word " * 60)
    # Minitest 6 no longer ships stub, so swap fetch by hand and put it back.
    original = DeliveryThread.method(:fetch)
    DeliveryThread.define_singleton_method(:fetch) { |*| long }

    get root_url

    content = css_select("meta[name=description]").first["content"]
    assert_operator content.length, :<=, 155
    assert content.end_with?("...")
  ensure
    DeliveryThread.define_singleton_method(:fetch, original)
  end

  test "the header names the site and links home, and nothing else yet" do
    get root_url

    assert_select "header a", count: 1
    assert_select "header a[href=?]", root_path, text: "Mark Evans"
  end

  test "every step renders open, in the thread file's order" do
    get root_url

    keys = css_select("section[aria-labelledby=thread-heading] > div[id]").map { |row| row["id"] }
    assert_equal @thread.steps.map(&:key), keys

    @thread.steps.each do |step|
      assert_select "##{step.key} h3 button", text: /\A0?#{@thread.steps.index(step) + 1} #{Regexp.escape(step.name)} Ctl/
      assert_select "##{step.key}-body"
      assert_includes response.body, ERB::Util.html_escape(step.body)
    end
  end

  test "each row draws its chart cell beside its strip, hidden from assistive tech" do
    get root_url

    assert_select "section[aria-labelledby=thread-heading] > div[id] > div[aria-hidden=true] [data-chart=fix]", count: @thread.steps.size
  end

  test "the graph follows the file: its forks, merges, loops, sectors and labels" do
    get root_url

    events = @thread.steps.map { |step| step.git.event }.tally
    %w[fork merge loop].each { |event| assert_select "[data-git-event=#{event}]", count: events[event] }
    assert_select "[data-chart=loop]", count: events["loop"]
    assert_select "[data-chart=sector]", count: @thread.cells.count(&:sector)
    assert_equal @thread.steps.filter_map { |step| step.git.label }, css_select("[data-chart=label]").map(&:text)
  end

  test "the legend renders beside the headline" do
    get root_url

    assert_select "aside [aria-label=Legend] li", count: 8
  end

  test "without scripts each strip is a disabled button with no status word, its body open" do
    get root_url

    assert_select "[data-playback-target=strip][disabled][aria-expanded=true]", count: @thread.steps.size
    assert_select "[data-playback-target=strip]:not([disabled])", count: 0
    assert_select "[data-playback-target=status]", text: "", count: @thread.steps.size
    assert_select "[data-open], [data-state]", count: 0
  end

  test "without scripts the scope is a map: one link per step, and nothing to press" do
    get root_url

    hrefs = css_select("[aria-label=Scope] a").map { |link| link["href"] }
    assert_equal @thread.steps.map { |step| "##{step.key}" }, hrefs
    assert_select "[aria-label=Scope] [data-playback-target=live]:not([hidden])", count: 0
    assert_select "[aria-label=Scope] [hidden] button", count: 4
  end

  test "each row carries its step's seconds for the playback clock, its bay and its lane" do
    get root_url

    @thread.steps.each do |step|
      assert_select "##{step.key}[style=?][data-bay=?][data-lane=?]", "--seconds: #{step.duration}", step.bay, step.lane
    end
  end

  test "without scripts the read-outs of playback state are not shown" do
    get root_url

    assert_select "[aria-label='Strip bay'][hidden]", count: 2 # the aside's, and the docked bar's
    assert_select "[aria-label='Strip bay']:not([hidden])", count: 0
    assert_select "[aria-labelledby=controller-filter][hidden] button", count: 4
    assert_select "[data-dim]", count: 0
    assert_select "section[aria-labelledby=log-heading][hidden]", count: 1
    assert_select "[aria-label='Docked playback'][hidden]", count: 1
  end

  test "the footer signs the page, and its key list waits for playback" do
    get root_url

    assert_select "footer", text: /Mark Evans · PositiveControl/
    assert_select "footer", text: /This site is built with the workflow it describes\./
    assert_select "footer ul[aria-label='Keyboard'][hidden][data-playback-target=live] kbd", count: 6
    assert_select "footer [aria-label='Keyboard'] kbd", text: @thread.steps.count(&:gate?).to_s
  end

  test "playback and the filter sit on a wrapper around main and the footer, so both read one state" do
    get root_url

    assert_select "[data-controller='playback filter'] > main"
    assert_select "[data-controller='playback filter'] > footer"
    assert_select "main[data-controller]", count: 0
  end

  test "the log counts gates out of the thread's own total" do
    get root_url

    assert_select "#log-heading ~ span", text: /Gates cleared\s+0\s+\/ #{@thread.steps.count(&:gate?)}/
  end

  test "self-hosted fonts are preloaded, not fetched from a third party" do
    get root_url

    assert_select "link[rel=preload][as=font]", 3
    refute_includes response.body, "fonts.googleapis.com"
    refute_includes response.body, "fonts.gstatic.com"
  end

  test "none of the portfolio page is left" do
    get root_url

    %w[palette reveal caret].each do |name|
      assert_select "[data-controller~=#{name}], .#{name}", count: 0
    end
    refute_includes response.body, "Command palette"
  end
end

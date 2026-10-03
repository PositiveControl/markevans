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
      assert_select "##{step.key} h3", text: step.name
      assert_includes response.body, ERB::Util.html_escape(step.body)
    end
  end

  test "each row draws its chart cell beside its strip, hidden from assistive tech" do
    get root_url

    assert_select "section[aria-labelledby=thread-heading] > div[id] > div.w-column[aria-hidden=true] [data-chart=fix]", count: @thread.steps.size
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

  test "the thread has no controls until playback exists" do
    get root_url

    assert_select "section[aria-labelledby=thread-heading] button", count: 0
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

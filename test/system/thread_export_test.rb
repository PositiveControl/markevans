require "application_system_test_case"

# The exported file in a browser, opened from disk as it is in a meeting
# (docs/sop/export-the-thread.md): its one script folds the strips, and the
# git graph beside each strip folds with its row. Steps are picked by
# position, never by key.
class ThreadExportTest < ApplicationSystemTestCase
  setup do
    @steps = DeliveryThread.fetch(:home).steps
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "thread.html")
    File.write(@path, ThreadExport.new.call)
  end

  teardown { FileUtils.rm_rf(@dir) }

  test "every strip loads collapsed, and the first draw does not animate" do
    visit "file://#{@path}"

    assert_selector "[data-open=false]", count: @steps.size
    assert_selector "h3 button[aria-expanded=false]:not([disabled])", count: @steps.size
    assert_no_selector "[data-settling]"
    assert_no_text @steps.first.body
    assert_accessible
  end

  test "a strip opens and closes its own row, and the git graph beside it follows" do
    visit "file://#{@path}"
    first = @steps.first
    closed = row_height(first.key)

    strip(first).click

    assert_selector "##{first.key}[data-open=true]"
    assert_selector "##{first.key} h3 button[aria-expanded=true]"
    assert_text first.body
    assert_selector "##{@steps.second.key}[data-open=false]"
    assert_operator chart_height(first.key), :>, closed
    assert_accessible

    strip(first).click

    assert_selector "##{first.key}[data-open=false]"
    assert_no_text first.body
    assert_equal closed, row_height(first.key)
  end

  test "without scripts the file reads as a document: every strip open" do
    with_scripts_off do
      visit "file://#{@path}"

      assert_no_selector "[data-open]"
      assert_text @steps.last.body
    end
  end

  private

  # The file's script is inline, so without_scripts, which blocks .js URLs,
  # cannot reach it. Chrome's own switch can; it would block axe too, and no
  # axe runs here.
  def with_scripts_off
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setScriptExecutionDisabled", value: true)
    yield
  ensure
    browser.execute_cdp("Emulation.setScriptExecutionDisabled", value: false)
  end

  def strip(step) = find("##{step.key} h3 button")

  # The roll-up eases for 200 ms, so a height is read once it has settled.
  def row_height(key) = settled_height("##{key}")

  def chart_height(key) = settled_height("##{key} [data-git-event], ##{key} > [aria-hidden=true]")

  def settled_height(selector)
    script = "document.querySelector(#{selector.to_json}).getBoundingClientRect().height"
    previous = nil
    10.times do
      height = evaluate_script(script)
      return height if height == previous

      previous = height
      sleep 0.05
    end
    previous
  end
end

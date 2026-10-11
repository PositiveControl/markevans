require "test_helper"
require "axe/matchers/be_axe_clean"

# axe's default run fans out through about:blank frames and times out against
# headless Chrome here; the single-frame run covers a page without iframes.
Axe::Configuration.instance.legacy_mode = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # The accessibility gate (docs/rules/real-controls.md): axe finds nothing on
  # the page as it stands.
  def assert_accessible
    axe = Axe::Matchers::BeAxeClean.new.according_to(:wcag2a, :wcag2aa)
    assert axe.matches?(page), -> { axe.failure_message }
  end

  # Runs the block with every script the page loads blocked, so the page is
  # what a reader without scripts gets. axe still runs: it is injected by the
  # driver, not loaded by the page. Chrome's own script switch would block
  # axe's callback too.
  def without_scripts
    browser = page.driver.browser
    browser.execute_cdp("Network.enable")
    browser.execute_cdp("Network.setBlockedURLs", urls: [ "*.js" ])
    yield
  ensure
    browser.execute_cdp("Network.setBlockedURLs", urls: [])
  end

  # Runs the block with the page styled for print, then back for the screen.
  def as_print
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
    yield
  ensure
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
  end

  # Runs the block with the viewport at the given size, then puts it back.
  def at_size(width, height)
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height:, deviceScaleFactor: 1, mobile: false)
    yield
  ensure
    browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  def assert_no_sideways_scroll
    widths = evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")
    assert_operator widths.first, :<=, widths.last, "the page is #{widths.first} px wide in a #{widths.last} px viewport"
  end
end

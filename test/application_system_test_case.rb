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
end

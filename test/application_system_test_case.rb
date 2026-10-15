require "test_helper"

# Base for browser-driven system tests (Capybara + headless Chrome). These exercise the
# JS-driven UX that server-rendering tests can't reach: the Stimulus tree canvas, the
# debounced combobox/search Turbo Frames, and the Lexxy rich-text editor mounting.
#
# NOTE: requires a Chrome/Chromium + chromedriver on the host. They are NOT part of the
# default `bin/rails test` run — execute with `bin/rails test:system`.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    # Rails eagerly pins Chrome::Service.driver_path (Browser#preload), which makes
    # selenium-webdriver skip Selenium Manager at session time — the managed browser
    # path is lost and chromedriver falls back to whatever "chrome" it finds on the
    # system (on WSL that's /usr/bin/chromium-browser, a snap stub that exits at once:
    # "session not created: Chrome instance exited"). Resolve the browser through
    # Selenium Manager ourselves so driver and browser stay a matched pair.
    paths = Selenium::WebDriver::SeleniumManager.binary_paths("--browser", "chrome")
    options.binary = paths["browser_path"] if paths["browser_path"].present?
  end

  # Absorb Turbo navigation / Stimulus-connect latency under load (default is 2s).
  Capybara.default_max_wait_time = 5

  # Block until the Stimulus controller `identifier` is actually connected to the element
  # matched by `selector`. Without this, an input we dispatch can fire before Stimulus has
  # wired its action, so the debounced submit never runs — the dominant source of flake in
  # the debounced search/combobox UX.
  def wait_for_stimulus(identifier, selector)
    Timeout.timeout(Capybara.default_max_wait_time) do
      until page.evaluate_script(
        "(() => { const el = document.querySelector(arguments[0]); " \
        "return !!(window.Stimulus && el && " \
        "window.Stimulus.getControllerForElementAndIdentifier(el, arguments[1])); })()",
        selector, identifier
      )
        sleep 0.05
      end
    end
  end

  # TEMPORARY CI diagnostics: keep the page, the console and the server log of a failed test.
  teardown do
    next if passed?
    dir = Rails.root.join("tmp/screenshots"); FileUtils.mkdir_p(dir)
    File.write(dir.join("#{method_name}.html"), page.html)
    File.write(dir.join("#{method_name}.console.txt"), page.driver.browser.logs.get(:browser).map(&:message).join("\n")) rescue nil
    File.write(dir.join("#{method_name}.test.log"), `tail -n 400 #{Rails.root.join("log/test.log")}`)
  end

  # Sign in through the real login form (the browser keeps its own cookie session).
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password",      with: password
    click_on I18n.t("auth.sign_in_submit")
    assert_selector "h1", text: I18n.t("people.title"), wait: 10
    # The browser (and its localStorage) outlives the test transaction; record ids
    # repeat across tests, so a persisted tree view from one test could leak into
    # the next. Start every test with a clean slate.
    page.execute_script("localStorage.clear()")
  end
end

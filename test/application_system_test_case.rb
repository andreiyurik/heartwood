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

    # Every page keeps a /cable WebSocket; pages parked in the back-forward cache keep
    # theirs too, and on a slow runner they can use up Chrome's connections to the test
    # server so the next fetch never leaves the browser.
    options.add_argument("--disable-features=BackForwardCache")
    options.add_argument("--disable-dev-shm-usage")
    options.add_option("goog:loggingPrefs", { browser: "ALL" })
  end

  # TEMPORARY CI diagnostics, taken before Capybara resets the session.
  def before_teardown
    dump_failure_state unless passed?
  ensure
    super
  end

  def dump_failure_state
    dir = Rails.root.join("tmp/screenshots"); FileUtils.mkdir_p(dir)
    state = page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      const s = window.Turbo && window.Turbo.session
      const out = {
        url: location.href, navType: performance.getEntriesByType("navigation")[0]?.type,
        turboStarted: s && s.started, drive: s && s.drive, bodyTurbo: document.body.dataset.turbo || null,
        preview: document.documentElement.hasAttribute("data-turbo-preview"),
        stimulus: window.Stimulus ? window.Stimulus.controllers.length : null,
        events: []
      }
      const names = ["turbo:click", "turbo:before-fetch-request", "turbo:frame-load", "turbo:before-visit", "turbo:submit-start", "click"]
      names.forEach(n => document.addEventListener(n, e => out.events.push(n + "@" + (e.target.id || e.target.tagName)), true))
      const link = document.querySelector("turbo-frame a")
      out.link = link ? link.getAttribute("href") : null
      if (link) link.click()
      setTimeout(() => {
        out.frames = [...document.querySelectorAll("turbo-frame")].map(f => f.id + ":" + (f.getAttribute("src") || "-") + ":" + (f.hasAttribute("busy") ? "busy" : "idle"))
        done(out)
      }, 1500)
    JS
    File.write(dir.join("#{method_name}.state.txt"), JSON.pretty_generate(state))
    File.write(dir.join("#{method_name}.console.txt"), page.driver.browser.logs.get(:browser).map { |l| "#{l.level} #{l.message}" }.join("\n"))
    File.write(dir.join("#{method_name}.test.log"), `tail -n 120 #{Rails.root.join("log/test.log")}`)
  rescue => e
    File.write(dir.join("#{method_name}.diag-error.txt"), "#{e.class}: #{e.message}")
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

  # A click dispatched by script instead of by pointer. Geometric clicks can miss inside
  # the tree's pan/zoom transform, and on the CI runner one is sometimes lost right after
  # a page loads; the page then shows no navigation at all (no request, no frame src).
  def js_click(element)
    page.execute_script("arguments[0].click()", element)
    sleep 0.4   # let the Stimulus relayout settle
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

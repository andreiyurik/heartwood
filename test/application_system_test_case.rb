require "test_helper"

# Base for browser-driven system tests (Capybara + headless Chrome). These exercise the
# JS-driven UX that server-rendering tests can't reach: the Stimulus tree canvas, the
# debounced combobox/search Turbo Frames, and the Lexxy rich-text editor mounting.
#
# NOTE: requires a Chrome/Chromium + chromedriver on the host. They are NOT part of the
# default `bin/rails test` run — execute with `bin/rails test:system`.
module TraceClicks
  def click(*args, **options)
    driver.browser.execute_script("window.__trace?.push('-- ruby click ' + arguments[0])", tag_name) rescue nil
    super.tap { driver.browser.execute_script("window.__trace?.push('-- ruby click returned')") rescue nil }
  end
end
Capybara::Selenium::Node.prepend(TraceClicks)

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
    # Capybara clicks where an element rests. With smooth scrolling and entrance animations
    # on, a slow runner scrolls the target away under the click and nothing happens.
    options.add_argument("--force-prefers-reduced-motion")
    # A fresh browser on CI starts at 800×600 and applies screen_size late; start at full size.
    options.add_argument("--window-size=1400,1400")
  end

  # Absorb Turbo navigation / Stimulus-connect latency under load (default is 2s).
  Capybara.default_max_wait_time = 5

  # Browsers get real broadcasts: the async adapter, switched on once for the whole run.
  def self.deliver_broadcasts!
    return if @delivering_broadcasts
    ActionCable.server.config.cable = { "adapter" => "async" }
    ActionCable.server.restart
    @delivering_broadcasts = true
  end

  setup { ApplicationSystemTestCase.deliver_broadcasts! }

  # Chrome on CI activates its window only after the first page has loaded, flipping focus on
  # and off, and drops any click or key sent before that settles. Once per browser, wait for it.
  setup do
    unless page.driver.browser.instance_variable_get(:@window_settled)
      visit new_session_path
      Timeout.timeout(10) do
        sleep 0.05 until 6.times.all? { sleep 0.05; page.evaluate_script("document.hasFocus()") }
      end
      page.driver.browser.instance_variable_set(:@window_settled, true)
    end
  end

  # TEMPORARY: record input and Turbo events on every page; print them when a test fails.
  TRACE = <<~JS
    window.__trace = [];
    const t0 = performance.now();
    const log = (m) => window.__trace.push(Math.round(performance.now() - t0) + "ms " + m);
    log("doc " + location.pathname + " " + innerWidth + "x" + innerHeight + " focus=" + document.hasFocus());
    ["pointermove","mouseover"].forEach(n => addEventListener(n, (e) => { if ((window.__moves = (window.__moves || 0) + 1) < 4) log(n + " " + e.clientX + "," + e.clientY) }, true));
    ["pointerdown","click","keydown","focus","blur"].forEach(n => addEventListener(n, (e) =>
      log(n + " " + (e.target?.closest?.("a,button,summary,input")?.outerHTML?.slice(0, 80) || e.target?.tagName || "window")), true));
    ["turbo:click","turbo:visit","turbo:load","turbo:before-fetch-request","turbo:fetch-request-error","turbo:frame-load",
     "turbo:before-stream-render","turbo:morph","turbo:render","turbo:frame-missing"].forEach(n => addEventListener(n, (e) =>
      log(n + " " + (e.target?.id || e.target?.tagName || "") + (e.detail?.url ? " " + e.detail.url : "") +
          (n === "turbo:before-stream-render" ? " " + e.target.getAttribute("action") : "")), true));
    addEventListener("error", (e) => log("error " + e.message));
    document.addEventListener("visibilitychange", () => log("visibility " + document.visibilityState));
  JS

  setup do
    unless page.driver.browser.instance_variable_get(:@__traced)
      page.driver.browser.execute_cdp("Page.addScriptToEvaluateOnNewDocument", source: TRACE)
      page.driver.browser.instance_variable_set(:@__traced, true)
    end
  end

  def before_teardown
    unless passed?
      puts "\n=== TRACE #{name} ===", (page.evaluate_script("window.__trace") || []).last(60).join("\n"),
        "now: #{page.evaluate_script("innerWidth + 'x' + innerHeight + ' focus=' + document.hasFocus() + ' active=' + document.activeElement?.outerHTML?.slice(0, 80)")}"
    end
  rescue => error
    puts "trace failed: #{error.message}"
  ensure
    super
  end

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

  # A click dispatched by script: geometric clicks can miss inside the tree's pan/zoom transform.
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

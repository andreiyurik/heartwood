require "application_system_test_case"

# TEMPORARY: records what the browser does when an inline form fails to open on CI.
class DiagnoseTest < ApplicationSystemTestCase
  TRACE = <<~JS
    (() => {
      if (window.__trace) return;
      window.__trace = [];
      const t0 = performance.now();
      const log = (msg) => window.__trace.push(Math.round(performance.now() - t0) + "ms " + msg);
      ["turbo:click","turbo:before-visit","turbo:visit","turbo:load","turbo:before-fetch-request","turbo:before-fetch-response",
       "turbo:fetch-request-error","turbo:frame-load","turbo:frame-render","turbo:frame-missing","turbo:before-frame-render",
       "turbo:before-stream-render","turbo:morph","turbo:before-morph-element","turbo:render","turbo:before-render","turbo:reload"]
        .forEach(name => document.addEventListener(name, (e) => {
          const target = e.target && (e.target.id || e.target.tagName);
          let extra = "";
          if (name === "turbo:before-fetch-request") extra = " " + e.detail.url;
          if (name === "turbo:before-stream-render") extra = " action=" + e.target.getAttribute("action");
          if (name === "turbo:before-morph-element" && e.target.id !== "add_event") return;
          log(name + " @" + target + extra);
        }, true));
      document.addEventListener("click", (e) => log("click " + (e.target.closest("a")?.getAttribute("href") || e.target.tagName) + " defaultPrevented=" + e.defaultPrevented), true);
      document.addEventListener("click", (e) => log("click(bubble) defaultPrevented=" + e.defaultPrevented), false);
      window.addEventListener("error", (e) => log("error " + e.message));
      window.addEventListener("unhandledrejection", (e) => log("rejection " + e.reason));
      const frame = document.getElementById("add_event");
      new MutationObserver((ms) => ms.forEach(m => log("mutation add_event " + m.type + " " + (m.attributeName || "") + " =" + frame.getAttribute(m.attributeName || "src"))))
        .observe(frame, { attributes: true });
      log("installed turbo=" + !!window.Turbo + " stimulus=" + !!window.Stimulus +
          " preserve=" + !!(window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(frame, "preserve-form")) +
          " cable=" + document.querySelector("turbo-cable-stream-source")?.hasAttribute("connected") +
          " paints=" + JSON.stringify(performance.getEntriesByType("paint").map(p => p.name + "@" + Math.round(p.startTime))) +
          " now=" + Math.round(performance.now()) + " visible=" + document.visibilityState + " focus=" + document.hasFocus());
    })()
  JS

  setup do
    @person = people(:johann_sebastian)
    sign_in_as users(:bach)
    puts "\nbrowser=#{page.driver.browser.capabilities.browser_version}"
  end

  20.times do |i|
    test "open the add-event form #{i}" do
      visit person_path(@person)
      page.execute_script(TRACE)
      click_on I18n.t("events.add")
      begin
        assert_field "event_date_raw"
        puts "\n--- PASS #{i} ---\n" + page.evaluate_script("window.__trace").join("\n") if i < 2
      rescue Minitest::Assertion, Capybara::ElementNotFound
        sleep 1
        puts "\n--- FAIL #{i} ---"
        puts page.evaluate_script("window.__trace").join("\n")
        puts "paints at fail: " + page.evaluate_script("JSON.stringify(performance.getEntriesByType('paint').map(p => p.name + '@' + Math.round(p.startTime)))")
        puts "frame html: " + page.evaluate_script("document.getElementById('add_event').outerHTML")[0, 400]
        puts "console: " + page.driver.browser.logs.get(:browser).map(&:message).join(" | ") rescue puts "no console logs"
        raise
      end
    end
  end
end

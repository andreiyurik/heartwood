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
      ["pointerdown","pointerup","mousedown","mouseup","pointermove"].forEach(n => window.addEventListener(n, (e) => {
        if (n === "pointermove" && window.__moves++ > 3) return;
        log(n + " at " + e.clientX + "," + e.clientY + " on " + (e.target.closest?.("a")?.getAttribute("href") || e.target.tagName + "." + e.target.className));
      }, true));
      window.__moves = 0;
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
    @fix = name[/\d+\z/].to_i.even? ? "emulation" : "bring_to_front"
    if @fix == "emulation"
      page.driver.browser.execute_cdp("Emulation.setFocusEmulationEnabled", enabled: true)
    else
      page.driver.browser.execute_cdp("Page.bringToFront")
    end
    @person = people(:johann_sebastian)
    sign_in_as users(:bach)
    puts "\nbrowser=#{page.driver.browser.capabilities.browser_version}"
  end

  teardown { page.driver.quit }

  10.times do |i|
    test "open the add-event form #{i}" do
      visit person_path(@person)
      before = page.evaluate_script("document.hasFocus()")
      puts "\n#{i} #{@fix} focus=#{before}"
      puts page.evaluate_script(<<~JS)
        (() => { const a = [...document.querySelectorAll("#add_event a")][0]; const r = a.getBoundingClientRect();
          const cx = r.left + r.width / 2, cy = r.top + r.height / 2; const hit = document.elementFromPoint(cx, cy);
          return "viewport=" + innerWidth + "x" + innerHeight + " dpr=" + devicePixelRatio + " scrollY=" + scrollY +
            " link=" + JSON.stringify(r) + " hit=" + (hit && (hit.closest("a") === a ? "LINK" : hit.tagName + "." + hit.className)); })()
      JS
      page.execute_script(TRACE)
      click_on I18n.t("events.add")
      begin
        assert_field "event_date_raw"
        puts "\n--- PASS #{i} ---\n" + page.evaluate_script("window.__trace").join("\n") if i < 2
      rescue Minitest::Assertion, Capybara::ElementNotFound
        sleep 1
        puts "\n--- FAIL #{i} ---"
        puts page.evaluate_script("window.__trace").join("\n")
        puts "scrollY at fail: " + page.evaluate_script("scrollY").to_s
        puts "paints at fail: " + page.evaluate_script("JSON.stringify(performance.getEntriesByType('paint').map(p => p.name + '@' + Math.round(p.startTime)))")
        puts "frame html: " + page.evaluate_script("document.getElementById('add_event').outerHTML")[0, 400]
        puts "console: " + page.driver.browser.logs.get(:browser).map(&:message).join(" | ") rescue puts "no console logs"
        raise
      end
    end
  end
end

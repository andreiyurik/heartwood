require "application_system_test_case"

# TEMPORARY: fresh browser per test, probe whether a click reaches the page.
class DiagnosePagesTest < ApplicationSystemTestCase
  teardown { page.driver.quit }

  PROBE = "window.__got = []; ['pointerdown','click'].forEach(n => addEventListener(n, () => __got.push(n), true))"

  setup { sign_in_as users(:bach) }

  def probe(css)
    page.execute_script(PROBE)
    find(css, match: :first).click
    sleep 0.3
    got = page.evaluate_script("window.__got") rescue [ "navigated" ]
    status = got.blank? ? "LOST" : got.join(",")
    if got.blank?
      t0 = Time.now
      page.execute_script("addEventListener('keydown', () => __got.push('key'), true)")
      find("body").send_keys("x")
      key = page.evaluate_script("window.__got").include?("key")
      revived = nil
      10.times do
        sleep 0.5
        find(css, match: :first).click
        if page.evaluate_script("window.__got").include?("click")
          revived = (Time.now - t0).round(1)
          break
        end
      end
      status += " key=#{key} revived_after=#{revived.inspect}"
    end
    puts "\n#{name} #{current_path} #{css}: #{status}"
  end

  6.times do |i|
    test "people list #{i}" do
      visit people_path
      probe "h1"
    end

    test "person without map #{i}" do
      plain = trees(:bach).people.create!(given_names: "Plain")
      visit person_path(plain)
      probe "h1"
    end

    test "person with map #{i}" do
      visit person_path(people(:johann_sebastian))
      probe "h1"
    end

    test "map page #{i}" do
      visit map_path
      probe "h1, header"
    end
  end
end

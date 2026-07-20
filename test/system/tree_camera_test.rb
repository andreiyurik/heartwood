require "application_system_test_case"

# Camera behavior of the tree canvas — fit-to-view on load and cursor-anchored wheel
# zoom — lives entirely in tree_controller.js; a real browser is the only way to
# prove it. Events are dispatched via JS for determinism (see TreeNavigationTest).
class TreeCameraTest < ApplicationSystemTestCase
  setup do
    @tree = trees(:alpha)

    # A single-file chain of 8 generations: tall enough that at scale 1 the tree
    # cannot fit the 70vh canvas, so the initial camera must zoom out.
    @chain = []
    parent = nil
    8.times do |i|
      person = Person.create!(given_names: "Gen#{i}", surname: "Chain", sex: "M", tree: @tree)
      Event.create!(kind: "DEAT", eventable: person, tree: @tree)
      if parent
        fam = Family.create!(tree: @tree)
        fam.partners << parent
        fam.children << person
      end
      @chain << person
      parent = person
    end

    sign_in_as users(:one)
  end

  test "initial camera fits a tall tree inside the canvas" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 6)
    assert_selector ".tree-edges path", wait: 5

    fits = page.evaluate_script(<<~JS)
      (() => {
        const canvas = document.querySelector(".tree-canvas").getBoundingClientRect()
        const inner  = document.querySelector(".tree-inner").getBoundingClientRect()
        return inner.top  >= canvas.top  - 1 && inner.bottom <= canvas.bottom + 1 &&
               inner.left >= canvas.left - 1 && inner.right  <= canvas.right  + 1
      })()
    JS
    assert fits, "the whole tree should be visible inside the canvas on load"
  end

  test "wheel zoom keeps the point under the cursor fixed" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 2)
    assert_selector ".tree-edges path", wait: 5

    drift = page.evaluate_script(<<~JS)
      (() => {
        const canvas = document.querySelector(".tree-canvas")
        const node   = document.querySelector(".tree-node--focus")
        const before = node.getBoundingClientRect()
        const cx = before.left + before.width / 2, cy = before.top + before.height / 2
        canvas.dispatchEvent(new WheelEvent("wheel",
          { clientX: cx, clientY: cy, deltaY: -100, bubbles: true, cancelable: true }))
        const after = node.getBoundingClientRect()
        const ax = after.left + after.width / 2, ay = after.top + after.height / 2
        return Math.hypot(ax - cx, ay - cy)
      })()
    JS
    assert_operator drift, :<, 2, "the point under the cursor should not move while zooming"
  end
end

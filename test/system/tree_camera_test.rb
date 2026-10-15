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

  test "a tall tree opens readable, with the focus card at the top edge, and Fit shows it whole" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 6)
    assert_selector ".tree-edges path", wait: 5

    opened = page.evaluate_script(<<~JS)
      (() => {
        const canvas = document.querySelector(".tree-canvas").getBoundingClientRect()
        const focus  = document.querySelector(".tree-node--focus").getBoundingClientRect()
        const scale  = new DOMMatrix(getComputedStyle(document.querySelector(".tree-inner")).transform).a
        return { scale, top: focus.top - canvas.top, centred: Math.abs((focus.left + focus.right) / 2 - (canvas.left + canvas.right) / 2) }
      })()
    JS
    assert_in_delta 0.85, opened["scale"], 0.01, "a tree that cannot fit opens at the readable floor"
    assert_in_delta 48, opened["top"], 2, "the focus card sits at the top padding"
    assert opened["centred"] < 2, "the focus card is centred horizontally"

    find(".tree-zoom button[data-action='tree#zoomFit']").click
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

  test "a big tree loads with far branches auto-folded" do
    # Binary descendancy, 6 generations → 63 people, over the auto-collapse bar.
    root  = Person.create!(given_names: "Big Root", sex: "M", tree: @tree)
    level = [ root ]
    5.times do |g|
      level = level.flat_map do |parent|
        fam = Family.create!(tree: @tree)
        fam.partners << parent
        Array.new(2) do |i|
          Person.create!(given_names: "G#{g}", sex: "M", tree: @tree).tap { |c| fam.children << c }
        end
      end
    end

    visit person_tree_path(root, mode: "descendants", depth: 6)
    assert_selector ".tree-edges path", wait: 5
    assert_selector ".tree-toggle--collapsed", minimum: 1
    # Far generations are folded away, so far fewer than 63 nodes are shown.
    shown = page.evaluate_script(
      "document.querySelectorAll('.tree-node:not([style*=\"display: none\"])').length")
    assert_operator shown, :<, 40, "far branches should load folded"
  end

  test "zoom buttons change the scale around the canvas centre" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 2)
    assert_selector ".tree-edges path", wait: 5

    scale = -> { page.evaluate_script(
      "new DOMMatrix(getComputedStyle(document.querySelector('.tree-inner')).transform).a") }
    before = scale.call
    find(".tree-zoom button[data-action='tree#zoomIn']").click
    assert_in_delta before * 1.2, scale.call, 0.01

    find(".tree-zoom button[data-action='tree#zoomFit']").click
    assert_in_delta before, scale.call, 0.05   # fit returns to the fitted scale
  end

  test "two-pointer pinch zooms the tree" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 2)
    assert_selector ".tree-edges path", wait: 5

    # Fingers land on empty canvas (bottom-left), spread 100 → 200 px apart.
    grew = page.evaluate_script(<<~JS)
      (() => {
        const canvas = document.querySelector(".tree-canvas")
        const rect   = canvas.getBoundingClientRect()
        const before = new DOMMatrix(getComputedStyle(document.querySelector(".tree-inner")).transform).a
        const ev = (type, id, x, y) => new PointerEvent(type,
          { pointerId: id, clientX: rect.left + x, clientY: rect.bottom - y, bubbles: true })
        canvas.dispatchEvent(ev("pointerdown", 1, 20, 20))
        canvas.dispatchEvent(ev("pointerdown", 2, 120, 20))
        window.dispatchEvent(ev("pointermove", 2, 220, 20))
        window.dispatchEvent(ev("pointerup", 1, 20, 20))
        window.dispatchEvent(ev("pointerup", 2, 220, 20))
        const after = new DOMMatrix(getComputedStyle(document.querySelector(".tree-inner")).transform).a
        return { before, after }
      })()
    JS
    assert_in_delta grew["before"] * 2, grew["after"], 0.05,
      "doubling the finger distance should double the scale"
  end

  test "mini map appears once the tree overflows and a click jumps the camera" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 2)
    assert_selector ".tree-edges path", wait: 5
    assert_no_selector ".tree-minimap"   # a short tree fits → no map

    3.times { find(".tree-zoom button[data-action='tree#zoomIn']").click }
    assert_selector ".tree-minimap", wait: 3

    moved = page.evaluate_script(<<~JS)
      (() => {
        const inner  = document.querySelector(".tree-inner")
        const before = getComputedStyle(inner).transform
        const mm     = document.querySelector(".tree-minimap")
        const rect   = mm.getBoundingClientRect()
        mm.dispatchEvent(new PointerEvent("pointerdown",
          { clientX: rect.left + 4, clientY: rect.top + 4, bubbles: true }))
        return getComputedStyle(inner).transform !== before
      })()
    JS
    assert moved, "clicking the mini map should move the camera"
  end

  test "print scales the tree to page width and restores the camera after" do
    visit person_tree_path(@chain.first, mode: "descendants", depth: 3)
    assert_selector ".tree-edges path", wait: 5

    result = page.evaluate_script(<<~JS)
      (() => {
        window.print = () => {}   // headless: no dialog, just the setup around it
        const inner  = document.querySelector(".tree-inner")
        const before = getComputedStyle(inner).transform
        document.querySelector("[data-controller=print]").click()
        const during = {
          printing: document.querySelector(".tree-canvas--print") !== null,
          origin:   new DOMMatrix(getComputedStyle(inner).transform).e === 0
        }
        window.dispatchEvent(new Event("afterprint"))
        return { ...during, restored: getComputedStyle(inner).transform === before }
      })()
    JS
    assert result["printing"], "print mode class should be set"
    assert result["origin"],   "tree should be moved to the page origin for print"
    assert result["restored"], "camera should be restored after printing"
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

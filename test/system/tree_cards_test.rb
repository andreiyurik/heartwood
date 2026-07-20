require "application_system_test_case"

# Card legibility: a long name (Russian имя + отчество is the common case) must not be
# cut off with an ellipsis. Only a real browser knows how text actually lays out, so the
# assertion measures overflow rather than trusting the markup.
class TreeCardsTest < ApplicationSystemTestCase
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Александр Александрович",
                             surname: "Пушкин", sex: "M", tree: @tree)
    Event.create!(kind: "DEAT", eventable: @person, tree: @tree)
    sign_in_as users(:one)
  end

  test "a long given name wraps instead of being clipped" do
    visit person_tree_path(@person)
    assert_selector ".tree-node--focus"

    clipped = page.evaluate_script(<<~JS)
      (() => {
        const lines = document.querySelectorAll(".tree-node--focus .node-name, .tree-node--focus .node-surname")
        return Array.from(lines)
          .filter(el => el.scrollWidth > el.clientWidth + 1)
          .map(el => el.textContent.trim())
      })()
    JS
    assert_empty clipped, "no name line should overflow its card"
  end

  test "the whole name stays inside the card box" do
    visit person_tree_path(@person)
    assert_selector ".tree-node--focus"

    fits = page.evaluate_script(<<~JS)
      (() => {
        const card = document.querySelector(".tree-node--focus")
        const text = card.querySelector(".node-text")
        return text.getBoundingClientRect().bottom <= card.getBoundingClientRect().bottom + 1
      })()
    JS
    assert fits, "the name block should not spill out of the card"
  end
end

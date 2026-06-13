require "application_system_test_case"

# The Lexxy rich-text editor (Action Text, ADR 0008) emits a <lexxy-editor> custom element
# that upgrades via JS into a contenteditable surface. Server rendering only proves the tag
# is present; this proves the editor actually MOUNTS in a browser and SAVES its content.
class BiographyEditorTest < ApplicationSystemTestCase
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Bio", surname: "Graph", sex: "U", tree: @tree)
    sign_in_as users(:one)
  end

  test "the Lexxy editor mounts and saves a biography" do
    visit edit_person_path(@person)

    # The custom element upgrades into an editable surface only when the JS mounts.
    editor = find("lexxy-editor [contenteditable='true']", wait: 10)
    editor.click  # focus the editable surface before typing, or the keys go nowhere
    editor.send_keys("A short, quiet life by the sea.")
    # Let the editor flush its content into the hidden Action Text input before submitting.
    assert_selector "lexxy-editor [contenteditable='true']", text: "quiet life", wait: 5

    find("input[type=submit]").click

    assert_current_path person_path(@person), wait: 10
    assert_selector ".biography", text: "A short, quiet life by the sea.", wait: 10
    assert @person.reload.biography.to_plain_text.include?("quiet life")
  end
end

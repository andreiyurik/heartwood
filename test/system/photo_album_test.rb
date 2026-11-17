require "application_system_test_case"

class PhotoAlbumTest < ApplicationSystemTestCase
  test "a relative adds a photo, captions it and opens it full size" do
    person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    sign_in_as users(:one)
    visit person_path(person)

    attach_file "photos[]", file_fixture("avatar.png"), make_visible: true
    assert_selector "#memories .photo"

    within("#memories") { click_on I18n.t("photos.sign") }
    fill_in I18n.t("photos.caption_placeholder"), with: "At the piano"
    click_on I18n.t("forms.save")
    assert_selector "#memories figcaption", text: "At the piano"

    find("#memories .photo__print").click
    assert_selector "dialog.lightbox[open] figcaption", text: "At the piano"

    find("dialog.lightbox .lightbox__btn").click
    assert_no_selector "dialog.lightbox[open]"
  end
end

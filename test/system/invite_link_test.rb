require "application_system_test_case"

class InviteLinkTest < ApplicationSystemTestCase
  test "the owner copies the invite link" do
    sign_in_as users(:one)
    visit tree_memberships_path

    click_on I18n.t("tree_memberships.copy_link")

    assert_selector "button.btn--success[data-controller=copy-to-clipboard]"
  end
end

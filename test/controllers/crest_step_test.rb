require "test_helper"

class CrestStepTest < ActionDispatch::IntegrationTest
  test "a new tree's owner is offered a crest right after signing up, and may skip it" do
    post registration_path, params: { tree_name: "Lovelace family", user: {
      name: "Ada Lovelace", email_address: "ada@example.com", password: "secret123", privacy_consent: "1" } }
    assert_redirected_to settings_crest_path

    follow_redirect!
    assert_select "h1", text: /Lovelace family/
    assert_select "form.crest-form input[type=hidden][name=step][value=crest]"
    assert_select "a.btn--primary[href=?]", root_path
    assert_select "a[href=?]", root_path, minimum: 2

    patch settings_url, params: { step: "crest", tree: { crest_shape: "round" } }
    assert_redirected_to settings_crest_path
  end

  test "joining someone else's tree goes straight in" do
    post join_url(trees(:alpha).join_code), params: { user: {
      name: "Cousin", email_address: "cousin@example.com", password: "secret123", privacy_consent: "1" } }
    assert_redirected_to root_path
  end
end

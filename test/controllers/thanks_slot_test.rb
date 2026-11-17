require "test_helper"

class ThanksSlotTest < ActionDispatch::IntegrationTest
  setup do
    Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: trees(:alpha))
    sign_in_as users(:one)
  end

  test "a self-hosted install never asks anyone for anything" do
    get people_url
    assert_select ".cloud-thanks", count: 0
    assert_no_match "cloudtips", response.body
  end

  test "the hosted engine may say thanks in the account menu, under the list and after an import" do
    with_cloud_slots do
      get people_url
      assert_select ".account-menu .cloud-thanks[data-place=menu]"
      assert_select "main .cloud-thanks[data-place=milestone]"

      import = Import.new(tree: trees(:alpha), user: users(:one), status: "completed", people_count: 3, families_count: 1)
      import.file.attach(io: StringIO.new("0 HEAD"), filename: "tree.ged")
      import.save!
      get import_url(id: import.id)
      assert_select ".import-report .cloud-thanks[data-place=import]"
    end
  end
end

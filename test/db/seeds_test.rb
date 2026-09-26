require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds never write to the test database" do
    assert_no_difference -> { User.count + Tree.count + Person.count } do
      load Rails.root.join("db/seeds.rb")
    end
  end
end

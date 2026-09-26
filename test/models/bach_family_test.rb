require "test_helper"

class BachFamilyTest < ActiveSupport::TestCase
  test "the fixture family hangs together" do
    sebastian = people(:johann_sebastian)

    assert_equal [ people(:ambrosius), people(:elisabeth) ].sort_by(&:id), sebastian.parents.sort_by(&:id)
    assert_equal [ people(:maria_barbara), people(:anna_magdalena) ].sort_by(&:id), sebastian.partners.sort_by(&:id)
    assert_equal 3, sebastian.children.count
    assert_equal "1685", sebastian.life_years.split(" – ").first
    assert_equal places(:eisenach), sebastian.birth.place
    assert_equal sources(:eisenach_baptisms), sebastian.birth.citations.sole.source
    assert_equal [ people(:carl_philipp_emanuel) ], people(:wilhelm_friedemann).siblings.to_a
  end
end

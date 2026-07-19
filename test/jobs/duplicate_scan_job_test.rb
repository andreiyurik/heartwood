require "test_helper"

class DuplicateScanJobTest < ActiveSupport::TestCase
  setup { Current.tree = trees(:alpha) }
  teardown { Current.reset }

  def duplicate_pair
    Person.create!(given_names: "John", surname: "Smith", sex: "M", tree: Current.tree)
    Person.create!(given_names: "John", surname: "Smith", sex: "M", tree: Current.tree)
  end

  test "creates pending hints for duplicates" do
    duplicate_pair
    assert_difference -> { Current.tree.duplicate_hints.pending.count }, 1 do
      DuplicateScanJob.perform_now(Current.tree)
    end
  end

  test "rescanning rebuilds rather than duplicates pending hints" do
    duplicate_pair
    DuplicateScanJob.perform_now(Current.tree)
    DuplicateScanJob.perform_now(Current.tree)
    assert_equal 1, Current.tree.duplicate_hints.pending.count
  end

  test "a dismissed pair does not resurface on rescan" do
    duplicate_pair
    DuplicateScanJob.perform_now(Current.tree)
    Current.tree.duplicate_hints.first.dismissed!

    DuplicateScanJob.perform_now(Current.tree)
    assert_equal 0, Current.tree.duplicate_hints.pending.count
    assert_equal 1, Current.tree.duplicate_hints.dismissed.count
  end
end

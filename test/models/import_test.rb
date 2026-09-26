require "test_helper"

class ImportTest < ActiveSupport::TestCase
  setup do
    @tree = trees(:alpha)
  end

  def import_from(fixture)
    Import.new(tree: @tree, user: users(:one)).tap do |import|
      import.file.attach(io: file_fixture("../gedcom/#{fixture}").open, filename: fixture)
      import.save!
    end
  end

  test "process reads the file into the tree and reports what it found" do
    import = import_from("minimal_551.ged")

    assert_difference -> { @tree.people.count }, 2 do
      import.process
    end

    assert import.completed?
    assert_equal 2, import.people_count
    assert_equal 1, import.families_count
  end

  test "a file with no people fails without touching the tree" do
    import = Import.new(tree: @tree, user: users(:one))
    import.file.attach(io: StringIO.new("this is not gedcom"), filename: "notes.ged")
    import.save!

    assert_no_difference -> { @tree.people.count } do
      import.process
    end
    assert import.failed?
    assert_equal "no_records", import.error
  end

  test "a tree over its plan limit fails and imports nothing" do
    @tree.define_singleton_method(:people_limit) { 1 }
    import = import_from("minimal_551.ged")

    assert_no_difference -> { Person.count } do
      import.process
    end
    assert import.failed?
    assert_equal "tree_full", import.error
  end

  test "requires a file with a .ged name" do
    import = Import.new(tree: @tree, user: users(:one))
    assert_not import.valid?

    import.file.attach(io: StringIO.new("x"), filename: "photo.png")
    assert_not import.valid?
  end
end

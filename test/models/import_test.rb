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

  test "an archive's photo marked _PRIM Y becomes the person's photo; others and unsafe files stay as references" do
    import = import_zip(
      "gedcom.ged" => <<~GED,
        0 @I1@ INDI
        1 NAME Anna /Bach/
        1 OBJE @O1@
        2 _PRIM N
        1 OBJE @O2@
        2 _PRIM Y
        1 OBJE
        2 FILE ../../etc/passwd
        0 @O1@ OBJE
        1 FILE media/letter.png
        0 @O2@ OBJE
        1 FILE media\\portrait.png
      GED
      "media/letter.png"   => "letter".b,
      "media/portrait.png" => "\x89PNG portrait".b)

    import.process

    assert import.completed?, import.error
    anna = @tree.people.find_by!(given_names: "Anna")
    assert_equal "\x89PNG portrait".b, anna.avatar.download
    assert_equal [ "media/letter.png", "../../etc/passwd" ],
      anna.gedcom_raw.select { it["tag"] == "OBJE" }.map { it["children"].find { it["tag"] == "FILE" }["value"] }
  end

  test "an archive without a GEDCOM inside fails cleanly" do
    import = import_zip("readme.txt" => "hello")

    import.process

    assert import.failed?
    assert_equal "no_records", import.error
  end

  private
    def import_zip(entries)
      buffer = Zip::OutputStream.write_buffer do |zip|
        entries.each { |name, content| zip.put_next_entry(name); zip.write(content) }
      end

      Import.new(tree: @tree, user: users(:one)).tap do |import|
        import.file.attach(io: StringIO.new(buffer.string), filename: "tree.zip")
        import.save!
      end
    end
end

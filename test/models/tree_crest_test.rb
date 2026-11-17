require "test_helper"

class TreeCrestTest < ActiveSupport::TestCase
  setup { @tree = trees(:alpha) }

  test "by default the crest is a shield in the tree's own colour with the family's initial" do
    assert_equal "shield", @tree.crest_shape_name
    assert_includes 0..359, @tree.crest_hue_value
    assert_nil @tree.crest_symbol
    assert_equal "A", @tree.crest_letter
    assert_equal "П", Tree.new(name: "Род Пушкиных").crest_letter
    assert_equal "И", Tree.new(name: "семья Ивановых").crest_letter
  end

  test "the owner's choice wins over the defaults" do
    @tree.update!(crest_shape: "round", crest_hue: 260, crest_symbol: "anchor")

    assert_equal "round", @tree.crest_shape_name
    assert_equal 260, @tree.crest_hue_value
    assert_equal Tree::Crest::SYMBOLS.fetch("anchor"), @tree.crest_symbol_svg
  end

  test "only the offered parts are accepted" do
    assert_not @tree.update(crest_shape: "pentagram")
    assert_not @tree.update(crest_symbol: "<script>")
    assert_not @tree.update(crest_hue: 400)
    assert @tree.update(crest_shape: "", crest_symbol: "", crest_hue: "")
    assert_nil @tree.crest_symbol
  end

  test "an uploaded crest must be a PNG or JPEG of a sane size" do
    @tree.crest_image.attach(io: StringIO.new("0 HEAD"), filename: "tree.ged", content_type: "text/plain")
    assert_not @tree.valid?
    assert @tree.errors.added?(:crest_image, :invalid_content_type)

    @tree.crest_image.attach(io: file_fixture("avatar.png").open, filename: "crest.png", content_type: "image/png")
    assert @tree.valid?
  end

  test "the link preview card is a PNG that follows the crest" do
    plain = Tree::Card.new(@tree).png
    assert plain.start_with?("\x89PNG".b)

    @tree.update!(crest_symbol: "star", crest_hue: 35)
    assert_not_equal plain, Tree::Card.new(@tree).png
  end

  test "the card survives a name full of markup" do
    @tree.update!(name: %(<Род> & "Пушкиных" </text>))
    assert Tree::Card.new(@tree).png.start_with?("\x89PNG".b)
  end

  test "the card can carry an uploaded crest" do
    @tree.crest_image.attach(io: file_fixture("avatar.png").open, filename: "crest.png", content_type: "image/png")
    @tree.save!
    assert Tree::Card.new(@tree).png.start_with?("\x89PNG".b)
  end
end

require "test_helper"

class PersonAvatarTest < ActiveSupport::TestCase
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(sex: "U", tree: @tree)
  end

  test "avatar is not attached by default" do
    assert_not @person.avatar.attached?
  end

  test "valid image attachment is accepted" do
    png = StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100)
    @person.avatar.attach(io: png, filename: "test.png", content_type: "image/png")
    @person.validate
    assert_not @person.errors[:avatar].any?
  end

  test "invalid content type is rejected" do
    txt = StringIO.new("not an image")
    @person.avatar.attach(io: txt, filename: "test.txt", content_type: "text/plain")
    @person.validate
    assert @person.errors[:avatar].any?
  end

  test "file over 5 MB is rejected" do
    big = StringIO.new("x" * (5.megabytes + 1))
    @person.avatar.attach(io: big, filename: "big.png", content_type: "image/png")
    @person.validate
    assert @person.errors[:avatar].any?
  end
end

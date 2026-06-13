require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a name" do
    user = User.new(email_address: "x@example.com", password: "secret123")
    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test "requires a unique, well-formed email address" do
    User.create!(name: "First", email_address: "taken@example.com", password: "secret123")

    dup = User.new(name: "Second", email_address: "taken@example.com", password: "secret123")
    assert_not dup.valid?, "duplicate email should be rejected"

    malformed = User.new(name: "Third", email_address: "not-an-email", password: "secret123")
    assert_not malformed.valid?, "malformed email should be rejected"
  end

  test "requires a password of at least 8 characters when one is set" do
    user = User.new(name: "Short", email_address: "short@example.com", password: "abc123")
    assert_not user.valid?
    assert user.errors[:password].any?
  end
end

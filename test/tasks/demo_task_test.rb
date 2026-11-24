require "test_helper"
require "rake"

class DemoTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("demo:rurikids")
    Rake::Task["demo:rurikids"].reenable
  end

  test "builds the example under its own account and prints the address for DEMO_URL" do
    output = with_env("OWNER" => "demo@example.com") { capture_io { Rake::Task["demo:rurikids"].invoke }.first }

    tree = User.find_by!(email_address: "demo@example.com").trees.sole
    assert_equal Rurikids::NAME, tree.name
    assert_match "DEMO_URL=/shared/#{tree.share_link.token}", output
  end

  private
    def with_env(vars)
      original = vars.keys.index_with { ENV[it] }
      vars.each { ENV[_1] = _2 }
      yield
    ensure
      original.each { ENV[_1] = _2 }
    end
end

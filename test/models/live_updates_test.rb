require "test_helper"
require "turbo/broadcastable/test_helper"

class LiveUpdatesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup { @tree = trees(:bach) }

  def assert_refresh_broadcast(tree = @tree, &block)
    streams = capture_turbo_stream_broadcasts(tree, &block)
    assert_operator streams.size, :>=, 1, "expected a refresh broadcast to the tree"
    assert_equal "refresh", streams.first["action"]
  end

  test "adding, changing and removing a person refreshes the tree's pages" do
    person = nil
    assert_refresh_broadcast { perform_enqueued_jobs { person = Person.create!(given_names: "Anna", sex: "F", tree: @tree) } }
    assert_refresh_broadcast { perform_enqueued_jobs { person.update!(nickname: "Anni") } }
    assert_refresh_broadcast { perform_enqueued_jobs { person.destroy! } }
  end

  test "events, citations and family links refresh the tree's pages" do
    event = events(:sebastian_death)
    assert_refresh_broadcast { perform_enqueued_jobs { event.update!(date_raw: "1750") } }
    assert_refresh_broadcast { perform_enqueued_jobs { event.cite({ title: "Register" }) } }
    assert_refresh_broadcast do
      perform_enqueued_jobs { families(:second_marriage).children << people(:wilhelm_friedemann) }
    end
  end

  test "other trees hear nothing" do
    streams = capture_turbo_stream_broadcasts(trees(:beta)) do
      perform_enqueued_jobs { people(:johann_sebastian).update!(nickname: "Thomaskantor") }
    end
    assert_empty streams
  end

  test "an import refreshes once at the end, not once per record" do
    import = Import.new(tree: trees(:alpha), user: users(:one))
    import.file.attach(io: file_fixture("../gedcom/minimal_551.ged").open, filename: "tree.ged")
    import.save!

    streams = capture_turbo_stream_broadcasts(trees(:alpha)) { perform_enqueued_jobs { import.process } }
    assert_equal 1, streams.size
  end
end

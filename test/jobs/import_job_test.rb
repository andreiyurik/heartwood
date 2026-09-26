require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  test "processes the import" do
    import = Import.new(tree: trees(:alpha), user: users(:one))
    import.file.attach(io: file_fixture("../gedcom/minimal_551.ged").open, filename: "tree.ged")
    import.save!

    perform_enqueued_jobs(only: ImportJob) { ImportJob.perform_later(import) }

    assert import.reload.completed?
  end
end

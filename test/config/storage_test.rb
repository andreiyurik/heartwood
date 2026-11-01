require "test_helper"

class StorageTest < ActiveSupport::TestCase
  test "object storage sends checksums only when an S3-compatible provider requires them" do
    config = Rails.configuration.active_storage.service_configurations.fetch("object_storage")

    assert_equal "when_required", config["request_checksum_calculation"]
    assert_equal "when_required", config["response_checksum_validation"]
  end
end

module CloudSlotsTestHelper
  def with_cloud_slots
    original = ApplicationController.view_paths
    ApplicationController.prepend_view_path Rails.root.join("test/fixtures/files/cloud_views")
    yield
  ensure
    ApplicationController.view_paths = original
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include CloudSlotsTestHelper
end

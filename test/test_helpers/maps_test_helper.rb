module MapsTestHelper
  def with_maps(**settings)
    maps = Rails.configuration.x.maps
    original = maps.slice(*settings.keys)
    maps.merge!(settings)
    yield
  ensure
    maps.merge!(original)
  end
end

ActiveSupport.on_load(:active_support_test_case) { include MapsTestHelper }

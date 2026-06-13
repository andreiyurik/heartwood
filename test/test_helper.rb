ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # I18n.locale is global and persists across requests; a test that switches locale
    # (e.g. LocalesControllerTest) would otherwise leak it into the next test in the same
    # parallel worker, breaking locale-sensitive assertions. Reset it after every test.
    teardown { I18n.locale = I18n.default_locale }

    # Add more helper methods to be used by all tests here...
  end
end

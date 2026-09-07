ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def with_stub(object, method_name, return_value)
      singleton = object.singleton_class
      original_method = object.method(method_name) rescue nil
      singleton.send(:define_method, method_name) { |*args, **kwargs| return_value }
      yield
    ensure
      if original_method
        singleton.send(:define_method, method_name, original_method)
      else
        singleton.send(:remove_method, method_name) rescue nil
      end
    end
  end
end

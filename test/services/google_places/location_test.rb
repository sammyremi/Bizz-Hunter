# test/services/google_places/location_test.rb

# frozen_string_literal: true

require 'test_helper'

module GooglePlaces
  class LocationTest < ActiveSupport::TestCase
    test "LocationAutocomplete validates short or blank input" do
      results = LocationAutocomplete.call(input: '')
      assert_equal [], results

      short_results = LocationAutocomplete.call(input: 'a')
      assert_equal [], short_results
    end

    test "LocationDetails validates blank place_id" do
      result = LocationDetails.call(place_id: '')
      assert_nil result
    end
  end
end

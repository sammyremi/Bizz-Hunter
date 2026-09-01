# test/services/search_quota_tracker_test.rb

# frozen_string_literal: true

require 'test_helper'

class SearchQuotaTrackerTest < ActiveSupport::TestCase
  setup do
    @orig_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @orig_cache
  end

  test "returns correct guest quota status" do
    status = SearchQuotaTracker.status(user: nil, ip: '192.168.1.1')
    assert_equal 'guest', status[:user_type]
    assert_equal 0, status[:used]
    assert_equal 5, status[:limit]
    assert_equal 5, status[:remaining]
  end

  test "increments guest quota and blocks when limit reached" do
    ip = '192.168.1.100'
    5.times do |i|
      res = SearchQuotaTracker.check_and_increment!(user: nil, ip: ip)
      assert res[:allowed], "Search #{i + 1} should be allowed"
      assert_equal i + 1, res[:quota][:used]
    end

    blocked_res = SearchQuotaTracker.check_and_increment!(user: nil, ip: ip)
    assert_not blocked_res[:allowed]
    assert_includes blocked_res[:message], 'Daily search limit reached'
  end

  test "returns higher limit for authenticated users" do
    user = User.create!(name: 'Quota User', email: 'quota@example.com', password: 'password123')
    status = SearchQuotaTracker.status(user: user, ip: '127.0.0.1')

    assert_equal 'authenticated', status[:user_type]
    assert_equal 50, status[:limit]
    assert_equal 50, status[:remaining]
  end
end

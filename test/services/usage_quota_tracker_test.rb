# test/services/usage_quota_tracker_test.rb

# frozen_string_literal: true

require 'test_helper'

class UsageQuotaTrackerTest < ActiveSupport::TestCase
  setup do
    @orig_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @user = User.create!(name: 'Quota User', email: "quota_#{SecureRandom.hex(4)}@example.com", password: 'password123')
    @ip = '192.168.1.50'
  end

  teardown do
    Rails.cache = @orig_cache
  end

  test "guest search quota enforces 2 searches per day" do
    status = UsageQuotaTracker.status(user: nil, ip: @ip)
    assert_equal 'guest', status[:user_type]
    assert_equal 2, status[:searches][:limit]
    assert_equal 2, status[:searches][:remaining]

    # Search 1
    res1 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :searches)
    assert res1[:allowed]
    UsageQuotaTracker.increment_feature!(user: nil, ip: @ip, feature: :searches)

    # Search 2
    res2 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :searches)
    assert res2[:allowed]
    UsageQuotaTracker.increment_feature!(user: nil, ip: @ip, feature: :searches)

    # Search 3 - Blocked
    res3 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :searches)
    refute res3[:allowed]
    assert_equal "Free preview limit reached. Create a free account to continue.", res3[:message]
  end

  test "guest prospect brief quota enforces 1 brief per day" do
    res1 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :prospect_briefs)
    assert res1[:allowed]
    UsageQuotaTracker.increment_feature!(user: nil, ip: @ip, feature: :prospect_briefs)

    res2 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :prospect_briefs)
    refute res2[:allowed]
    assert_equal "Free preview limit reached. Create a free account to continue.", res2[:message]
  end

  test "guest whatsapp message quota enforces 1 message per day" do
    res1 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :whatsapp_messages)
    assert res1[:allowed]
    UsageQuotaTracker.increment_feature!(user: nil, ip: @ip, feature: :whatsapp_messages)

    res2 = UsageQuotaTracker.check_feature(user: nil, ip: @ip, feature: :whatsapp_messages)
    refute res2[:allowed]
    assert_equal "Free preview limit reached. Create a free account to continue.", res2[:message]
  end

  test "registered free user has 20 searches per day" do
    status = UsageQuotaTracker.status(user: @user, ip: @ip)
    assert_equal 'authenticated', status[:user_type]
    assert_equal 20, status[:searches][:limit]

    20.times do
      assert UsageQuotaTracker.check_feature(user: @user, ip: @ip, feature: :searches)[:allowed]
      UsageQuotaTracker.increment_feature!(user: @user, ip: @ip, feature: :searches)
    end

    blocked = UsageQuotaTracker.check_feature(user: @user, ip: @ip, feature: :searches)
    refute blocked[:allowed]
    assert_includes blocked[:message], 'Daily search limit reached (20/20 searches used)'
  end

  test "registered free user has 10 AI prospect briefs per month" do
    status = UsageQuotaTracker.status(user: @user, ip: @ip)
    assert_equal 10, status[:prospect_briefs][:limit]

    10.times do
      assert UsageQuotaTracker.check_feature(user: @user, ip: @ip, feature: :prospect_briefs)[:allowed]
      UsageQuotaTracker.increment_feature!(user: @user, ip: @ip, feature: :prospect_briefs)
    end

    blocked = UsageQuotaTracker.check_feature(user: @user, ip: @ip, feature: :prospect_briefs)
    refute blocked[:allowed]
    assert_includes blocked[:message], 'Monthly AI Prospect Brief limit reached (10/10 briefs used)'
  end

  test "registered free user has 10 AI whatsapp messages per month" do
    status = UsageQuotaTracker.status(user: @user, ip: @ip)
    assert_equal 10, status[:whatsapp_messages][:limit]

    10.times do
      assert UsageQuotaTracker.check_feature(user: @user, ip: @ip, feature: :whatsapp_messages)[:allowed]
      UsageQuotaTracker.increment_feature!(user: @user, ip: @ip, feature: :whatsapp_messages)
    end

    blocked = UsageQuotaTracker.check_feature(user: @user, ip: @ip, feature: :whatsapp_messages)
    refute blocked[:allowed]
    assert_includes blocked[:message], 'Monthly AI WhatsApp message limit reached (10/10 messages used)'
  end
end

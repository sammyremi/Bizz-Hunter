# app/services/search_quota_tracker.rb

# frozen_string_literal: true

class SearchQuotaTracker
  GUEST_DAILY_LIMIT = UsageQuotaTracker::QUOTAS[:guest][:searches][:limit]
  USER_DAILY_LIMIT  = UsageQuotaTracker::QUOTAS[:free_user][:searches][:limit]

  class << self
    def status(user:, ip:)
      UsageQuotaTracker.status(user: user, ip: ip)
    end

    def check_and_increment!(user:, ip:)
      check = UsageQuotaTracker.check_feature(user: user, ip: ip, feature: :searches)
      if check[:allowed]
        UsageQuotaTracker.increment_feature!(user: user, ip: ip, feature: :searches)
        updated_status = UsageQuotaTracker.status(user: user, ip: ip)
        {
          allowed: true,
          quota: updated_status[:searches],
          message: 'Search permitted'
        }
      else
        {
          allowed: false,
          quota: check[:quota],
          message: check[:message]
        }
      end
    end
  end
end


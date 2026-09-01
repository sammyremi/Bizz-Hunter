# app/services/search_quota_tracker.rb

# frozen_string_literal: true

class SearchQuotaTracker
  GUEST_DAILY_LIMIT = 5
  USER_DAILY_LIMIT = 50

  class << self
    def status(user:, ip:)
      key, limit, user_type = build_key_and_limit(user, ip)
      used = Rails.cache.read(key).to_i
      remaining = [limit - used, 0].max
      reset_at = Time.now.utc.end_of_day

      {
        user_type: user_type,
        used: used,
        limit: limit,
        remaining: remaining,
        reset_at: reset_at
      }
    end

    def check_and_increment!(user:, ip:)
      current_status = status(user: user, ip: ip)

      if current_status[:remaining] <= 0
        return {
          allowed: false,
          quota: current_status,
          message: "Daily search limit reached (#{current_status[:limit]}/#{current_status[:limit]} searches used). Sign in for higher limits!"
        }
      end

      key, limit, user_type = build_key_and_limit(user, ip)
      new_used = current_status[:used] + 1
      Rails.cache.write(key, new_used, expires_in: 24.hours)

      updated_quota = {
        user_type: user_type,
        used: new_used,
        limit: limit,
        remaining: [limit - new_used, 0].max,
        reset_at: Time.now.utc.end_of_day
      }

      {
        allowed: true,
        quota: updated_quota,
        message: 'Search permitted'
      }
    end

    private

    def build_key_and_limit(user, ip)
      today = Time.now.utc.strftime('%Y-%m-%d')

      if user.present?
        ["bizz_quota:user:#{user.id}:#{today}", USER_DAILY_LIMIT, 'authenticated']
      else
        safe_ip = (ip.presence || '127.0.0.1').to_s.gsub(/[^0-9a-fA-F:.]/, '')
        ["bizz_quota:guest:#{safe_ip}:#{today}", GUEST_DAILY_LIMIT, 'guest']
      end
    end
  end
end

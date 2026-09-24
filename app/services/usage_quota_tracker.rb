# app/services/usage_quota_tracker.rb

# frozen_string_literal: true

class UsageQuotaTracker
  # Centralized Quota Configuration for Bizz-Hunter
  QUOTAS = {
    guest: {
      searches:          { limit: 2,  period: :daily },
      prospect_briefs:   { limit: 1,  period: :daily },
      whatsapp_messages: { limit: 1,  period: :daily },
      max_search_results: 20
    },
    free_user: {
      searches:          { limit: 20, period: :daily },
      prospect_briefs:   { limit: 10, period: :monthly },
      whatsapp_messages: { limit: 10, period: :monthly },
      max_search_results: 60
    }
  }.freeze

  class << self
    def config_for(user)
      user.present? ? QUOTAS[:free_user] : QUOTAS[:guest]
    end

    def status(user:, ip:)
      user_type = user.present? ? 'authenticated' : 'guest'
      role = user.present? ? :free_user : :guest
      cfg = QUOTAS[role]

      searches_stat = fetch_feature_status(user: user, ip: ip, feature: :searches, feature_cfg: cfg[:searches])
      briefs_stat   = fetch_feature_status(user: user, ip: ip, feature: :prospect_briefs, feature_cfg: cfg[:prospect_briefs])
      messages_stat = fetch_feature_status(user: user, ip: ip, feature: :whatsapp_messages, feature_cfg: cfg[:whatsapp_messages])

      {
        user_type: user_type,
        used: searches_stat[:used],
        limit: searches_stat[:limit],
        remaining: searches_stat[:remaining],
        reset_at: searches_stat[:reset_at],
        searches: searches_stat,
        prospect_briefs: briefs_stat,
        whatsapp_messages: messages_stat,
        limits: {
          max_search_results: cfg[:max_search_results]
        }
      }
    end

    def check_feature(user:, ip:, feature:)
      role = user.present? ? :free_user : :guest
      feature_cfg = QUOTAS[role][feature]
      return { allowed: true } unless feature_cfg

      stat = fetch_feature_status(user: user, ip: ip, feature: feature, feature_cfg: feature_cfg)

      if stat[:remaining] <= 0
        {
          allowed: false,
          quota: stat,
          message: limit_reached_message(feature, user.present?)
        }
      else
        {
          allowed: true,
          quota: stat
        }
      end
    end

    def increment_feature!(user:, ip:, feature:)
      role = user.present? ? :free_user : :guest
      feature_cfg = QUOTAS[role][feature]
      return unless feature_cfg

      key = cache_key(user: user, ip: ip, feature: feature, period: feature_cfg[:period])
      used = Rails.cache.read(key).to_i
      expires_in = feature_cfg[:period] == :monthly ? 31.days : 24.hours
      Rails.cache.write(key, used + 1, expires_in: expires_in)
    end

    def reset_feature!(user:, ip:, feature:)
      role = user.present? ? :free_user : :guest
      feature_cfg = QUOTAS[role][feature]
      return unless feature_cfg

      key = cache_key(user: user, ip: ip, feature: feature, period: feature_cfg[:period])
      Rails.cache.delete(key)
    end

    private

    def fetch_feature_status(user:, ip:, feature:, feature_cfg:)
      limit = feature_cfg[:limit]
      period = feature_cfg[:period]
      key = cache_key(user: user, ip: ip, feature: feature, period: period)

      used = Rails.cache.read(key).to_i
      remaining = [limit - used, 0].max
      reset_at = period == :monthly ? Time.now.utc.end_of_month : Time.now.utc.end_of_day

      {
        feature: feature,
        used: used,
        limit: limit,
        remaining: remaining,
        period: period,
        reset_at: reset_at
      }
    end

    def cache_key(user:, ip:, feature:, period:)
      time_suffix = if period == :monthly
                      Time.now.utc.strftime('%Y-%m')
                    else
                      Time.now.utc.strftime('%Y-%m-%d')
                    end

      if user.present?
        "bizz_quota:#{feature}:user:#{user.id}:#{time_suffix}"
      else
        safe_ip = (ip.presence || '127.0.0.1').to_s.gsub(/[^0-9a-fA-F:.]/, '')
        "bizz_quota:#{feature}:guest:#{safe_ip}:#{time_suffix}"
      end
    end

    def limit_reached_message(feature, authenticated)
      if !authenticated
        "Free preview limit reached. Create a free account to continue."
      else
        case feature
        when :searches
          "Daily search limit reached (20/20 searches used)."
        when :prospect_briefs
          "Monthly AI Prospect Brief limit reached (10/10 briefs used)."
        when :whatsapp_messages
          "Monthly AI WhatsApp message limit reached (10/10 messages used)."
        else
          "Usage limit reached."
        end
      end
    end
  end
end

# config/initializers/resend.rb
# frozen_string_literal: true

# Configure the Resend API key from the environment.
# Never hardcode the API key here.
if ENV['RESEND_API_KEY'].present?
  Resend.api_key = ENV['RESEND_API_KEY']
else
  Rails.logger.warn('[Resend] RESEND_API_KEY is not set. Email delivery will not work.')
end

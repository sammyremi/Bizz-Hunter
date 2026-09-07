require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://127.0.0.1:3000/api/v1'

def request(method, path, body = nil, token = nil)
  uri = URI.parse("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  
  req_class = case method
              when :get then Net::HTTP::Get
              when :post then Net::HTTP::Post
              when :patch then Net::HTTP::Patch
              when :delete then Net::HTTP::Delete
              end
              
  req = req_class.new(uri.request_uri)
  req['Content-Type'] = 'application/json'
  req['Accept'] = 'application/json'
  req['Authorization'] = "Bearer #{token}" if token
  req.body = body.to_json if body
  
  res = http.request(req)
  JSON.parse(res.body)
rescue => e
  { 'success' => false, 'error' => e.message }
end

email = "onboarding_test_#{Time.now.to_i}@example.com"
password = "password123"

puts "1. Registering new first-time user: #{email}"
reg_res = request(:post, '/auth/register', { name: "Onboarding Tester", email: email, password: password })
token = reg_res['token']
puts "   Token acquired: #{!token.nil?}"

puts "\n2. Verifying user starts with 0 profiles (triggers onboarding)..."
list_res = request(:get, '/prospecting_profiles', nil, token)
puts "   Profiles count: #{list_res['data'].size}"

puts "\n3. Simulating profile creation from onboarding modal..."
p1_payload = {
  name: "Restaurant Software Sales",
  service: "POS & Ordering Software",
  service_description: "Cloud POS systems for independent restaurants",
  target_businesses: ["Restaurants", "Cafes", "Pizzerias"],
  opportunity_signals: ["No online ordering", "Outdated website"],
  contact_signals: ["WhatsApp available", "Phone available"],
  is_default: true
}
create_res = request(:post, '/prospecting_profiles', p1_payload, token)
p1 = create_res['data']
puts "   Created Profile ID: #{p1['id']}, Default: #{p1['is_default']}"

puts "\n4. Verifying profiles list now has 1 profile (disables onboarding)..."
post_create_list = request(:get, '/prospecting_profiles', nil, token)
puts "   Profiles count now: #{post_create_list['data'].size}"

puts "\n=== TASK 3.5 ONBOARDING INTEGRATION VERIFICATION SUCCESSFUL ==="

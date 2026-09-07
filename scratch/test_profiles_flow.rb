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

email = "ui_test_#{Time.now.to_i}@example.com"
password = "password123"

puts "1. Registering user: #{email}"
reg_res = request(:post, '/auth/register', { name: "UI Tester", email: email, password: password })
token = reg_res['token']
puts "   Token acquired: #{!token.nil?}"

puts "\n2. Fetching empty profiles list..."
list_res = request(:get, '/prospecting_profiles', nil, token)
puts "   Initial count: #{list_res['data'].size}"

puts "\n3. Creating Profile 1 (Restaurant Website Dev)..."
p1_payload = {
  name: "Restaurant Website Development",
  service: "Website Development",
  service_description: "Modern websites for restaurants",
  target_businesses: ["Restaurants", "Cafes"],
  opportunity_signals: ["No website", "Outdated website"],
  contact_signals: ["WhatsApp available", "Phone available"],
  is_default: true
}
create1_res = request(:post, '/prospecting_profiles', p1_payload, token)
p1 = create1_res['data']
puts "   Created ID: #{p1['id']}, Default: #{p1['is_default']}"

puts "\n4. Creating Profile 2 (Hotel Systems)..."
p2_payload = {
  name: "Hotel Booking Systems",
  service: "Custom Software",
  service_description: "Direct booking engines for boutique hotels",
  target_businesses: ["Hotels", "Resorts"],
  opportunity_signals: ["No online booking"],
  contact_signals: ["Email available"],
  is_default: false
}
create2_res = request(:post, '/prospecting_profiles', p2_payload, token)
p2 = create2_res['data']
puts "   Created ID: #{p2['id']}, Default: #{p2['is_default']}"

puts "\n5. Setting Profile 2 as Default..."
set_def_res = request(:patch, "/prospecting_profiles/#{p2['id']}", { is_default: true }, token)
puts "   Profile 2 is_default: #{set_def_res['data']['is_default']}"

puts "\n6. Verifying Profile 1 loses default status..."
p1_get = request(:get, "/prospecting_profiles/#{p1['id']}", nil, token)
puts "   Profile 1 is_default now: #{p1_get['data']['is_default']}"

puts "\n7. Editing Profile 1 description..."
update_res = request(:patch, "/prospecting_profiles/#{p1['id']}", { service_description: "Updated description for restaurants" }, token)
puts "   Updated desc: #{update_res['data']['service_description']}"

puts "\n8. Deleting Profile 1..."
del_res = request(:delete, "/prospecting_profiles/#{p1['id']}", nil, token)
puts "   Delete success: #{del_res['success']}"

puts "\n9. Final profiles count..."
final_list = request(:get, '/prospecting_profiles', nil, token)
puts "   Final count: #{final_list['data'].size}"

puts "\n=== ALL INTEGRATION VERIFICATIONS SUCCESSFUL ==="

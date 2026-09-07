# scratch/test_gemini_integration.rb

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

email = "gemini_tester_#{Time.now.to_i}@example.com"
password = "password123"

puts "1. Registering user for real Gemini integration test: #{email}"
reg_res = request(:post, '/auth/register', { name: "Gemini Tester", email: email, password: password })
token = reg_res['token']
puts "   Token acquired: #{!token.nil?}"

puts "\n2. Testing POST /api/v1/prospecting_profiles/generate with real Gemini API..."
prompt = "I build modern websites for restaurants and hotels that want to improve their online presence."
gen_res = request(:post, '/prospecting_profiles/generate', { description: prompt }, token)

if gen_res['success'] && gen_res['data']
  proposal = gen_res['data']
  puts "   ✅ Real Gemini response received successfully!"
  puts "   Name: #{proposal['name']}"
  puts "   Service: #{proposal['service']}"
  puts "   Description: #{proposal['service_description']}"
  puts "   Target Businesses: #{proposal['target_businesses'].inspect}"
  puts "   Opportunity Signals: #{proposal['opportunity_signals'].inspect}"
  puts "   Contact Signals: #{proposal['contact_signals'].inspect}"

  puts "\n3. Simulating user review & creation of the proposal via existing API..."
  create_res = request(:post, '/prospecting_profiles', proposal, token)
  if create_res['success'] && create_res['data']
    saved = create_res['data']
    puts "   ✅ Profile persisted into PostgreSQL DB! ID: #{saved['id']}, Default: #{saved['is_default']}"
  else
    puts "   ❌ Failed to persist profile: #{create_res['message']}"
  end
else
  puts "   ❌ Gemini Generation Error: #{gen_res['message']}"
end

puts "\n=== TASK 4 REAL GEMINI INTEGRATION VERIFICATION COMPLETE ==="

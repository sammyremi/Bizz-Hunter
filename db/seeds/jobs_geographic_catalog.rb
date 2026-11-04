# frozen_string_literal: true

# db/seeds/jobs_geographic_catalog.rb

puts "== Seeding Global Jobs Geographic Catalog =="

LAUNCH_COUNTRIES ||= [
  {
    iso_country_code: "NG",
    iso_alpha3_code: "NGA",
    name: "Nigeria",
    calling_code: "234",
    default_timezone: "Africa/Lagos",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Lagos", region: "Lagos State", classification: "metropolis", priority: 1, aliases: ["Eko", "Lasgidi"] },
      { name: "Abuja", region: "Federal Capital Territory", classification: "metropolis", priority: 2, aliases: ["FCT"] },
      { name: "Kano", region: "Kano State", classification: "metropolis", priority: 3, aliases: [] },
      { name: "Ibadan", region: "Oyo State", classification: "metropolis", priority: 4, aliases: [] },
      { name: "Port Harcourt", region: "Rivers State", classification: "metropolis", priority: 5, aliases: ["PH", "Pitakwa"] },
      { name: "Benin City", region: "Edo State", classification: "municipality", priority: 6, aliases: [] },
      { name: "Enugu", region: "Enugu State", classification: "municipality", priority: 7, aliases: ["Coal City"] },
      { name: "Kaduna", region: "Kaduna State", classification: "municipality", priority: 8, aliases: [] },
      { name: "Jos", region: "Plateau State", classification: "municipality", priority: 9, aliases: ["J-Town"] },
      { name: "Abeokuta", region: "Ogun State", classification: "municipality", priority: 10, aliases: [] },
      { name: "Warri", region: "Delta State", classification: "municipality", priority: 11, aliases: [] },
      { name: "Onitsha", region: "Anambra State", classification: "municipality", priority: 12, aliases: [] },
      { name: "Ilorin", region: "Kwara State", classification: "municipality", priority: 13, aliases: [] },
      { name: "Owerri", region: "Imo State", classification: "municipality", priority: 14, aliases: [] },
      { name: "Uyo", region: "Akwa Ibom State", classification: "municipality", priority: 15, aliases: [] },
      { name: "Calabar", region: "Cross River State", classification: "municipality", priority: 16, aliases: [] },
      { name: "Aba", region: "Abia State", classification: "municipality", priority: 17, aliases: [] },
      { name: "Akure", region: "Ondo State", classification: "municipality", priority: 18, aliases: [] },
      { name: "Sokoto", region: "Sokoto State", classification: "municipality", priority: 19, aliases: [] },
      { name: "Maiduguri", region: "Borno State", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "GH",
    iso_alpha3_code: "GHA",
    name: "Ghana",
    calling_code: "233",
    default_timezone: "Africa/Accra",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Accra", region: "Greater Accra", classification: "metropolis", priority: 1, aliases: [] },
      { name: "Kumasi", region: "Ashanti", classification: "metropolis", priority: 2, aliases: ["Oseikrom"] },
      { name: "Tamale", region: "Northern", classification: "municipality", priority: 3, aliases: [] },
      { name: "Takoradi", region: "Western", classification: "municipality", priority: 4, aliases: ["Sekondi-Takoradi"] },
      { name: "Cape Coast", region: "Central", classification: "municipality", priority: 5, aliases: ["Oguaa"] },
      { name: "Tema", region: "Greater Accra", classification: "municipality", priority: 6, aliases: [] },
      { name: "Koforidua", region: "Eastern", classification: "municipality", priority: 7, aliases: ["K-dua"] },
      { name: "Sunyani", region: "Bono", classification: "municipality", priority: 8, aliases: [] },
      { name: "Ho", region: "Volta", classification: "municipality", priority: 9, aliases: [] },
      { name: "Wa", region: "Upper West", classification: "municipality", priority: 10, aliases: [] },
      { name: "Bolgatanga", region: "Upper East", classification: "municipality", priority: 11, aliases: ["Bolga"] },
      { name: "Obuasi", region: "Ashanti", classification: "municipality", priority: 12, aliases: [] },
      { name: "Techiman", region: "Bono East", classification: "municipality", priority: 13, aliases: [] },
      { name: "Nkawkaw", region: "Eastern", classification: "municipality", priority: 14, aliases: [] },
      { name: "Winneba", region: "Central", classification: "municipality", priority: 15, aliases: [] },
      { name: "Kasoa", region: "Central", classification: "municipality", priority: 16, aliases: [] },
      { name: "Tarkwa", region: "Western", classification: "municipality", priority: 17, aliases: [] },
      { name: "Aflao", region: "Volta", classification: "municipality", priority: 18, aliases: [] },
      { name: "Sefwi Wiawso", region: "Western North", classification: "municipality", priority: 19, aliases: [] },
      { name: "Yendi", region: "Northern", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "ZA",
    iso_alpha3_code: "ZAF",
    name: "South Africa",
    calling_code: "27",
    default_timezone: "Africa/Johannesburg",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Johannesburg", region: "Gauteng", classification: "metropolis", priority: 1, aliases: ["Joburg", "Jozi"] },
      { name: "Cape Town", region: "Western Cape", classification: "metropolis", priority: 2, aliases: ["Mother City"] },
      { name: "Durban", region: "KwaZulu-Natal", classification: "metropolis", priority: 3, aliases: ["eThekwini"] },
      { name: "Pretoria", region: "Gauteng", classification: "metropolis", priority: 4, aliases: ["Tshwane"] },
      { name: "Gqeberha", region: "Eastern Cape", classification: "metropolis", priority: 5, aliases: ["Port Elizabeth", "PE"] },
      { name: "Bloemfontein", region: "Free State", classification: "municipality", priority: 6, aliases: ["Mangaung"] },
      { name: "East London", region: "Eastern Cape", classification: "municipality", priority: 7, aliases: ["Buffalo City"] },
      { name: "Polokwane", region: "Limpopo", classification: "municipality", priority: 8, aliases: ["Pietersburg"] },
      { name: "Mbombela", region: "Mpumalanga", classification: "municipality", priority: 9, aliases: ["Nelspruit"] },
      { name: "Kimberley", region: "Northern Cape", classification: "municipality", priority: 10, aliases: [] },
      { name: "Rustenburg", region: "North West", classification: "municipality", priority: 11, aliases: [] },
      { name: "Pietermaritzburg", region: "KwaZulu-Natal", classification: "municipality", priority: 12, aliases: ["PMB"] },
      { name: "George", region: "Western Cape", classification: "municipality", priority: 13, aliases: [] },
      { name: "Stellenbosch", region: "Western Cape", classification: "municipality", priority: 14, aliases: [] },
      { name: "Paarl", region: "Western Cape", classification: "municipality", priority: 15, aliases: [] },
      { name: "Vereeniging", region: "Gauteng", classification: "municipality", priority: 16, aliases: [] },
      { name: "Klerksdorp", region: "North West", classification: "municipality", priority: 17, aliases: [] },
      { name: "Richards Bay", region: "KwaZulu-Natal", classification: "municipality", priority: 18, aliases: [] },
      { name: "Welkom", region: "Free State", classification: "municipality", priority: 19, aliases: [] },
      { name: "Newcastle", region: "KwaZulu-Natal", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "KE",
    iso_alpha3_code: "KEN",
    name: "Kenya",
    calling_code: "254",
    default_timezone: "Africa/Nairobi",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Nairobi", region: "Nairobi County", classification: "metropolis", priority: 1, aliases: [] },
      { name: "Mombasa", region: "Mombasa County", classification: "metropolis", priority: 2, aliases: [] },
      { name: "Kisumu", region: "Kisumu County", classification: "metropolis", priority: 3, aliases: [] },
      { name: "Nakuru", region: "Nakuru County", classification: "metropolis", priority: 4, aliases: [] },
      { name: "Eldoret", region: "Uasin Gishu County", classification: "municipality", priority: 5, aliases: [] },
      { name: "Thika", region: "Kiambu County", classification: "municipality", priority: 6, aliases: [] },
      { name: "Malindi", region: "Kilifi County", classification: "municipality", priority: 7, aliases: [] },
      { name: "Kitale", region: "Trans-Nzoia County", classification: "municipality", priority: 8, aliases: [] },
      { name: "Garissa", region: "Garissa County", classification: "municipality", priority: 9, aliases: [] },
      { name: "Kakamega", region: "Kakamega County", classification: "municipality", priority: 10, aliases: [] },
      { name: "Nyeri", region: "Nyeri County", classification: "municipality", priority: 11, aliases: [] },
      { name: "Machakos", region: "Machakos County", classification: "municipality", priority: 12, aliases: [] },
      { name: "Meru", region: "Meru County", classification: "municipality", priority: 13, aliases: [] },
      { name: "Naivasha", region: "Nakuru County", classification: "municipality", priority: 14, aliases: [] },
      { name: "Kericho", region: "Kericho County", classification: "municipality", priority: 15, aliases: [] },
      { name: "Embu", region: "Embu County", classification: "municipality", priority: 16, aliases: [] },
      { name: "Nanyuki", region: "Laikipia County", classification: "municipality", priority: 17, aliases: [] },
      { name: "Bungoma", region: "Bungoma County", classification: "municipality", priority: 18, aliases: [] },
      { name: "Kilifi", region: "Kilifi County", classification: "municipality", priority: 19, aliases: [] },
      { name: "Voi", region: "Taita-Taveta County", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "UG",
    iso_alpha3_code: "UGA",
    name: "Uganda",
    calling_code: "256",
    default_timezone: "Africa/Kampala",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Kampala", region: "Central", classification: "metropolis", priority: 1, aliases: [] },
      { name: "Entebbe", region: "Central", classification: "municipality", priority: 2, aliases: [] },
      { name: "Jinja", region: "Eastern", classification: "municipality", priority: 3, aliases: [] },
      { name: "Mbarara", region: "Western", classification: "municipality", priority: 4, aliases: [] },
      { name: "Gulu", region: "Northern", classification: "municipality", priority: 5, aliases: [] },
      { name: "Mbale", region: "Eastern", classification: "municipality", priority: 6, aliases: [] },
      { name: "Fort Portal", region: "Western", classification: "municipality", priority: 7, aliases: [] },
      { name: "Masaka", region: "Central", classification: "municipality", priority: 8, aliases: [] },
      { name: "Lira", region: "Northern", classification: "municipality", priority: 9, aliases: [] },
      { name: "Arua", region: "Northern", classification: "municipality", priority: 10, aliases: [] },
      { name: "Mukono", region: "Central", classification: "municipality", priority: 11, aliases: [] },
      { name: "Nansana", region: "Central", classification: "municipality", priority: 12, aliases: [] },
      { name: "Wakiso", region: "Central", classification: "municipality", priority: 13, aliases: [] },
      { name: "Hoima", region: "Western", classification: "municipality", priority: 14, aliases: [] },
      { name: "Soroti", region: "Eastern", classification: "municipality", priority: 15, aliases: [] },
      { name: "Kabale", region: "Western", classification: "municipality", priority: 16, aliases: [] },
      { name: "Tororo", region: "Eastern", classification: "municipality", priority: 17, aliases: [] },
      { name: "Iganga", region: "Eastern", classification: "municipality", priority: 18, aliases: [] },
      { name: "Kasese", region: "Western", classification: "municipality", priority: 19, aliases: [] },
      { name: "Busia", region: "Eastern", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "TZ",
    iso_alpha3_code: "TZA",
    name: "Tanzania",
    calling_code: "255",
    default_timezone: "Africa/Dar_es_Salaam",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Dar es Salaam", region: "Dar es Salaam", classification: "metropolis", priority: 1, aliases: ["DSM"] },
      { name: "Dodoma", region: "Dodoma", classification: "metropolis", priority: 2, aliases: [] },
      { name: "Arusha", region: "Arusha", classification: "municipality", priority: 3, aliases: [] },
      { name: "Mwanza", region: "Mwanza", classification: "municipality", priority: 4, aliases: ["Rock City"] },
      { name: "Mbeya", region: "Mbeya", classification: "municipality", priority: 5, aliases: [] },
      { name: "Morogoro", region: "Morogoro", classification: "municipality", priority: 6, aliases: [] },
      { name: "Tanga", region: "Tanga", classification: "municipality", priority: 7, aliases: [] },
      { name: "Zanzibar City", region: "Mjini Magharibi", classification: "municipality", priority: 8, aliases: ["Stone Town"] },
      { name: "Moshi", region: "Kilimanjaro", classification: "municipality", priority: 9, aliases: [] },
      { name: "Iringa", region: "Iringa", classification: "municipality", priority: 10, aliases: [] },
      { name: "Tabora", region: "Tabora", classification: "municipality", priority: 11, aliases: [] },
      { name: "Kigoma", region: "Kigoma", classification: "municipality", priority: 12, aliases: [] },
      { name: "Sumbawanga", region: "Rukwa", classification: "municipality", priority: 13, aliases: [] },
      { name: "Songea", region: "Ruvuma", classification: "municipality", priority: 14, aliases: [] },
      { name: "Shinyanga", region: "Shinyanga", classification: "municipality", priority: 15, aliases: [] },
      { name: "Musoma", region: "Mara", classification: "municipality", priority: 16, aliases: [] },
      { name: "Mtwara", region: "Mtwara", classification: "municipality", priority: 17, aliases: [] },
      { name: "Singida", region: "Singida", classification: "municipality", priority: 18, aliases: [] },
      { name: "Babati", region: "Manyara", classification: "municipality", priority: 19, aliases: [] },
      { name: "Geita", region: "Geita", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "GB",
    iso_alpha3_code: "GBR",
    name: "United Kingdom",
    calling_code: "44",
    default_timezone: "Europe/London",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "London", region: "Greater London", classification: "metropolis", priority: 1, aliases: [] },
      { name: "Birmingham", region: "West Midlands", classification: "metropolis", priority: 2, aliases: [] },
      { name: "Manchester", region: "Greater Manchester", classification: "metropolis", priority: 3, aliases: [] },
      { name: "Leeds", region: "West Yorkshire", classification: "metropolis", priority: 4, aliases: [] },
      { name: "Glasgow", region: "Scotland", classification: "metropolis", priority: 5, aliases: [] },
      { name: "Liverpool", region: "Merseyside", classification: "metropolis", priority: 6, aliases: [] },
      { name: "Bristol", region: "South West", classification: "metropolis", priority: 7, aliases: [] },
      { name: "Sheffield", region: "South Yorkshire", classification: "metropolis", priority: 8, aliases: [] },
      { name: "Edinburgh", region: "Scotland", classification: "metropolis", priority: 9, aliases: [] },
      { name: "Leicester", region: "East Midlands", classification: "municipality", priority: 10, aliases: [] },
      { name: "Nottingham", region: "East Midlands", classification: "municipality", priority: 11, aliases: [] },
      { name: "Newcastle upon Tyne", region: "Tyne and Wear", classification: "municipality", priority: 12, aliases: ["Newcastle"] },
      { name: "Cardiff", region: "Wales", classification: "metropolis", priority: 13, aliases: ["Caerdydd"] },
      { name: "Belfast", region: "Northern Ireland", classification: "metropolis", priority: 14, aliases: [] },
      { name: "Coventry", region: "West Midlands", classification: "municipality", priority: 15, aliases: [] },
      { name: "Bradford", region: "West Yorkshire", classification: "municipality", priority: 16, aliases: [] },
      { name: "Southampton", region: "Hampshire", classification: "municipality", priority: 17, aliases: [] },
      { name: "Brighton", region: "East Sussex", classification: "municipality", priority: 18, aliases: ["Brighton and Hove"] },
      { name: "Oxford", region: "Oxfordshire", classification: "municipality", priority: 19, aliases: [] },
      { name: "Cambridge", region: "Cambridgeshire", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "US",
    iso_alpha3_code: "USA",
    name: "United States",
    calling_code: "1",
    default_timezone: "America/New_York",
    whatsapp_consumer_status: "moderate",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "New York", region: "New York", classification: "metropolis", priority: 1, aliases: ["NYC", "New York City"] },
      { name: "Los Angeles", region: "California", classification: "metropolis", priority: 2, aliases: ["LA"] },
      { name: "Chicago", region: "Illinois", classification: "metropolis", priority: 3, aliases: [] },
      { name: "Houston", region: "Texas", classification: "metropolis", priority: 4, aliases: [] },
      { name: "Phoenix", region: "Arizona", classification: "metropolis", priority: 5, aliases: [] },
      { name: "Philadelphia", region: "Pennsylvania", classification: "metropolis", priority: 6, aliases: ["Philly"] },
      { name: "San Antonio", region: "Texas", classification: "metropolis", priority: 7, aliases: [] },
      { name: "San Diego", region: "California", classification: "metropolis", priority: 8, aliases: [] },
      { name: "Dallas", region: "Texas", classification: "metropolis", priority: 9, aliases: [] },
      { name: "Austin", region: "Texas", classification: "metropolis", priority: 10, aliases: [] },
      { name: "Jacksonville", region: "Florida", classification: "municipality", priority: 11, aliases: [] },
      { name: "San Francisco", region: "California", classification: "metropolis", priority: 12, aliases: ["SF"] },
      { name: "Seattle", region: "Washington", classification: "metropolis", priority: 13, aliases: [] },
      { name: "Denver", region: "Colorado", classification: "metropolis", priority: 14, aliases: [] },
      { name: "Boston", region: "Massachusetts", classification: "metropolis", priority: 15, aliases: [] },
      { name: "Miami", region: "Florida", classification: "metropolis", priority: 16, aliases: [] },
      { name: "Atlanta", region: "Georgia", classification: "metropolis", priority: 17, aliases: [] },
      { name: "Las Vegas", region: "Nevada", classification: "municipality", priority: 18, aliases: ["Vegas"] },
      { name: "Portland", region: "Oregon", classification: "municipality", priority: 19, aliases: [] },
      { name: "Detroit", region: "Michigan", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "CA",
    iso_alpha3_code: "CAN",
    name: "Canada",
    calling_code: "1",
    default_timezone: "America/Toronto",
    whatsapp_consumer_status: "moderate",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Toronto", region: "Ontario", classification: "metropolis", priority: 1, aliases: [] },
      { name: "Montreal", region: "Quebec", classification: "metropolis", priority: 2, aliases: [] },
      { name: "Vancouver", region: "British Columbia", classification: "metropolis", priority: 3, aliases: [] },
      { name: "Calgary", region: "Alberta", classification: "metropolis", priority: 4, aliases: [] },
      { name: "Edmonton", region: "Alberta", classification: "metropolis", priority: 5, aliases: [] },
      { name: "Ottawa", region: "Ontario", classification: "metropolis", priority: 6, aliases: [] },
      { name: "Winnipeg", region: "Manitoba", classification: "metropolis", priority: 7, aliases: [] },
      { name: "Quebec City", region: "Quebec", classification: "municipality", priority: 8, aliases: ["Ville de Québec"] },
      { name: "Hamilton", region: "Ontario", classification: "municipality", priority: 9, aliases: [] },
      { name: "Kitchener", region: "Ontario", classification: "municipality", priority: 10, aliases: [] },
      { name: "London", region: "Ontario", classification: "municipality", priority: 11, aliases: [] },
      { name: "Halifax", region: "Nova Scotia", classification: "municipality", priority: 12, aliases: [] },
      { name: "Victoria", region: "British Columbia", classification: "municipality", priority: 13, aliases: [] },
      { name: "Saskatoon", region: "Saskatchewan", classification: "municipality", priority: 14, aliases: [] },
      { name: "Regina", region: "Saskatchewan", classification: "municipality", priority: 15, aliases: [] },
      { name: "St. John's", region: "Newfoundland and Labrador", classification: "municipality", priority: 16, aliases: [] },
      { name: "Windsor", region: "Ontario", classification: "municipality", priority: 17, aliases: [] },
      { name: "Oshawa", region: "Ontario", classification: "municipality", priority: 18, aliases: [] },
      { name: "Barrie", region: "Ontario", classification: "municipality", priority: 19, aliases: [] },
      { name: "Kelowna", region: "British Columbia", classification: "municipality", priority: 20, aliases: [] }
    ]
  },
  {
    iso_country_code: "AE",
    iso_alpha3_code: "ARE",
    name: "United Arab Emirates",
    calling_code: "971",
    default_timezone: "Asia/Dubai",
    whatsapp_consumer_status: "widespread",
    whatsapp_business_status: "available",
    whatsapp_api_eligibility: "eligible",
    data_source: "itu_e164_meta_2026",
    cities: [
      { name: "Dubai", region: "Emirate of Dubai", classification: "metropolis", priority: 1, aliases: [] },
      { name: "Abu Dhabi", region: "Emirate of Abu Dhabi", classification: "metropolis", priority: 2, aliases: [] },
      { name: "Sharjah", region: "Emirate of Sharjah", classification: "metropolis", priority: 3, aliases: [] },
      { name: "Al Ain", region: "Emirate of Abu Dhabi", classification: "municipality", priority: 4, aliases: [] },
      { name: "Ajman", region: "Emirate of Ajman", classification: "municipality", priority: 5, aliases: [] },
      { name: "Ras Al Khaimah", region: "Emirate of Ras Al Khaimah", classification: "municipality", priority: 6, aliases: ["RAK"] },
      { name: "Fujairah", region: "Emirate of Fujairah", classification: "municipality", priority: 7, aliases: [] },
      { name: "Umm Al Quwain", region: "Emirate of Umm Al Quwain", classification: "municipality", priority: 8, aliases: ["UAQ"] },
      { name: "Khor Fakkan", region: "Emirate of Sharjah", classification: "municipality", priority: 9, aliases: [] },
      { name: "Kalba", region: "Emirate of Sharjah", classification: "municipality", priority: 10, aliases: [] },
      { name: "Dibba Al-Fujairah", region: "Emirate of Fujairah", classification: "municipality", priority: 11, aliases: [] },
      { name: "Jebel Ali", region: "Emirate of Dubai", classification: "urban_district", priority: 12, aliases: [] },
      { name: "Ruwais", region: "Emirate of Abu Dhabi", classification: "municipality", priority: 13, aliases: [] },
      { name: "Madinat Zayed", region: "Emirate of Abu Dhabi - Al Dhafra", classification: "municipality", priority: 14, aliases: [] },
      { name: "Liwa Oasis", region: "Emirate of Abu Dhabi - Al Dhafra", classification: "settlement", priority: 15, aliases: [] },
      { name: "Hatta", region: "Emirate of Dubai", classification: "municipality", priority: 16, aliases: [] },
      { name: "Al Dhaid", region: "Emirate of Sharjah", classification: "municipality", priority: 17, aliases: [] },
      { name: "Masafi", region: "Emirate of Ras Al Khaimah/Fujairah", classification: "settlement", priority: 18, aliases: [] },
      { name: "Ghayathi", region: "Emirate of Abu Dhabi - Al Dhafra", classification: "municipality", priority: 19, aliases: [] },
      { name: "Al Madam", region: "Emirate of Sharjah", classification: "settlement", priority: 20, aliases: [] }
    ]
  }
].freeze

Country.transaction do
  total_countries = 0
  total_cities = 0

  LAUNCH_COUNTRIES.each do |c_data|
    country = Country.find_or_initialize_by(iso_country_code: c_data[:iso_country_code])
    country.assign_attributes(
      iso_alpha3_code:          c_data[:iso_alpha3_code],
      name:                     c_data[:name],
      calling_code:             c_data[:calling_code],
      default_timezone:         c_data[:default_timezone],
      whatsapp_consumer_status: c_data[:whatsapp_consumer_status],
      whatsapp_business_status: c_data[:whatsapp_business_status],
      whatsapp_api_eligibility: c_data[:whatsapp_api_eligibility],
      data_source:              c_data[:data_source],
      is_active:                true,
      last_verified_at:         Time.current
    )
    country.save!
    total_countries += 1

    c_data[:cities].each do |city_data|
      city = country.country_cities.find_or_initialize_by(name: city_data[:name], state_or_region: city_data[:region])
      city.assign_attributes(
        administrative_classification: city_data[:classification],
        commercial_priority:           city_data[:priority],
        is_default_discovery_pool:     true,
        is_active:                     true,
        aliases:                       city_data[:aliases],
        data_source:                   c_data[:data_source],
        last_verified_at:              Time.current
      )
      city.save!
      total_cities += 1
    end
  end

  puts "== Successfully seeded #{total_countries} launch countries and #{total_cities} cities =="
end


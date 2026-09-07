# Bizz-Hunter — Technical Architecture

## 1. Architecture Overview

Bizz-Hunter is primarily a Ruby on Rails API application backed by PostgreSQL.

High-level architecture:

```text
                    ┌─────────────────────┐
                    │      Frontend       │
                    │  Bizz-Hunter UI     │
                    └──────────┬──────────┘
                               │
                               │ HTTP / JSON
                               ▼
                    ┌─────────────────────┐
                    │    Rails API        │
                    │                     │
                    │ Controllers         │
                    │ Authentication      │
                    │ Authorization       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    Service Layer    │
                    │                     │
                    │ Business Logic      │
                    │ External APIs       │
                    │ Calculations        │
                    └───────┬─────┬───────┘
                            │     │
                 ┌──────────┘     └────────────┐
                 ▼                             ▼
       ┌─────────────────┐           ┌─────────────────┐
       │    PostgreSQL   │           │ External APIs   │
       │                 │           │                 │
       │ Users           │           │ Google Places   │
       │ Searches        │           │ Gemini          │
       │ Profiles        │           │ Future APIs     │
       │ Prospects       │           └─────────────────┘
       └─────────────────┘
```

---

# 2. Backend Stack

Expected/current backend technologies include:

* Ruby
* Ruby on Rails
* Rails API architecture
* PostgreSQL
* Devise
* devise-jwt
* ActiveRecord
* RSpec or the project's existing test framework
* Rswag/Swagger where currently used

Always inspect the actual `Gemfile` and project structure before assuming a dependency exists.

---

# 3. Rails Layering

Preferred architecture:

```text
Request
  ↓
Route
  ↓
Controller
  ↓
Service
  ↓
Model / External API
  ↓
Database / External Service
```

Controllers should be thin.

Services contain business operations.

Models contain:

* relationships
* validations
* persistence-related behavior
* small domain methods

External integrations should be isolated behind services.

---

# 4. API Namespace

Existing APIs are organized under:

```text
app/controllers/api/v1/
```

Expected namespace:

```ruby
module Api
  module V1
    ...
  end
end
```

New API controllers should follow this convention.

---

# 5. Authentication

Authentication uses Devise/JWT.

Protected endpoints generally use:

```ruby
before_action :authenticate_user!
```

The authenticated user is accessed using:

```ruby
current_user
```

Never accept ownership from client input.

---

# 6. Authorization

Ownership should be enforced through the authenticated user.

For example:

```ruby
current_user.prospecting_profiles
```

is preferred to unrestricted global lookup.

Resources should not be exposed across users.

Every user-owned resource needs authorization tests.

---

# 7. Current Controller Architecture

Relevant controllers include concepts such as:

```text
Api::V1::BusinessDiscoveryController
Api::V1::SearchesController
Api::V1::ProspectingProfilesController
```

Existing controllers may include concerns.

Example:

```ruby
include BusinessDiscoveryConcern
```

or:

```ruby
include ProspectingProfilesConcern
```

Do not remove concerns without understanding their purpose.

---

# 8. Service Layer

Bizz-Hunter uses service objects.

Existing examples include:

```text
GooglePlaces::BusinessDiscovery
GooglePlaces::SearchPersistence
GooglePlaces::BusinessDiscoveryAnalysis
SearchQuotaTracker
```

Inspect their actual implementations before creating new services.

---

# 9. Service Naming

Services should follow the existing namespace convention.

For example:

```text
app/services/google_places/
    business_discovery.rb
    search_persistence.rb
    business_discovery_analysis.rb
```

Prospecting Profile services may follow:

```text
app/services/prospecting_profiles/
    create.rb
    update.rb
    destroy.rb
```

AI services may eventually follow:

```text
app/services/ai/
    gemini_client.rb
    prospecting_profile_builder.rb
    outreach_message_generator.rb
```

These are architectural targets; inspect the repository before creating files.

---

# 10. Prospecting Profile Architecture

Relationship:

```text
User
  │
  └── has_many :prospecting_profiles

ProspectingProfile
  │
  └── belongs_to :user
```

Conceptual database structure:

```text
users
  │
  │ 1:N
  ▼
prospecting_profiles
```

A profile contains the user's prospecting strategy.

---

# 11. Search Architecture

Search should remain separate from Prospecting Profiles.

Concept:

```text
Prospecting Profile
        │
        │ defines intent
        ▼
Search
        │
        │ defines discovery constraints
        ▼
Google Places
        │
        ▼
Business Results
```

A search may contain information such as:

* query
* business_type
* location
* filters
* results_count
* timestamps
* associated business results

Inspect the existing schema before modifying these structures.

---

# 12. Google Places Integration

Google Places is the initial business discovery provider.

Concept:

```text
Frontend
   ↓
Rails Business Discovery API
   ↓
GooglePlaces::BusinessDiscovery
   ↓
Google Places
   ↓
Normalized Business Results
   ↓
Frontend
```

Google Places integration should remain isolated.

Do not put Google API calls directly inside controllers.

---

# 13. Search Persistence

Search persistence should remain separate from business discovery.

Concept:

```text
Business Discovery
        ↓
Business Results
        ↓
Search Persistence
        ↓
Database
```

Existing services should be reused where appropriate.

Do not duplicate persistence logic.

---

# 14. Analytics Architecture

Analytics should generally be derived from persisted data.

Concept:

```text
Searches
   +
Search Results
   +
Prospects
   ↓
Database Queries / Services
   ↓
Analytics API
   ↓
Dashboard
```

Do not persist every calculated chart number unless required.

---

# 15. Opportunity Scoring Architecture

Future architecture:

```text
             ┌─────────────────────┐
             │ Prospecting Profile │
             └──────────┬──────────┘
                        │
                        │
             ┌──────────▼──────────┐
             │   Business Data     │
             └──────────┬──────────┘
                        │
                        ▼
             ┌─────────────────────┐
             │ Opportunity Score   │
             │ Calculator          │
             └──────────┬──────────┘
                        │
              ┌─────────┼──────────┐
              ▼         ▼          ▼
            Score      Tier      Factors
```

Recommended future location:

```text
app/services/opportunity_score_calculator.rb
```

The scoring service should be deterministic.

---

# 16. Scoring Data

Scoring should use factual business data.

Potential signals:

```text
website_available
phone_available
whatsapp_available
rating
review_count
business_type
location
```

Do not invent information.

Do not score based on AI assumptions unless the relevant fact has been independently verified.

---

# 17. AI Architecture

AI should sit behind Rails.

Correct:

```text
Frontend
   ↓
Rails
   ↓
AI Service
   ↓
Gemini
```

Incorrect:

```text
Frontend
   ↓
Gemini API directly
```

API keys must never be exposed to browser clients.

---

# 18. AI Provider Abstraction

AI should be replaceable.

Concept:

```text
Application
    ↓
AI Service
    ↓
Gemini
```

Later:

```text
Application
    ↓
AI Service
    ↓
OpenAI
```

The rest of the application should not be tightly coupled to a provider-specific implementation.

---

# 19. AI Profile Builder

Future architecture:

```text
User Description
       ↓
ProspectingProfiles::AI Builder
       ↓
Gemini
       ↓
Structured JSON
       ↓
Rails Validation
       ↓
ProspectingProfile
```

AI output must be validated before persistence.

---

# 20. Outreach Message Architecture

Future flow:

```text
Prospecting Profile
        +
Business Facts
        +
Opportunity Factors
        ↓
AI Message Generator
        ↓
Draft Message
        ↓
User Review/Edit
        ↓
WhatsApp
```

AI must not invent business facts.

---

# 21. WhatsApp Architecture

Business phone number:

```text
Business Phone
      ↓
Normalize to international format
      ↓
wa.me URL
```

Example:

```text
https://wa.me/2348012345678
```

Message version:

```text
https://wa.me/2348012345678?text=<encoded_message>
```

---

# 22. QR Architecture

Business card:

```text
Business
   ↓
Phone Number
   ↓
International Number
   ↓
WhatsApp URL
   ↓
QR Generator
   ↓
Rendered QR
```

QR generation should be deterministic.

The QR should encode the actual URL.

---

# 23. Frontend Architecture

Current frontend code has historically used:

```text
public/js/
```

with modules/components such as:

```text
app.js
api.js
state.js
qrcode_generator.js
components/
features/
utils/
```

The exact structure must always be inspected before modifying it.

Do not assume a React architecture if the current application is using another frontend arrangement.

---

# 24. Frontend State

Existing frontend state management should be preserved.

Previously a global state concept existed around:

```text
window.BizzState
```

Again, inspect the current implementation before using or modifying it.

Do not introduce a new state-management framework unnecessarily.

---

# 25. API Response Architecture

Existing APIs commonly use:

```json
{
  "success": true,
  "data": {}
}
```

and errors such as:

```json
{
  "success": false,
  "message": "...",
  "errors": {}
}
```

New APIs should follow the project's actual existing conventions.

---

# 26. Serialization

The application may use serializers such as:

```text
ProspectingProfileSerializer
```

Use the project's established serialization approach.

Do not expose unnecessary internal fields.

---

# 27. Database Source of Truth

PostgreSQL is the source of truth for persistent application data.

Frontend state is not a replacement for database persistence.

Persist entities such as:

```text
User
Search
SearchResult
Prospect
ProspectingProfile
```

according to the actual current schema.

---

# 28. Future Lead Architecture

Long-term:

```text
User
 │
 ├── Prospecting Profiles
 │
 ├── Searches
 │
 ├── Prospects
 │
 └── Outreach / Activities
```

Potential future:

```text
Prospect
   ↓
Outreach
   ↓
Follow-up
   ↓
Pipeline
   ↓
Conversion
```

Do not implement this prematurely.

---

# 29. Testing Architecture

Tests should exist at multiple levels:

```text
Model
 ↓
Service
 ↓
Request/API
 ↓
Integration
```

External APIs should be mocked/stubbed appropriately in tests.

Do not make the test suite dependent on unnecessary live external API calls.

---

# 30. Architecture Golden Rule

```text
Thin Controllers
      ↓
Focused Services
      ↓
Validated Models
      ↓
PostgreSQL
```

External integrations:

```text
Services
   ↓
Google Places / Gemini / WhatsApp-related URL generation
```

AI interprets intent and generates content.

Backend logic owns facts, authorization, persistence, and deterministic scoring.

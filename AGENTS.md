# Bizz-Hunter — AI Coding Agent Instructions

## 1. Purpose of This File

This file is the primary instruction and context file for AI coding agents working on Bizz-Hunter.

This project may be developed using different AI coding agents, including:

* Antigravity
* GitHub Copilot
* Cursor
* Claude Code
* Gemini
* Other coding agents

Every coding agent MUST read this file before making changes.

The agent should also read:

1. `PROJECT_CONTEXT.md`
2. `ARCHITECTURE.md`
3. `DEVELOPMENT_RULES.md`
4. `TASKS.md`

before starting significant work.

---

# 2. Project Identity

**Project:** Bizz-Hunter

**Type:** Business discovery and prospecting SaaS

**Primary backend:** Ruby on Rails API

**Database:** PostgreSQL

**Primary business discovery source:** Google Places

**Authentication:** Devise / JWT-based authentication

Bizz-Hunter helps users discover businesses that may be good prospects for the products or services they sell.

The long-term goal is not to become another generic business directory.

The core product direction is:

> Bizz-Hunter does not just find businesses. It helps users identify which businesses are worth contacting and why.

---

# 3. Core Product Flow

The long-term product architecture is:

```text
User
  ↓
Prospecting Profiles
  ↓
Select Prospecting Profile
  ↓
Search
  ↓
Location + Business Type + Filters
  ↓
Google Places
  ↓
Business Data
  ↓
Personalized Opportunity Scoring
  ↓
Opportunity Reasons
  ↓
AI Outreach Message
  ↓
User Reviews/Edits Message
  ↓
WhatsApp / QR
```

Do not collapse these concepts into one feature.

A Prospecting Profile defines the user's prospecting strategy.

A Search defines what businesses the user wants to investigate.

Business data provides factual signals.

The scoring engine determines opportunity.

AI helps interpret user intent and generate outreach content.

---

# 4. CRITICAL DEVELOPMENT RULE

Before implementing anything:

> INSPECT THE EXISTING CODEBASE FIRST.

Do not assume:

* a model exists
* a service exists
* a controller exists
* a route exists
* a database field exists
* a library is installed
* a frontend framework is being used
* a particular naming convention is being used

Search the codebase and verify.

If something already exists, extend it instead of creating a duplicate.

---

# 5. Preserve Existing Functionality

Bizz-Hunter is an actively developed application.

Existing functionality is considered protected unless the task explicitly requires changing it.

Do not casually modify:

* authentication
* Google Places integration
* business discovery
* existing search behavior
* existing analytics
* QR functionality
* WhatsApp functionality
* existing frontend behavior
* existing API contracts
* existing database structures

When implementing a new feature, make the smallest safe change required.

Avoid unrelated refactoring.

---

# 6. Architecture Principles

Bizz-Hunter uses a layered architecture.

Preferred direction:

```text
HTTP Request
     ↓
Controller
     ↓
Service Object
     ↓
Model / External API
     ↓
Database
```

Controllers should primarily handle:

* authentication
* parameter handling
* authorization/resource lookup
* calling services
* rendering responses
* HTTP status codes

Business logic should live in services.

Do not place complex business logic inside controllers.

Follow existing service-object conventions found in the repository.

---

# 7. Service Objects

Bizz-Hunter already uses service-oriented patterns.

Examples include concepts/services such as:

```text
GooglePlaces::BusinessDiscovery
GooglePlaces::SearchPersistence
GooglePlaces::BusinessDiscoveryAnalysis
SearchQuotaTracker
```

These are examples of existing architecture and MUST be inspected before creating new services.

When adding business logic:

1. Inspect existing services.
2. Follow their naming.
3. Follow their method signatures.
4. Follow their error/result conventions.
5. Keep services focused.

Do not introduce a completely different service architecture.

---

# 8. Controllers

Controllers should remain thin.

Bad:

```ruby
def create
  profile = current_user.prospecting_profiles.build(params)

  if profile.save
    # complex business logic
  end
end
```

Preferred concept:

```text
Controller
   ↓
ProspectingProfiles::Create
   ↓
ProspectingProfile
```

The exact implementation must follow the existing service conventions.

Controllers should not contain:

* scoring algorithms
* AI prompt construction
* complex business rules
* external API orchestration
* large data transformations

---

# 9. Authentication and Authorization

Bizz-Hunter uses authenticated users.

Never trust a client-provided `user_id`.

Resources belonging to a user must always be scoped through the authenticated user.

Preferred concept:

```ruby
current_user.prospecting_profiles
```

rather than:

```ruby
ProspectingProfile.find(params[:id])
```

A user must never be able to access another user's:

* Prospecting Profiles
* Searches
* Prospects
* private analytics
* private data

Any new resource must include ownership/authorization tests.

---

# 10. Prospecting Profiles

Prospecting Profiles are persistent user configurations.

Relationship:

```text
User
  └── has_many :prospecting_profiles
```

A profile contains concepts such as:

* name
* service_description
* service
* target_businesses
* opportunity_signals
* contact_signals
* is_default

Example:

```json
{
  "name": "Website Development for Restaurants",
  "service_description": "I build modern websites for small businesses.",
  "service": "Website Development",
  "target_businesses": [
    "restaurants",
    "hotels"
  ],
  "opportunity_signals": [
    "no_website",
    "outdated_website"
  ],
  "contact_signals": [
    "phone_available",
    "whatsapp_available"
  ],
  "is_default": true
}
```

Do not hard-code services.

Users may sell any service.

---

# 11. Prospecting Profile vs Search

These are different concepts.

A Prospecting Profile answers:

> What am I selling and what makes a business valuable to me?

A Search answers:

> Which businesses do I want to investigate?

Example:

```text
Prospecting Profile:
Website Development for Restaurants

Search:
Restaurants
Abuja
Rating >= 4.0
No website
Phone available
```

Eventually:

```text
Prospecting Profile
        +
Search
        +
Business Data
        ↓
Opportunity Score
```

Do not merge these concepts.

---

# 12. AI Architecture

AI will be used selectively.

Initial AI responsibilities:

### 1. Prospecting Profile Builder

Natural language:

> I build websites for restaurants and small hotels.

becomes structured data:

```json
{
  "service": "Website Development",
  "target_businesses": [
    "restaurants",
    "small hotels"
  ],
  "opportunity_signals": [
    "no_website",
    "outdated_website"
  ],
  "contact_signals": [
    "phone_available",
    "whatsapp_available"
  ]
}
```

### 2. Outreach Message Generator

AI receives:

* prospecting profile
* business facts
* opportunity reasons

and generates a personalized outreach message.

---

# 13. AI Must Not Control Business Scoring

Do not ask AI to calculate the final opportunity score.

AI interprets intent.

The backend scoring engine determines the score.

Preferred architecture:

```text
User Service Description
        ↓
AI
        ↓
Prospecting Profile
        ↓
Backend Scoring Engine
        ↓
Score + Factors
```

This makes scoring:

* deterministic
* explainable
* consistent
* testable
* cheaper
* easier to debug

---

# 14. AI Provider

The initial preferred AI provider is **Google Gemini**.

Architecture should keep the provider replaceable.

Preferred concept:

```text
Rails
  ↓
AI Service Layer
  ↓
Gemini
```

Potential structure:

```text
app/services/ai/
├── gemini_client.rb
├── prospecting_profile_builder.rb
└── outreach_message_generator.rb
```

Do not expose AI API keys to the frontend.

All AI requests should go through the Rails backend.

---

# 15. Personalized Opportunity Scoring

The scoring engine should eventually evaluate:

```text
Prospecting Profile
        +
Business Data
        ↓
OpportunityScoreCalculator
        ↓
Score
Tier
Factors
```

Example:

```json
{
  "score": 92,
  "tier": "high",
  "factors": [
    {
      "signal": "no_website",
      "points": 30,
      "reason": "This business does not currently have a website."
    },
    {
      "signal": "whatsapp_available",
      "points": 15,
      "reason": "The business can be contacted through WhatsApp."
    }
  ]
}
```

The score measures **prospecting opportunity**, not business quality.

A business can have a high opportunity score without being a "better" business.

Scoring must eventually be personalized to the selected Prospecting Profile.

---

# 16. WhatsApp

WhatsApp is a major contact channel.

When a valid international phone number exists, Bizz-Hunter can generate:

```text
https://wa.me/<international_number>
```

Phone number formatting must use international digits only:

```text
2348012345678
```

Not:

```text
+234 801 234 5678
```

For personalized outreach, the future URL may contain:

```text
https://wa.me/<number>?text=<encoded_message>
```

Do not automatically send messages.

The user should review/edit the message and choose to open WhatsApp.

---

# 17. QR Codes

Every business card with a valid phone number should eventually display a permanent QR code that opens WhatsApp.

QR payload:

```text
https://wa.me/<international_number>
```

Requirements:

* high contrast
* black modules on white
* adequate quiet zone
* square modules
* no distortion
* no stretching
* no rotation
* no unnecessary logos inside QR
* mobile-scannable
* compatible with modern phone cameras

The QR should not display a phone number beside it merely as part of the QR component.

QR generation must use the actual business phone number.

Do not assume that a QR library producing an image means the final rendered QR is scannable. Test the actual rendered output when debugging QR issues.

---

# 18. Frontend Protection

The frontend already contains an established Bizz-Hunter UI.

Do not redesign it unless explicitly requested.

Existing frontend characteristics include:

* premium B2B SaaS appearance
* light theme
* dark theme
* blue visual identity
* responsive layout
* subtle animations
* business cards
* dashboards
* search interface
* analysis views
* QR/WhatsApp functionality

When adding frontend features:

> Extend the existing design language instead of replacing it.

---

# 19. JavaScript Architecture

The frontend has previously been organized approximately as:

```text
public/js/
├── app.js
├── api.js
├── qrcode_generator.js
├── state.js
├── utils/
│   ├── formatters.js
│   └── toast.js
├── components/
│   ├── business-card.js
│   ├── modal.js
│   └── charts.js
└── features/
    ├── auth.js
    ├── search.js
    ├── prospects.js
    ├── dashboard.js
    └── analysis.js
```

Inspect the actual repository before relying on this structure.

Do not assume these files still have exactly the same contents.

---

# 20. Existing API Principles

Existing APIs generally use response structures similar to:

```json
{
  "success": true,
  "data": {}
}
```

or:

```json
{
  "success": false,
  "message": "...",
  "errors": {}
}
```

Follow the actual conventions in the repository.

Do not introduce inconsistent response formats without a strong reason.

---

# 21. Database Principles

PostgreSQL is the source of truth.

Do not rely on:

* localStorage
* sessionStorage
* frontend state
* browser memory

for persistent business data.

Persist underlying entities and derive analytics from them.

Avoid creating tables that merely store chart numbers.

---

# 22. Analytics

Analytics should generally be calculated from persisted business/search/prospect data.

Do not create a giant table containing:

```text
businesses_found
high_opportunities
no_website
whatsapp_available
```

as permanent duplicated statistics unless there is a specific performance requirement.

Prefer database aggregation.

---

# 23. Testing Requirements

Every meaningful backend feature must include tests.

At minimum:

* model tests
* service tests
* request/controller tests where appropriate
* authorization tests
* regression tests

Never delete tests to make a feature pass.

Never weaken tests simply because implementation is difficult.

After significant backend changes:

```text
Run targeted tests
        ↓
Run related tests
        ↓
Run full Rails suite
```

---

# 24. Agent Workflow

Every AI agent should follow this process:

### Step 1

Read:

```text
AGENTS.md
PROJECT_CONTEXT.md
ARCHITECTURE.md
DEVELOPMENT_RULES.md
TASKS.md
```

### Step 2

Inspect the existing implementation.

### Step 3

Identify what already exists.

### Step 4

Plan the smallest required change.

### Step 5

Implement only the requested task.

### Step 6

Run tests.

### Step 7

Check for regressions.

### Step 8

Report exactly what changed.

---

# 25. Task Boundaries

Bizz-Hunter is being developed incrementally.

Do not implement future tasks just because they are visible in `TASKS.md`.

If the user says:

> Implement Task 4

implement Task 4 only.

Do not automatically implement Tasks 5–9.

---

# 26. When Uncertain

If an architectural decision is unclear:

1. Inspect the codebase.
2. Look for existing patterns.
3. Prefer consistency.
4. Avoid speculative refactoring.

If making a potentially breaking assumption is unavoidable:

STOP and explain the issue before making the risky change.

---

# 27. Final Agent Report

Every completed task should report:

* files created
* files modified
* architecture used
* important decisions
* tests added
* tests executed
* test results
* known issues
* remaining work

Do not claim a test passed unless it was actually executed.

Do not claim a feature works merely because the code compiles.

---

# 28. Golden Rule

> **Understand the existing Bizz-Hunter architecture first. Make the smallest safe change. Keep controllers thin. Keep business logic in services. Keep AI replaceable. Keep scoring deterministic. Protect existing functionality. Test everything.**

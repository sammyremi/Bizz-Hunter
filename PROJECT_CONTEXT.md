# Bizz-Hunter — Project Context

## 1. Overview

Bizz-Hunter is a business discovery and prospecting platform.

Its purpose is to help freelancers, agencies, sales professionals, marketers, entrepreneurs, and other service providers find businesses they may want to contact.

The product is evolving from a simple business search tool into a personalized prospecting intelligence platform.

---

# 2. The Problem

Finding potential business clients manually is slow.

A user may need to:

1. Search Google Maps.
2. Open businesses one by one.
3. Check whether they have a website.
4. Find their phone number.
5. Determine whether WhatsApp is available.
6. Decide whether the business is actually worth contacting.
7. Write an outreach message.
8. Repeat this process dozens or hundreds of times.

Bizz-Hunter is intended to compress this workflow into one platform.

---

# 3. Core Value Proposition

The long-term positioning is:

> **Bizz-Hunter doesn't just find businesses. It tells you which businesses are worth contacting and why.**

The product should help users move from:

```text
Search
```

to:

```text
Search → Evaluate → Prioritize → Contact
```

---

# 4. Target Users

Primary users include:

* freelancers
* web developers
* software developers
* digital agencies
* marketing agencies
* sales professionals
* marketers
* entrepreneurs
* service businesses

Examples:

### Web Developer

Wants to find:

* restaurants without websites
* hotels with poor/outdated websites
* businesses with phone numbers
* businesses reachable on WhatsApp

### Cleaning Company

May care more about:

* larger businesses
* offices
* hotels
* restaurants
* multiple locations

### SEO Consultant

May care about:

* businesses with websites
* poor online presence
* weak search visibility
* businesses in competitive categories

The system must eventually adapt to different services.

---

# 5. Existing Search Concept

Users can search businesses using factors such as:

* country
* state/region
* city
* town/area
* business type
* rating
* website availability
* phone availability
* WhatsApp availability

The initial business discovery source is Google Places.

Current architecture:

```text
Google Places
     ↓
Bizz-Hunter Rails Backend
     ↓
Bizz-Hunter Frontend
```

---

# 6. Business Data

Relevant business information includes:

* business name
* Google Place ID
* business type
* address
* city
* state
* country
* phone number
* website
* rating
* review count
* website availability
* phone availability
* WhatsApp availability

The application must distinguish between:

```text
Business quality
```

and:

```text
Prospecting opportunity
```

These are not the same.

---

# 7. Prospecting Profiles

The major product evolution is the introduction of Prospecting Profiles.

A Prospecting Profile describes:

> What the user sells, who they want to sell it to, and what business signals make a prospect valuable.

A user can have multiple profiles.

Example:

```text
Samuel
│
├── Website Development → Restaurants
│
├── Website Development → Hotels
│
└── E-commerce Development → Fashion Businesses
```

This is important because users may sell multiple services or target different markets.

---

# 8. Prospecting Profile Fields

The initial profile concept includes:

```text
name
service_description
service
target_businesses
opportunity_signals
contact_signals
is_default
```

Example:

```json
{
  "name": "Website Development for Restaurants",
  "service_description": "I build modern websites for restaurants and small businesses.",
  "service": "Website Development",
  "target_businesses": [
    "restaurants"
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

---

# 9. Prospecting Profile Creation

Eventually, the user should be able to describe their service naturally.

Example:

> I build modern websites for restaurants and hotels.

AI can convert this into a structured Prospecting Profile.

However, AI must not blindly determine the user's target if the user has not provided it.

For example:

> I build websites.

This identifies the service:

```text
Website Development
```

but does not necessarily identify the target market.

The user should be able to specify/edit the target.

---

# 10. AI-Generated Profile

The AI profile builder should eventually return structured JSON.

Example:

```json
{
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
  ]
}
```

The Rails backend must validate AI output before persisting it.

Never trust raw AI output.

---

# 11. Search + Profile

A Prospecting Profile does not replace search filters.

Instead:

```text
Prospecting Profile
+
Search Parameters
```

work together.

Example:

```text
Profile:
Website Development for Restaurants

Search:
Business type = Restaurant
Location = Abuja
Rating >= 4.0
Website = No
Phone = Yes
```

The profile provides the prospecting strategy.

The search provides the business discovery constraints.

---

# 12. Personalized Opportunity Scoring

The core future feature is personalized opportunity scoring.

Architecture:

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

A web developer may consider:

```text
No website = extremely valuable
```

A cleaning company may not.

Therefore, scoring cannot be universally hard-coded around one service.

---

# 13. Score Meaning

The score represents:

> How promising this business is as a prospect for the selected user's service.

It does NOT represent:

* business quality
* financial performance
* customer satisfaction
* overall business ranking

Example output:

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

---

# 14. Deterministic Scoring

The initial scoring engine should be deterministic.

Example signals:

```text
No website
Phone available
WhatsApp available
Rating
Review count
Other verified business signals
```

Potential initial scoring structure:

```text
No website             +30
Phone available        +20
WhatsApp available     +15

Rating:
4.5+                   +15
4.0–4.49               +12
3.5–3.99               +8
3.0–3.49               +4
Below 3                +0

Reviews:
0–10                   +0
11–50                  +2
51–100                 +4
101–500                +7
500+                   +10
```

The score can be normalized/capped at 100.

Potential tiers:

```text
80–100 = High
50–79  = Medium
0–49   = Low
```

These rules may evolve as the product develops.

Do not hard-code them into the ProspectingProfile model.

---

# 15. AI + Scoring Separation

The correct separation is:

```text
User describes service
       ↓
AI interprets intent
       ↓
Prospecting Profile
       ↓
Business Search
       ↓
Verified Business Facts
       ↓
Deterministic Scoring
       ↓
Opportunity Score
       ↓
AI generates outreach
```

AI should not be the source of factual business information.

AI should not invent business facts.

---

# 16. Outreach Messages

Eventually Bizz-Hunter will generate personalized outreach messages.

Input:

```text
Prospecting Profile
+
Business Facts
+
Opportunity Factors
```

Output:

```text
Personalized WhatsApp message
```

Example:

```text
Hi ABC Restaurant, I noticed your business currently doesn't appear to have a website. I help restaurants build modern websites that make it easier for customers to discover their menu and contact them. I'd be happy to show you what I could build for your business.
```

The user should be able to:

* preview
* edit
* regenerate
* choose tone
* choose length
* open WhatsApp

---

# 17. WhatsApp

Bizz-Hunter should use WhatsApp as a contact channel.

The application should generate:

```text
https://wa.me/<international_number>
```

For personalized messages:

```text
https://wa.me/<international_number>?text=<encoded_message>
```

The user should remain in control of sending the message.

No automatic mass messaging should be introduced as part of the core workflow.

---

# 18. QR Code Workflow

Each business card with a valid phone number should eventually have a QR code.

Scanning the QR should open:

```text
WhatsApp
```

for that business number.

The QR should encode the WhatsApp URL directly.

Future enhancement:

```text
QR
  ↓
WhatsApp
  ↓
Personalized pre-filled message
```

---

# 19. Dashboard

The dashboard is intended to become the user's prospecting command center.

Existing/current concepts include:

* Businesses Found
* High-Opportunity Prospects
* No Website
* WhatsApp Available
* Saved Prospects
* Opportunity Breakdown
* Discovery Trend
* Top Business Types

Analytics should be derived from persisted data.

---

# 20. Analysis

The analysis system is intended to help users understand search results.

Concepts include:

* search context
* KPI cards
* opportunity breakdown
* opportunity score
* website opportunity
* contactability
* business type distribution
* location distribution
* rating distribution
* top opportunities

Charts should eventually be actionable/filterable.

---

# 21. Product Evolution

The product is evolving through stages.

### Stage 1

Reliable business discovery.

```text
Google Places
↓
Search
↓
Business Results
```

### Stage 2

Prospecting Profiles.

```text
User
↓
Service/Target
↓
Prospecting Profile
```

### Stage 3

Personalized opportunity intelligence.

```text
Profile
+
Business
↓
Opportunity Score
```

### Stage 4

AI-assisted outreach.

```text
Opportunity
↓
AI Message
↓
User Review
↓
WhatsApp
```

### Stage 5

Lead management.

Potential future capabilities:

* saved prospects
* CRM
* contact history
* outreach tracking
* follow-ups
* pipeline
* conversion tracking

Do not implement future stages unless explicitly requested.

---

# 22. Product Philosophy

Bizz-Hunter should become an **intelligence layer over business discovery**.

The user should not have to manually inspect hundreds of businesses.

The system should progressively answer:

```text
Who should I contact?
Why should I contact them?
How should I contact them?
What should I say?
```

while keeping factual claims verifiable and the user in control.

---

# 23. Current Development Philosophy

The application should be developed incrementally.

Each task should:

* have a clear boundary
* preserve existing functionality
* be tested
* be reviewed before the next task

Do not combine unrelated features into one implementation.

---

# 24. Long-Term Vision

The eventual Bizz-Hunter experience should feel like:

```text
"I tell Bizz-Hunter what I sell."

        ↓

"It understands who is likely to need it."

        ↓

"I choose where I want to prospect."

        ↓

"It finds the businesses."

        ↓

"It tells me which ones are strongest prospects."

        ↓

"It explains why."

        ↓

"It helps me contact them."

        ↓

"I manage those leads inside Bizz-Hunter."
```

That is the long-term product direction.

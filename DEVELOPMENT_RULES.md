# Bizz-Hunter — Development Rules

## 1. General Rule

Before changing anything:

> Understand the existing implementation first.

Never code based only on assumptions.

---

# 2. Inspect Before Creating

Before creating a:

* model
* migration
* controller
* service
* serializer
* concern
* route
* frontend module

search the repository first.

If it already exists, reuse or extend it.

Never create duplicate functionality.

---

# 3. Small Changes Only

Implement only what the current task requires.

Do not combine:

```text
Task 3 + Task 4 + Task 5
```

into one implementation.

Future tasks are intentionally separated so each stage can be tested.

---

# 4. Protect Existing Features

Do not modify unrelated functionality.

Especially protect:

* authentication
* Google Places
* search
* analytics
* QR
* WhatsApp
* existing API responses
* existing frontend
* existing database structures

---

# 5. Controllers Must Be Thin

Controllers should not contain substantial business logic.

Controllers should:

```text
Authenticate
Authorize
Receive parameters
Call service
Render response
```

Business logic belongs in services.

---

# 6. Service Objects

Use service objects for meaningful business operations.

Before creating a service:

1. Inspect existing services.
2. Follow naming conventions.
3. Follow result/error conventions.
4. Keep the service focused.

Do not create services unnecessarily.

---

# 7. Models

Models should primarily handle:

* associations
* validations
* database behavior
* simple domain methods

Do not turn models into massive business-logic containers.

---

# 8. Authorization

Never trust client ownership fields.

Bad:

```ruby
ProspectingProfile.find(params[:id])
```

Preferred:

```ruby
current_user.prospecting_profiles.find(params[:id])
```

A user must never access another user's data.

Always add authorization tests.

---

# 9. Strong Parameters

Only accept fields that the client is actually allowed to modify.

Never allow:

```text
user_id
created_at
updated_at
```

from normal client input.

---

# 10. Validation

Validate user-controlled and AI-generated data.

Do not use unnecessarily restrictive enumerations for flexible concepts such as services.

For example, do not hard-code:

```text
Website Development
SEO
Graphic Design
```

as the only valid services.

Users can sell arbitrary services.

---

# 11. AI Safety

AI output is untrusted input.

Always:

```text
AI output
   ↓
Parse
   ↓
Validate
   ↓
Normalize
   ↓
Persist
```

Never:

```text
AI output
   ↓
Database
```

without validation.

---

# 12. AI Must Not Invent Facts

AI must not fabricate:

* business information
* phone numbers
* websites
* ratings
* reviews
* addresses
* WhatsApp availability

Business facts must come from verified application data.

---

# 13. AI API Keys

Never place AI API keys in:

* frontend JavaScript
* HTML
* public files
* client-side environment variables

AI requests must go through Rails.

---

# 14. Scoring Rules

Opportunity scoring should be deterministic.

Do not ask an LLM:

> Give this business a score from 0–100.

Instead:

```text
Profile
+
Verified business signals
↓
Scoring service
↓
Score
```

This keeps scoring reproducible.

---

# 15. Scoring Must Be Personalized

Never assume the same signal has the same value for every user.

A missing website may be extremely valuable to:

```text
Web Developer
```

but less valuable to:

```text
Cleaning Company
```

The selected Prospecting Profile determines what opportunity means.

---

# 16. Database Rules

PostgreSQL is the source of truth.

Do not store important persistent application data only in browser storage.

Do not create duplicate data tables without a clear reason.

---

# 17. Analytics Rules

Prefer calculating analytics from underlying data.

Do not store redundant dashboard statistics unless performance requirements justify it.

---

# 18. API Rules

Follow existing API conventions.

Do not create inconsistent response formats.

Preferred concept:

```json
{
  "success": true,
  "data": {}
}
```

Errors should clearly communicate failure without exposing internal stack traces.

---

# 19. HTTP Status Codes

Use appropriate status codes.

Examples:

```text
200 OK
201 Created
401 Unauthorized
403 Forbidden
404 Not Found
422 Unprocessable Entity
429 Too Many Requests
500 Internal Server Error
```

Follow existing project conventions.

---

# 20. Error Handling

Do not expose:

* stack traces
* API keys
* database credentials
* internal implementation details

to users.

Log useful debugging information appropriately on the backend.

---

# 21. External API Calls

External APIs should be isolated in services.

Do not make Google Places or Gemini calls directly from controllers unless the existing architecture explicitly does so.

---

# 22. Google Places

Do not modify existing Google Places behavior unless the task explicitly requires it.

Reuse existing integration services.

Do not create a second Google Places client without inspecting the existing implementation.

---

# 23. WhatsApp

Phone numbers must be normalized correctly before generating WhatsApp URLs.

Use:

```text
international digits only
```

Example:

```text
2348012345678
```

not:

```text
+234 801 234 5678
```

---

# 24. QR

Do not assume a generated QR is automatically usable.

When QR functionality changes:

* verify encoded payload
* verify actual rendered QR
* verify quiet zone
* verify dimensions
* verify mobile scanning

Do not add unnecessary visual elements inside the QR.

---

# 25. Frontend

Do not redesign existing screens unless explicitly requested.

When adding UI:

* preserve existing design language
* preserve responsive behavior
* preserve themes
* preserve animations
* preserve existing interactions

---

# 26. JavaScript

Before changing JavaScript:

* inspect script loading order
* inspect global state
* inspect module dependencies
* inspect existing initialization lifecycle

Do not create hidden circular dependencies.

Do not assume a module is loaded before another module without checking.

---

# 27. Regression Prevention

Every significant change should include:

```text
Targeted tests
+
Related tests
+
Full test suite
```

If something worked before the change and breaks afterward:

> Treat it as a regression until proven otherwise.

---

# 28. Do Not Cheat Tests

Never:

* delete failing tests
* skip tests without explanation
* weaken assertions
* mock away the functionality being tested
* claim success without executing tests

---

# 29. Migrations

Before creating a migration:

* inspect schema
* inspect existing migrations
* check whether the column/table already exists
* check naming conventions

Never create duplicate tables.

After migration:

```text
rails db:migrate
```

and verify schema.

---

# 30. Dependencies

Do not add a gem/package unless necessary.

Before adding a dependency:

1. Check whether the project already has an equivalent.
2. Check whether the functionality can be implemented with existing dependencies.
3. Prefer the smallest reliable dependency.

---

# 31. Refactoring

Refactoring is allowed only when it directly supports the requested task.

Do not use a feature request as an excuse to rewrite unrelated code.

If a major architectural problem is discovered:

* document it
* explain the risk
* propose a separate task

---

# 32. Documentation

When architecture changes significantly, update:

* `AGENTS.md`
* `ARCHITECTURE.md`
* `TASKS.md`

when appropriate.

Do not let documentation become misleading.

---

# 33. Task Completion

A task is complete only when:

```text
Implementation
+
Tests
+
Regression verification
+
Documentation/report
```

are complete.

---

# 34. Agent Final Report

Every agent should report:

```text
Files created:
Files modified:

Implementation:
- ...

Tests:
- ...

Full suite:
- ...

Potential issues:
- ...

Next task:
- ...
```

Never claim something was tested if it was not.

---

# 35. Golden Rule

> Make the smallest safe change that solves the requested problem while remaining consistent with the existing Bizz-Hunter architecture.

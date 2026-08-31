# Bizz-Hunter — Worldwide Location & Prospecting Application

Bizz-Hunter is a Rails 8 + PostgreSQL application for discovering, evaluating, and contacting business prospects worldwide.

## 📌 Worldwide Location System Setup

The application features a production-ready, idempotent worldwide location engine powered by **GeoNames** data with PostgreSQL trigram search indexing.

### Developer Setup from Scratch

```bash
# 1. Install dependencies
bundle install

# 2. Setup PostgreSQL database and run migrations
bin/rails db:create
bin/rails db:migrate

# 3. Seed initial worldwide location dataset
bin/rails db:seed

# 4. Start application server
bin/rails server -p 3000
```

---

## 🗺️ Location Importer Commands

Location tasks allow downloading and updating the complete worldwide dataset directly from **GeoNames.org**:

```bash
# Download latest GeoNames dataset (Default: DATASET=cities15000)
bin/rails locations:download

# Import dataset into PostgreSQL (upsert_all bulk operations)
bin/rails locations:import

# Re-download and update existing database records idempotently
bin/rails locations:update
```

### Dataset Options & Scale

You can control the dataset depth by passing `DATASET`:

- `cities15000` (Default): Populated places with population > 15,000 (~25,000 places worldwide, ~15MB download). Recommended for fast dev & staging.
- `cities5000`: Populated places with population > 5,000 (~80,000 places worldwide).
- `allCountries`: Full worldwide dataset containing millions of places, suburbs, and landmarks (~12,000,000 places).

Example:
```bash
DATASET=cities5000 bin/rails locations:update
```

---

## 🏗️ Architecture & Database Models

- **`Country`** (`countries` table): Stores ISO-2, ISO-3, phone codes, continents, and `geonames_id` (unique index).
- **`AdministrativeDivision`** (`administrative_divisions` table): Multi-level hierarchy (States, Provinces, Regions, Territories, Prefectures, Departments) with self-referencing parent-child relationships.
- **`Place`** (`places` table): Populated places (cities, towns, capitals) with coordinates (lat/lng), timezones, population, and `geonames_id` (unique index).
- **`PlaceName`** (`place_names` table): Alternate local names with PostgreSQL `pg_trgm` trigram indexing for fuzzy search (e.g. searching "München" matches "Munich").
- **Backwards Compatibility Proxies**: `State` maps to `administrative_divisions` and `City` maps to `places`, preserving `country.states` and `state.cities` associations for legacy API contracts.

---

## 📜 Dataset License & Attribution

Geographic data provided by **GeoNames** (https://www.geonames.org/) under the [Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/).

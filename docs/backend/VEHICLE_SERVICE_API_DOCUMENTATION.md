# Vehicle Service — API Documentation

**Base URLs:**
- Production: `https://be.beapp.in/api/vehicle-service`
- Development: `http://localhost:3009`
- Swagger UI: `/api-docs`

**Authentication:** Bearer token in the `Authorization` header for protected routes. Public routes need no auth.

---

## Table of Contents

1. [Vehicle Type Taxonomy (3 tiers)](#vehicle-type-taxonomy)
2. [Vehicle Condition (New / Used)](#vehicle-condition)
3. [Listing-Detail Option Sets](#listing-detail-option-sets)
4. [NEW vs USED — Field Matrix](#new-vs-used-field-matrix)
5. [Display Labels in Responses](#display-labels-in-responses)
6. [Vehicle Creation Flow (Page-wise)](#vehicle-creation-flow)
7. [Reference APIs (Types / Conditions / Options / Seller defaults)](#reference-apis)
8. [Vehicles API](#vehicles-api)
9. [Vehicle Images API](#vehicle-images-api)
10. [Upload API](#upload-api)
11. [Full Vehicle Object Reference](#full-vehicle-object-reference)
12. [Owner Enrichment (Public Reads)](#owner-enrichment)
13. [gRPC Surface (for other services)](#grpc-surface)
14. [Frontend Integration Sequence](#frontend-integration-sequence)
15. [Error Response Format](#error-response-format)

---

## Vehicle Type Taxonomy

The vehicle type is a **three-tier tree**. The user drills down through all three tiers, and **each tier is stored in its own field**:

| Tier | Field | Example | Notes |
|------|-------|---------|-------|
| L1 — Category | `category` | `PASSENGER`, `COMMERCIAL` | The two top-level categories |
| L2 — Sub-category (display group) | `sub_category` | `PASSENGER_2W`, `LCV`, `MHCV` | A group **under** the chosen category |
| L3 — Type (concrete leaf) | `type` | `SCOOTER`, `MINI_TRUCK` | The concrete vehicle **under** the chosen sub_category |

On create, **all three are required** and each must belong to the tier above it. `vehicle_class` is derived server-side as a mirror of `category` (kept for backward compatibility) and is never client-set.

`category`, `sub_category`, `type`, and `condition` are all **immutable** after creation — together they form the vehicle's locked type. To filter the public listing, pass `?category=`, `?sub_category=`, and/or `?type=`; each is an exact, case-normalized match on its own field (filter to a leaf via `?type=`, not `?sub_category=`).

The full tree is served by [`GET /vehicles/types`](#list-vehicle-types) — see that endpoint for the complete value/label/icon listing of every category, sub-category, and type.

---

## Vehicle Condition

`condition` is an independent classification from the type taxonomy: the user picks **`NEW`** or **`USED`** at upload time. It is **required** on create and **immutable** afterwards. The chosen condition drives which listing-detail fields apply (see the [field matrix](#new-vs-used-field-matrix)).

Served by [`GET /vehicles/conditions`](#list-vehicle-conditions).

---

## Listing-Detail Option Sets

Beyond the taxonomy and `NEW`/`USED` condition, the upload form has several "picker" fields whose allowed values are server-controlled. Unknown values are **rejected with `400`**, never bucketed. All option sets are served in one call by [`GET /vehicles/options`](#list-listing-detail-options).

| Field | Flow | Select | Allowed values |
|-------|------|--------|----------------|
| `availability` | NEW | single | `IN_STOCK`, `LIMITED_STOCK`, `PRE_BOOKING` |
| `delivery_time` | NEW | single | `IMMEDIATE`, `DAYS_3`, `DAYS_7`, `DAYS_15` |
| `special_offers` | NEW | **multi** (array) | `EXCHANGE_AVAILABLE`, `FREE_INSURANCE`, `FREE_HELMET`, `CASHBACK_OFFERS`, `ACCESSORIES_INCLUDED`, `EXTENDED_WARRANTY`, `FREE_SERVICE`, `LOW_DOWN_PAYMENT` |
| `ownership` | USED | single | `FIRST_OWNER`, `SECOND_OWNER`, `THIRD_OWNER`, `FOURTH_OWNER`, `FIFTH_PLUS_OWNER` |
| `condition_grade` | USED | single | `GOOD`, `AVERAGE`, `NEEDS_REPAIR` |

> `condition_grade` (the physical grade of a used vehicle) is **independent** of `condition` (`NEW`/`USED`): a USED listing carries both — `condition=USED` **plus** a `condition_grade`.

The enum-coded `fuel_type` and `transmission` fields are validated by the schema itself:
- `fuel_type`: `PETROL`, `DIESEL`, `ELECTRIC`, `CNG`, `HYBRID`, `OTHER`
- `transmission`: `MANUAL`, `AUTOMATIC`, `AMT`, `CVT`

---

## NEW vs USED — Field Matrix

The two upload flows have **mutually exclusive** detail fields. Sending a field that belongs to the *other* flow (with a meaningful value) is **rejected with `400`** — a NEW listing can't carry used-only data, and a USED listing can't carry new-only data.

| Field | NEW | USED | Notes |
|-------|:---:|:---:|-------|
| `availability` | ✅ required | ✖ rejected | |
| `delivery_time` | ✅ required | ✖ rejected | |
| `ex_showroom_price` | ✅ required | ✖ rejected | |
| `on_road_price` | ✅ optional | ✖ rejected | |
| `emi_available` | ✅ optional | ✖ rejected | boolean |
| `down_payment` | ✅ required *if* `emi_available=true` | ✖ rejected | |
| `monthly_emi` | ✅ required *if* `emi_available=true` | ✖ rejected | |
| `special_offers` | ✅ optional | ✖ rejected | multi-select array |
| `manufacturing_year` | ✖ rejected | ✅ required | |
| `registration_year` | ✖ rejected | ✅ required | |
| `registration_no` | ✖ rejected | ✅ required | |
| `ownership` | ✖ rejected | ✅ required | |
| `condition_grade` | ✖ rejected | ✅ required | |
| `expected_price` | ✖ rejected | ✅ required | |
| `km_driven` | ✖ rejected | ✅ required | |
| `is_negotiable` | ✖ rejected | ✅ optional | boolean |
| `color` | ✖ rejected | ✅ optional | |
| `insurance_valid_till` | ✖ rejected | ✅ optional | date |
| `rc_available` | ✖ rejected | ✅ optional | boolean |
| `pollution_certificate` | ✖ rejected | ✅ optional | boolean |
| `service_history` | ✖ rejected | ✅ optional | boolean |

**Shared (either flow):** `name` (always required), `description`, `brand`, `model`, `variant`, `year`, `fuel_type`, `transmission`, `seating_capacity`, `engine_capacity_cc`, `mileage`, `price`, `currency`, `location`, `cover_image`, `images`, `videos`, `seller_name`, `seller_mobile`, `is_active`, `business_id`.

**`description` length cap:** max **2000** chars for NEW, **500** chars for USED (exceeded → `400`).

> **Yes/No toggles are not "required".** `emi_available`, `is_negotiable`, `rc_available`, `pollution_certificate`, and `service_history` all default to `false` — `false` is a valid answer, so they are never enforced as required.

> **`year` mirroring.** On a USED create, when `manufacturing_year` is supplied but `year` is not, the server mirrors `year = manufacturing_year` so the legacy `year` field (and the gRPC `year`) stays meaningful.

---

## Display Labels in Responses

Every vehicle returned by the API (HTTP reads, create/update, image ops) is decorated with human-readable **display labels** alongside the raw codes. The raw codes are kept intact (filters/consumers depend on them); each label is added immediately after its source field. Unknown/legacy values fall back to the raw code, so a label is always present.

| Source field | Added key | Example |
|--------------|-----------|---------|
| `category` | `category_label` | `"PASSENGER"` → `"Passenger"` |
| `sub_category` | `sub_category_label` | `"PASSENGER_2W"` → `"Two Wheeler"` |
| `type` | `type_label` | `"SCOOTER"` → `"Scooter"` |
| `condition` | `condition_label` | `"USED"` → `"Used"` |
| `availability` | `availability_label` | `"IN_STOCK"` → `"In Stock"` |
| `delivery_time` | `delivery_time_label` | `"DAYS_7"` → `"7 Days"` |
| `ownership` | `ownership_label` | `"FIRST_OWNER"` → `"First Owner"` |
| `condition_grade` | `condition_grade_label` | `"GOOD"` → `"Good"` |
| `special_offers` (array) | `special_offers_labels` (array) | `["FREE_INSURANCE"]` → `["Free Insurance"]` |

---

## Vehicle Creation Flow

The **page-wise flow** a frontend follows to list a vehicle and make it publicly discoverable.

```
PAGE 1: Pick Vehicle Type (drill-down, 3 tiers) + Condition + Detail options
  GET /vehicles/types        → category / sub_category / type (the whole tree, one call)
  GET /vehicles/conditions   → condition  (NEW / USED)
  GET /vehicles/options      → availability, delivery_time, special_offers (NEW)
                               ownership, condition_grade (USED)
       category     = top-level `value`   (e.g. "PASSENGER")
       sub_category = group `value`        (e.g. "PASSENGER_2W")
       type         = leaf `value`         (e.g. "SCOOTER")
       (server mirrors `vehicle_class` = `category`)

PAGE 2: Upload Photos / Videos
  For each file: get a pre-signed S3 policy, upload the file, keep publicUrl
    GET /upload/init-v2?fileName=front.jpg&fileType=image/jpeg   (preferred, size-capped)
      └── POST multipart/form-data (fields first, then file) to url
      └── keep returned publicUrl  →  cover_image / images[] / videos[]
    (legacy: GET /upload/init → PUT raw bytes to uploadUrl)

PAGE 3: Vehicle Details + Seller Contact + Submit (Owner)
    GET  /vehicles/seller-defaults     → pre-fill seller_name / seller_mobile
    POST /vehicles/create
      └── owner = authenticated user (server-set, never client-set)
      └── send only the fields valid for the chosen condition (NEW vs USED)

PAGE 4: Vehicle is now live — anyone can browse and view
    GET  /vehicles?category=PASSENGER&pincode=110001
    GET  /vehicles?sub_category=PASSENGER_2W&type=SCOOTER&condition=USED
    GET  /vehicles/get/{id}
```

---

## Reference APIs

### List Vehicle Types

```
GET /vehicles/types
```

Public. No auth. Returns the canonical, server-controlled type taxonomy as a **nested tree**. The top-level `value` is the `category`; its direct children are the `sub_category` display groups; leaf nodes (no `children`) are the selectable `type` values.

**Response (200):**
```json
{
  "status": true,
  "vehicleTypes": [
    {
      "value": "PASSENGER", "label": "Passenger", "icon": "passenger",
      "children": [
        {
          "value": "PASSENGER_2W", "label": "Two Wheeler", "icon": "two-wheeler",
          "children": [
            { "value": "SCOOTER", "label": "Scooter", "icon": "scooter" },
            { "value": "MOTORCYCLE", "label": "Motorcycle", "icon": "motorcycle" },
            { "value": "MOPED", "label": "Moped", "icon": "moped" },
            { "value": "ELECTRIC_2W", "label": "Electric Two Wheeler", "icon": "ev-two-wheeler" },
            { "value": "ELECTRIC_BICYCLE", "label": "Electric Bicycle", "icon": "ev-bicycle" }
          ]
        },
        {
          "value": "PASSENGER_3W", "label": "Three Wheeler", "icon": "three-wheeler",
          "children": [
            { "value": "AUTO_RICKSHAW", "label": "Auto Rickshaw", "icon": "auto-rickshaw" },
            { "value": "ELECTRIC_AUTO_PASSENGER", "label": "Electric Auto Passenger", "icon": "ev-auto" }
          ]
        },
        {
          "value": "PASSENGER_4W", "label": "Four Wheeler", "icon": "four-wheeler",
          "children": [
            { "value": "QUADRICYCLE_PASSENGER", "label": "Quadricycle Passenger", "icon": "quadricycle" },
            { "value": "HATCHBACK", "label": "Hatchback", "icon": "hatchback" },
            { "value": "SEDAN", "label": "Sedan", "icon": "sedan" },
            { "value": "SUV", "label": "SUV", "icon": "suv" },
            { "value": "MUV", "label": "MUV", "icon": "muv" },
            { "value": "PASSENGER_VAN", "label": "Passenger Van", "icon": "van" },
            { "value": "LUXURY_VEHICLE", "label": "Luxury Vehicle", "icon": "luxury" },
            { "value": "ELECTRIC_CAR", "label": "Electric Car", "icon": "ev-car" }
          ]
        }
      ]
    },
    {
      "value": "COMMERCIAL", "label": "Commercial", "icon": "commercial",
      "children": [
        {
          "value": "COMMERCIAL_3W", "label": "Three Wheeler Commercial", "icon": "three-wheeler-cargo",
          "children": [
            { "value": "CARGO_3W", "label": "Cargo Three Wheeler", "icon": "cargo-three-wheeler" },
            { "value": "ELECTRIC_CARGO_3W", "label": "Electric Cargo Three Wheeler", "icon": "ev-cargo-three-wheeler" }
          ]
        },
        {
          "value": "LCV", "label": "Light Commercial Vehicle", "icon": "lcv",
          "children": [
            { "value": "QUADRICYCLE_GOODS", "label": "Quadricycle Goods", "icon": "quadricycle-goods" },
            { "value": "MINI_TRUCK", "label": "Mini Truck", "icon": "mini-truck" },
            { "value": "PICKUP_TRUCK", "label": "Pickup Truck", "icon": "pickup" },
            { "value": "COMMERCIAL_CARGO_VAN", "label": "Commercial Cargo Van", "icon": "cargo-van" }
          ]
        },
        {
          "value": "MHCV", "label": "Medium and Heavy Commercial Vehicle", "icon": "mhcv",
          "children": [
            { "value": "HAULAGE_TRUCK", "label": "Haulage Truck", "icon": "haulage-truck" },
            { "value": "TRACTOR_TRAILER", "label": "Tractor Trailer", "icon": "tractor-trailer" },
            { "value": "LIQUID_TANKER", "label": "Liquid Tanker", "icon": "tanker" },
            { "value": "TIPPER", "label": "Tipper", "icon": "tipper" },
            { "value": "DUMPER", "label": "Dumper", "icon": "dumper" }
          ]
        },
        {
          "value": "BUSES_COACHES", "label": "Buses and Coaches", "icon": "bus",
          "children": [
            { "value": "CITY_BUS", "label": "City Bus", "icon": "city-bus" },
            { "value": "SCHOOL_BUS", "label": "School Bus", "icon": "school-bus" },
            { "value": "STAFF_BUS", "label": "Staff Bus", "icon": "staff-bus" },
            { "value": "INTERCITY_TOURIST_COACH", "label": "Intercity Tourist Coach", "icon": "coach" },
            { "value": "ELECTRIC_BUS", "label": "Electric Bus", "icon": "ev-bus" }
          ]
        },
        {
          "value": "AGRICULTURAL_EQUIPMENT", "label": "Agricultural Equipment", "icon": "agriculture",
          "children": [
            { "value": "TRACTOR", "label": "Tractor", "icon": "tractor" },
            { "value": "POWER_TILLER", "label": "Power Tiller", "icon": "power-tiller" },
            { "value": "HARVESTER", "label": "Harvester", "icon": "harvester" }
          ]
        },
        {
          "value": "CONSTRUCTION_EQUIPMENT", "label": "Construction Equipment", "icon": "construction",
          "children": [
            { "value": "BACKHOE_LOADER", "label": "Backhoe Loader", "icon": "backhoe-loader" },
            { "value": "EXCAVATOR", "label": "Excavator", "icon": "excavator" },
            { "value": "CRANE", "label": "Crane", "icon": "crane" },
            { "value": "ROAD_ROLLER", "label": "Road Roller", "icon": "road-roller" },
            { "value": "COMPACTOR", "label": "Compactor", "icon": "compactor" }
          ]
        },
        {
          "value": "SPECIAL_PURPOSE_VEHICLE", "label": "Special Purpose Vehicle", "icon": "special-purpose",
          "children": [
            { "value": "AMBULANCE", "label": "Ambulance", "icon": "ambulance" },
            { "value": "FIRE_TENDER", "label": "Fire Tender", "icon": "fire-tender" },
            { "value": "DEFENSE_VEHICLE", "label": "Defense Vehicle", "icon": "defense" },
            { "value": "WASTE_MANAGEMENT_VEHICLE", "label": "Waste Management Vehicle", "icon": "waste-management" },
            { "value": "TOW_TRUCK", "label": "Tow Truck", "icon": "tow-truck" }
          ]
        }
      ]
    }
  ]
}
```

> Send the **top-level** `value` (e.g. `"PASSENGER"`) as `category`, the **group** `value` (e.g. `"PASSENGER_2W"`) as `sub_category`, and the **leaf** `value` (e.g. `"SCOOTER"`) as `type` when creating a vehicle. All three are **required** on create and must belong to the tier above; a mismatch, the wrong tier, or an unknown value is **rejected with `400`**.

---

### List Vehicle Conditions

```
GET /vehicles/conditions
```

Public. No auth. Returns the selectable condition options for the upload picker.

**Response (200):**
```json
{
  "status": true,
  "conditions": [
    { "value": "NEW",  "label": "New",  "icon": "new" },
    { "value": "USED", "label": "Used", "icon": "used" }
  ]
}
```

> Send the chosen `value` (`NEW` / `USED`) as `condition` on create. **Required** on create and **immutable** afterwards.

---

### List Listing-Detail Options

```
GET /vehicles/options
```

Public. No auth. Returns **every** non-taxonomy picker in one call so the upload form can render all detail dropdowns without extra round-trips. Each item is `{ value, label, icon }`.

**Response (200):**
```json
{
  "status": true,
  "options": {
    "availability": [
      { "value": "IN_STOCK", "label": "In Stock", "icon": "in-stock" },
      { "value": "LIMITED_STOCK", "label": "Limited Stock", "icon": "limited-stock" },
      { "value": "PRE_BOOKING", "label": "Pre Booking", "icon": "pre-booking" }
    ],
    "delivery_time": [
      { "value": "IMMEDIATE", "label": "Immediate", "icon": "immediate" },
      { "value": "DAYS_3", "label": "3 Days", "icon": "days-3" },
      { "value": "DAYS_7", "label": "7 Days", "icon": "days-7" },
      { "value": "DAYS_15", "label": "15 Days", "icon": "days-15" }
    ],
    "ownership": [
      { "value": "FIRST_OWNER", "label": "First Owner", "icon": "owner-1" },
      { "value": "SECOND_OWNER", "label": "Second Owner", "icon": "owner-2" },
      { "value": "THIRD_OWNER", "label": "Third Owner", "icon": "owner-3" },
      { "value": "FOURTH_OWNER", "label": "Fourth Owner", "icon": "owner-4" },
      { "value": "FIFTH_PLUS_OWNER", "label": "Fifth Owner or More", "icon": "owner-5-plus" }
    ],
    "condition_grade": [
      { "value": "GOOD", "label": "Good", "icon": "good" },
      { "value": "AVERAGE", "label": "Average", "icon": "average" },
      { "value": "NEEDS_REPAIR", "label": "Needs Repair", "icon": "needs-repair" }
    ],
    "special_offers": [
      { "value": "EXCHANGE_AVAILABLE", "label": "Exchange Available", "icon": "exchange" },
      { "value": "FREE_INSURANCE", "label": "Free Insurance", "icon": "free-insurance" },
      { "value": "FREE_HELMET", "label": "Free Helmet", "icon": "free-helmet" },
      { "value": "CASHBACK_OFFERS", "label": "Cashback Offers", "icon": "cashback" },
      { "value": "ACCESSORIES_INCLUDED", "label": "Accessories Included", "icon": "accessories" },
      { "value": "EXTENDED_WARRANTY", "label": "Extended Warranty", "icon": "warranty" },
      { "value": "FREE_SERVICE", "label": "Free Service", "icon": "free-service" },
      { "value": "LOW_DOWN_PAYMENT", "label": "Low Down Payment", "icon": "low-down-payment" }
    ]
  }
}
```

---

### Get Seller Defaults

```
GET /vehicles/seller-defaults
Authorization: Bearer <user_token>
```

**Auth required.** Returns the **authenticated user's own** name + mobile (resolved from user-service via gRPC) so the create form can pre-fill the *Seller Name* / *Seller Mobile* fields. The user may edit them; whatever is sent on create is what gets stored. Only ever returns the caller's own contact number (never someone else's).

**Response (200):**
```json
{
  "status": true,
  "seller_name": "Ritesh Kumar",
  "seller_mobile": "+919876543210"
}
```

> If the gRPC lookup fails, both fields return as empty strings so the form still opens.

**Error Responses:**
- `401` — Unauthorized (missing/invalid token)

---

## Vehicles API

### Endpoint Summary

| # | Screen / action | Method & path | Auth |
|---|-----------------|---------------|------|
| 1 | Vehicle type picker (upload step 1) | `GET /vehicles/types` | Public |
| 2 | Vehicle condition picker | `GET /vehicles/conditions` | Public |
| 3 | Listing-detail option pickers | `GET /vehicles/options` | Public |
| 4 | Seller contact pre-fill | `GET /vehicles/seller-defaults` | Auth |
| 5 | Browse / list vehicles | `GET /vehicles` | Public |
| 6 | Vehicle detail | `GET /vehicles/get/{id}` | Public |
| 7 | Create vehicle | `POST /vehicles/create` | Auth |
| 8 | My vehicles list (paginated) | `GET /vehicles/me/list` | Auth |
| 9 | Edit vehicle | `PUT /vehicles/update/{id}` | Auth (owner) |
| 10 | Delete vehicle (soft) | `DELETE /vehicles/delete/{id}` | Auth (owner) |
| 11 | Add images | `POST /vehicles/{id}/images` | Auth (owner) |
| 12 | Remove image | `DELETE /vehicles/{id}/images` | Auth (owner) |
| 13 | Presigned S3 upload URL (PUT) | `GET /upload/init` | Auth |
| 14 | Presigned S3 upload policy (POST, size-capped) — **preferred** | `GET /upload/init-v2` | Auth |

---

### List Vehicles (Public)

```
GET /vehicles?category=PASSENGER&sub_category=PASSENGER_2W&type=SCOOTER&condition=USED&pincode=110001&q=activa&page=1&limit=20
```

**Query Parameters** (all optional, AND-ed together; each is an exact, case-normalized match on its own field):

| Param | Type | Description |
|-------|------|-------------|
| `vehicle_class` | string | Mirrors `category`: `PASSENGER` or `COMMERCIAL` |
| `category` | string | L1 category exact match: `PASSENGER` or `COMMERCIAL` |
| `sub_category` | string | L2 display-group exact match (e.g. `PASSENGER_2W`, `LCV`) — returns every vehicle in that group |
| `type` | string | L3 concrete-leaf exact match (e.g. `SCOOTER`, `MINI_TRUCK`) |
| `condition` | string | `NEW` or `USED` (exact match) |
| `pincode` | integer | Filter by `location.pincode` |
| `user_id` | string | Filter by owner |
| `q` | string | Free-text search (name / description / brand / model) |
| `page` | integer | Default: `1` |
| `limit` | integer | Default: `20`, max `100` |

> Only `is_active: true`, non-deleted vehicles are returned. Results are sorted newest-first. To filter to a specific leaf, use `?type=` — **not** `?sub_category=` (which matches the group tier).

**Response (200):**
```json
{
  "status": true,
  "page": 1,
  "limit": 20,
  "total": 1,
  "vehicles": [
    {
      "_id": "683def456789012345abcdef",
      "user_id": "683user12345abcdef678901",
      "business_id": null,
      "name": "Honda Activa 6G",
      "description": "Single owner, well maintained",
      "vehicle_class": "PASSENGER",
      "category": "PASSENGER",
      "category_label": "Passenger",
      "sub_category": "PASSENGER_2W",
      "sub_category_label": "Two Wheeler",
      "type": "SCOOTER",
      "type_label": "Scooter",
      "condition": "USED",
      "condition_label": "Used",
      "brand": "Honda",
      "model": "Activa 6G",
      "variant": "",
      "manufacturing_year": 2022,
      "registration_year": 2022,
      "year": 2022,
      "color": "Grey",
      "registration_no": "DL01AB1234",
      "fuel_type": "PETROL",
      "transmission": "AUTOMATIC",
      "seating_capacity": 2,
      "engine_capacity_cc": 110,
      "mileage": "45 kmpl",
      "price": 85000,
      "currency": "INR",
      "expected_price": 85000,
      "is_negotiable": true,
      "ownership": "FIRST_OWNER",
      "ownership_label": "First Owner",
      "condition_grade": "GOOD",
      "condition_grade_label": "Good",
      "km_driven": 12000,
      "insurance_valid_till": "2027-03-31T00:00:00.000Z",
      "rc_available": true,
      "pollution_certificate": true,
      "service_history": false,
      "location": { "lat": 28.6139, "lon": 77.2090, "address": "Connaught Place", "city": "New Delhi", "state": "Delhi", "pincode": 110001 },
      "seller_name": "Rahul Sharma",
      "seller_mobile": "+919876543210",
      "cover_image": "https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/front.jpg",
      "images": ["https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/side.jpg"],
      "videos": [],
      "is_active": true,
      "is_verified": false,
      "deleted_at": null,
      "created_at": "2026-06-13T10:00:00.000Z",
      "updated_at": "2026-06-13T10:00:00.000Z",
      "user": {
        "id": "683user12345abcdef678901",
        "name": "Rahul Sharma",
        "username": "rahul_s",
        "profile_image": "https://s3.../user.jpg",
        "account_type": "personal",
        "profileType": "USER",
        "profession": "Engineer",
        "designation": "Owner",
        "bio": "Vehicle enthusiast"
      },
      "business": null
    }
  ]
}
```

> A response always carries the **full field set** regardless of condition. Flow-irrelevant fields appear with their schema defaults (`null`, `0`, `false`, `[]`) rather than being omitted — drive display off `condition`, not field presence. (Fields with no default — e.g. `manufacturing_year` on a NEW listing — are absent until set.)

---

### Get Vehicle by ID (Public)

```
GET /vehicles/get/{id}
```

Owner `user` + `business` are hydrated via the user-service gRPC and trimmed to public-safe fields. Soft-deleted listings read as `404`.

**Response (200):** same vehicle shape as the list endpoint (with labels), wrapped as:
```json
{
  "status": true,
  "vehicle": {
    "_id": "683def456789012345abcdef",
    "name": "Honda Activa 6G",
    "category": "PASSENGER", "category_label": "Passenger",
    "sub_category": "PASSENGER_2W", "sub_category_label": "Two Wheeler",
    "type": "SCOOTER", "type_label": "Scooter",
    "condition": "USED", "condition_label": "Used",
    "...": "all vehicle fields + *_label fields",
    "user": { "id": "683user...", "name": "Rahul Sharma", "...": "public fields only" },
    "business": null
  }
}
```

**Error Responses:**
- `400` — Invalid id
- `404` — Vehicle not found

---

### Create Vehicle

```
POST /vehicles/create
Content-Type: application/json
Authorization: Bearer <user_token>
```

The owner (`user_id`) is taken from the JWT — it is **never** read from the body. Server-controlled fields (`user_id`, `is_verified`, `vehicle_class`, `deleted_at`, timestamps) cannot be set by the client.

#### Always-required fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Vehicle title |
| `category` | string | A **top-level** `value`: `PASSENGER` or `COMMERCIAL`. `vehicle_class` is mirrored from it server-side |
| `sub_category` | string | A **display group** `value` BELONGING to `category` (e.g. `PASSENGER_2W` under `PASSENGER`) |
| `type` | string | A **concrete leaf** `value` BELONGING to `sub_category` (e.g. `SCOOTER` under `PASSENGER_2W`) |
| `condition` | string | `NEW` or `USED` |

#### Condition-specific required fields (enforced on create)

- **NEW** → `availability`, `delivery_time`, `ex_showroom_price` (plus `down_payment` & `monthly_emi` **when** `emi_available=true`).
- **USED** → `manufacturing_year`, `registration_year`, `registration_no`, `ownership`, `condition_grade`, `expected_price`, `km_driven`.

#### Optional fields

See the [NEW vs USED field matrix](#new-vs-used-field-matrix) for which optional fields are valid per flow, and the [full vehicle reference](#full-vehicle-object-reference) for every field. Shared optionals: `description`, `brand`, `model`, `variant`, `year`, `fuel_type`, `transmission`, `seating_capacity`, `engine_capacity_cc`, `mileage`, `price`, `currency`, `location`, `cover_image`, `images`, `videos`, `seller_name`, `seller_mobile`, `is_active`, `business_id`.

**Validation (HTTP 400 on failure — show `message`):**
- `name` required → `name is required`.
- `category` required / invalid → `category is required` / `Invalid category — must be one of PASSENGER, COMMERCIAL (see GET /vehicles/types)`.
- `sub_category` required / not under `category` → `sub_category is required` / `Invalid sub_category for <category> — pick a sub-category group under it from GET /vehicles/types`.
- `type` required / not a leaf under `sub_category` → `type is required` / `Invalid type for <sub_category> — pick a leaf type under it from GET /vehicles/types`.
- `condition` required / invalid → `Field "condition" is required — must be one of NEW, USED (see GET /vehicles/conditions)` / `Field "condition" is invalid — ...`.
- Cross-flow field → `"<field>" is not applicable to a <NEW|USED> vehicle`.
- Missing flow-required field → `"<field>" is required for a <NEW|USED> vehicle`; missing EMI sub-field → `"<field>" is required when EMI is available`.
- Picker value not in its set → `<field> must be one of <allowed values>` (and `special_offers contains an invalid value — allowed: ...`).
- `description` over the cap → `description must be at most <2000|500> characters for a <NEW|USED> vehicle`.
- Numbers (`year`, `manufacturing_year`, `registration_year`, `seating_capacity`, `engine_capacity_cc`, `km_driven`, `price`, `ex_showroom_price`, `on_road_price`, `down_payment`, `monthly_emi`, `expected_price`) — must be finite and non-negative when supplied.
- Booleans (`emi_available`, `is_negotiable`, `rc_available`, `pollution_certificate`, `service_history`) — accept `true/false`, `"true"/"yes"/"1"`, `"false"/"no"/"0"`.
- `insurance_valid_till` — must be a valid date.
- `seller_mobile` — optional leading `+` then 6–15 digits (spaces/dashes stripped).
- `cover_image` — must be a string. `images` / `videos` — arrays of non-empty strings.

**Example request — NEW vehicle:**
```json
{
  "name": "Bajaj Pulsar N160",
  "description": "Brand new, latest model",
  "category": "PASSENGER",
  "sub_category": "PASSENGER_2W",
  "type": "MOTORCYCLE",
  "condition": "NEW",
  "brand": "Bajaj",
  "model": "Pulsar N160",
  "variant": "Pulsar 150 Twin Disc",
  "fuel_type": "PETROL",
  "transmission": "MANUAL",
  "engine_capacity_cc": 160,
  "availability": "IN_STOCK",
  "delivery_time": "IMMEDIATE",
  "ex_showroom_price": 122000,
  "on_road_price": 138000,
  "emi_available": true,
  "down_payment": 20000,
  "monthly_emi": 4500,
  "special_offers": ["FREE_INSURANCE", "FREE_HELMET"],
  "location": { "city": "New Delhi", "state": "Delhi", "pincode": 110001 },
  "cover_image": "https://bucket.s3.../front.jpg",
  "images": ["https://bucket.s3.../side.jpg"],
  "seller_name": "Rahul Sharma",
  "seller_mobile": "+919876543210"
}
```

**Example request — USED vehicle:**
```json
{
  "name": "Honda Activa 6G",
  "description": "Single owner, well maintained",
  "category": "PASSENGER",
  "sub_category": "PASSENGER_2W",
  "type": "SCOOTER",
  "condition": "USED",
  "brand": "Honda",
  "model": "Activa 6G",
  "manufacturing_year": 2022,
  "registration_year": 2022,
  "registration_no": "DL01AB1234",
  "color": "Grey",
  "ownership": "FIRST_OWNER",
  "condition_grade": "GOOD",
  "expected_price": 85000,
  "is_negotiable": true,
  "km_driven": 12000,
  "insurance_valid_till": "2027-03-31",
  "rc_available": true,
  "pollution_certificate": true,
  "service_history": false,
  "location": { "city": "New Delhi", "state": "Delhi", "pincode": 110001 },
  "cover_image": "https://bucket.s3.../front.jpg",
  "images": ["https://bucket.s3.../side.jpg"]
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Vehicle created",
  "vehicle": { "_id": "683def...", "category": "PASSENGER", "category_label": "Passenger", "condition": "NEW", "condition_label": "New", "...": "all fields + *_label fields" }
}
```

**Error Responses:**
- `400` — any validation message above
- `401` — Unauthorized (missing/invalid token)

---

### List My Vehicles

```
GET /vehicles/me/list?page=1&limit=20
Authorization: Bearer <user_token>
```

Returns the authenticated user's non-deleted vehicles, newest-first, **paginated** (default page 1, limit 20, max 100). Owner enrichment is **not** applied (it's the owner's own list).

**Response (200):**
```json
{
  "status": true,
  "page": 1,
  "limit": 20,
  "total": 3,
  "vehicles": [
    { "_id": "683def...", "name": "Honda Activa 6G", "category": "PASSENGER", "category_label": "Passenger", "condition": "USED", "condition_label": "Used", "...": "all fields + *_label fields" }
  ]
}
```

---

### Update Vehicle (Owner)

```
PUT /vehicles/update/{id}
Content-Type: application/json
Authorization: Bearer <user_token>
```

Only the vehicle's owner may update it. All fields are optional on update (send only what changes). Only whitelisted fields are applied; server-controlled fields are ignored.

> **`category`, `sub_category`, `type`, and `condition` are immutable after creation.** Omitting them (or resending the **same** values) is fine; sending a **different** value returns `400 <field> cannot be changed after creation`. To re-type a vehicle, create a new listing. `vehicle_class` is derived and never client-set.

> **Cross-flow fields are still rejected on update**, validated against the listing's (immutable) condition — e.g. you can't add `km_driven` to a NEW listing. The flow-specific **required-field** check is enforced only on **create**, not update.

**Request Body (partial example):**
```json
{
  "expected_price": 79000,
  "description": "Price reduced — quick sale",
  "is_negotiable": true,
  "is_active": true
}
```

**Response (200):**
```json
{
  "status": true,
  "message": "Vehicle updated",
  "vehicle": { "_id": "683def...", "expected_price": 79000, "...": "updated vehicle + *_label fields" }
}
```

**Error Responses:**
- `400` — Invalid id / validation error / cross-flow field / `<field> cannot be changed after creation`
- `403` — Not the owner (`Not allowed`)
- `404` — Vehicle not found

---

### Delete Vehicle (Owner)

```
DELETE /vehicles/delete/{id}
Authorization: Bearer <user_token>
```

**Soft delete.** Sets `deleted_at` and `is_active=false` instead of removing the record. The row is retained (restorable, no orphaned cross-service references) but **excluded from every read** — public listing, get-by-id, owner list, and the gRPC lookups other services use. Not reversible via the public API. Deleting an already-deleted (or non-existent) vehicle returns `404`.

**Response (200):**
```json
{ "status": true, "message": "Vehicle deleted" }
```

**Error Responses:**
- `400` — Invalid id
- `403` — Not the owner
- `404` — Vehicle not found

---

## Vehicle Images API

Images are URLs already uploaded via the [`/upload/init`](#upload-api) flow. These endpoints attach/detach those URLs on a vehicle. Both require the authenticated **owner**.

### Add Images

```
POST /vehicles/{id}/images
Content-Type: application/json
Authorization: Bearer <user_token>
```

**Request Body:**
```json
{ "images": ["https://bucket.s3.../img1.jpg", "https://bucket.s3.../img2.jpg"] }
```

> URLs are de-duplicated against the vehicle's existing `images`.

**Response (200):**
```json
{
  "status": true,
  "vehicle": { "_id": "683def...", "images": ["https://.../img1.jpg", "https://.../img2.jpg"], "...": "... + *_label fields" }
}
```

**Error Responses:**
- `400` — Invalid id / `images[] required` / `images must be non-empty strings`
- `403` — Not the owner
- `404` — Vehicle not found

---

### Remove Image

```
DELETE /vehicles/{id}/images
Content-Type: application/json
Authorization: Bearer <user_token>
```

**Request Body:**
```json
{ "image": "https://bucket.s3.../img1.jpg" }
```

**Response (200):**
```json
{
  "status": true,
  "vehicle": { "_id": "683def...", "images": ["https://.../img2.jpg"], "...": "... + *_label fields" }
}
```

**Error Responses:**
- `400` — Invalid id / `image required`
- `403` — Not the owner
- `404` — Vehicle not found

---

## Upload API

Both endpoints are auth-gated and rate-limited (`uploadLimiter`). Both enforce a **MIME allowlist + matching file extension** before signing — only `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `video/mp4`, `video/quicktime`, `video/webm` are accepted (SVG and html are deliberately blocked to close the stored-XSS / CWE-434 vector). Both return errors as `{ "error": "..." }`, unlike the `{ status, message }` shape elsewhere.

> **Use `/upload/init-v2` for new clients.** It is the preferred flow because the signed policy carries a **hard size cap** that S3 itself enforces (10 MB for images, 100 MB for video). The original `/upload/init` (presigned PUT) **cannot** carry a size condition, so it has no server-side size limit.

### Generate Pre-signed S3 Upload URL — PUT (`/upload/init`)

```
GET /upload/init?fileName=front.jpg&fileType=image/jpeg
Authorization: Bearer <user_token>
```

**Query Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `fileName` | string | Yes | Original file name (extension must match `fileType`) |
| `fileType` | string | Yes | MIME type from the allowlist, e.g. `image/jpeg` |

**Response (200):**
```json
{
  "uploadUrl": "https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/...jpg?X-Amz-Signature=...",
  "publicUrl": "https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/...jpg",
  "fileKey": "vehicle-service/uid/1717920000000-uuid.jpg"
}
```

**Frontend usage:**
1. Call `GET /upload/init` to get a pre-signed URL (valid ~30 min, ACL `public-read`).
2. `PUT` the raw file bytes to `uploadUrl` with header `Content-Type: <fileType>`.
3. Use `publicUrl` in subsequent API calls (`cover_image`, `images[]`, `videos[]`).

**Error Responses:**
- `400` — Missing `fileName` / `fileType`, unsupported `fileType`, or extension mismatch
- `500` — S3 error

---

### Generate Pre-signed S3 Upload Policy — POST, size-capped (`/upload/init-v2`) — **preferred**

```
GET /upload/init-v2?fileName=front.jpg&fileType=image/jpeg
Authorization: Bearer <user_token>
```

Returns a presigned **POST** `url` + `fields`. S3 enforces both the declared `Content-Type` and a **hard size cap** (`content-length-range`) via the signed policy — neither is possible with the PUT flow.

| Cap | Limit |
|-----|-------|
| Image (`image/*`) | 10 MB |
| Video (`video/*`) | 100 MB |

**Query Parameters:** same as `/upload/init` (`fileName`, `fileType`).

**Response (200):**
```json
{
  "url": "https://bucket.s3.ap-south-1.amazonaws.com/",
  "fields": {
    "Content-Type": "image/jpeg",
    "acl": "public-read",
    "bucket": "...",
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": "...",
    "X-Amz-Date": "...",
    "key": "vehicle-service/uid/1717920000000-uuid.jpg",
    "Policy": "...",
    "X-Amz-Signature": "..."
  },
  "publicUrl": "https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/...jpg",
  "fileKey": "vehicle-service/uid/1717920000000-uuid.jpg",
  "maxSizeBytes": 10485760
}
```

**Frontend usage:**
1. Call `GET /upload/init-v2`.
2. Build a `multipart/form-data` body: append **all** returned `fields` first, then the binary `file` **last**.
3. `POST` it to `url`. S3 rejects the upload if it exceeds `maxSizeBytes` or the Content-Type doesn't match.
4. Use `publicUrl` in subsequent API calls (`cover_image`, `images[]`, `videos[]`).

**Error Responses:**
- `400` — Missing `fileName` / `fileType`, unsupported `fileType`, or extension mismatch
- `500` — S3 error

---

## Full Vehicle Object Reference

Every field stored on a vehicle (returned by all reads, alongside its `*_label` where applicable). Defaults shown are the schema defaults applied when a field is not set.

| Field | Type | Default | Flow | Notes |
|-------|------|---------|------|-------|
| `_id` | string | — | — | Mongo id |
| `user_id` | string | — | — | Owner (server-set from JWT) |
| `business_id` | string\|null | `null` | — | Optional business id |
| `name` | string | — | both | Required |
| `description` | string | `""` | both | Max 2000 (NEW) / 500 (USED) |
| `vehicle_class` | string | — | — | Mirrors `category` (derived, never client-set) |
| `category` | string | — | both | `PASSENGER` / `COMMERCIAL`. Immutable |
| `sub_category` | string | — | both | L2 display group. Immutable |
| `type` | string | — | both | L3 concrete leaf. Immutable |
| `condition` | string | — | both | `NEW` / `USED`. Immutable |
| `brand` | string | — | both | |
| `model` | string | — | both | |
| `variant` | string | `""` | both | Trim/variant of the model |
| `year` | number | — | both | Legacy; mirrors `manufacturing_year` for USED |
| `manufacturing_year` | number | — | USED | Required (USED) |
| `registration_year` | number | — | USED | Required (USED) |
| `color` | string | — | USED | |
| `registration_no` | string | — | USED | Required (USED) |
| `fuel_type` | string\|null | `null` | both | `PETROL`/`DIESEL`/`ELECTRIC`/`CNG`/`HYBRID`/`OTHER` |
| `transmission` | string\|null | `null` | both | `MANUAL`/`AUTOMATIC`/`AMT`/`CVT` |
| `seating_capacity` | number | `0` | both | |
| `engine_capacity_cc` | number | `0` | both | Displacement in CC |
| `mileage` | string | `""` | both | e.g. `"45 kmpl"` |
| `price` | number | `0` | both | Generic (kept for search / backward compat) |
| `currency` | string | `"INR"` | both | |
| `ex_showroom_price` | number | `0` | NEW | Required (NEW) |
| `on_road_price` | number | `0` | NEW | |
| `emi_available` | boolean | `false` | NEW | |
| `down_payment` | number | `0` | NEW | Required when `emi_available=true` |
| `monthly_emi` | number | `0` | NEW | Required when `emi_available=true` |
| `availability` | string\|null | `null` | NEW | Required (NEW). See options |
| `delivery_time` | string\|null | `null` | NEW | Required (NEW). See options |
| `special_offers` | string[] | `[]` | NEW | Multi-select. See options |
| `expected_price` | number | `0` | USED | Required (USED) |
| `is_negotiable` | boolean | `false` | USED | |
| `ownership` | string\|null | `null` | USED | Required (USED). See options |
| `condition_grade` | string\|null | `null` | USED | Required (USED). Physical grade (≠ condition) |
| `km_driven` | number | `0` | USED | Required (USED) |
| `insurance_valid_till` | date\|null | `null` | USED | |
| `rc_available` | boolean | `false` | USED | |
| `pollution_certificate` | boolean | `false` | USED | |
| `service_history` | boolean | `false` | USED | |
| `location` | object | `{...}` | both | `{ lat, lon, address, city, state, pincode }` |
| `seller_name` | string | `""` | both | Per-listing override; empty → use attached `user` |
| `seller_mobile` | string | `""` | both | Per-listing contact (profile `contact_no` is not public) |
| `cover_image` | string | `""` | both | |
| `images` | string[] | `[]` | both | |
| `videos` | string[] | `[]` | both | |
| `is_active` | boolean | `true` | both | |
| `is_verified` | boolean | `false` | — | Server-controlled |
| `deleted_at` | date\|null | `null` | — | Soft-delete marker; excluded from all reads when set |
| `created_at` | date | — | — | |
| `updated_at` | date | — | — | |
| `user` | object\|null | — | — | Only on hydrated public reads (gRPC) |
| `business` | object\|null | — | — | Only on hydrated public reads (gRPC) |

> A read returns the **full field set** regardless of condition: flow-irrelevant fields with a schema default appear with that default; fields with no default (e.g. `brand`, `model`, `manufacturing_year`) are absent until set. Drive display off `condition`, not field presence.

---

## Owner Enrichment

On **public** reads (`GET /vehicles`, `GET /vehicles/get/{id}`), the embedded owner is fetched from the user-service via gRPC and **trimmed** to a safe display subset — PII (email, phone, address, exact geo, tokens, password) is never exposed.

**`user` object fields:**
`id`, `name`, `username`, `profile_image`, `account_type`, `profileType`, `profession`, `designation`, `bio`

**`business` object fields (null when the owner has no business):**
`id`, `business_name`, `logo`, `website_url`, `business_description`, `category_of_business`, `sub_category_of_business`, `pincode`

> If the gRPC enrichment fails, the vehicle still ships with `user: null` / `business: null` rather than failing the request.
>
> The seller's phone number is **not** part of public `user` enrichment (`contact_no` is stripped). It is surfaced only via the per-listing `seller_mobile` field (which the owner sets at create time) and via the auth-gated `GET /vehicles/seller-defaults` for the caller's own number.

---

## gRPC Surface

Other services consume vehicle data over gRPC (`vehicle.proto`, package `vehicle`, service `VehicleService`). Soft-deleted vehicles are excluded from all of these reads.

| RPC | Request | Response |
|-----|---------|----------|
| `GetVehicleById` | `{ id }` | `Vehicle` |
| `GetVehiclesByUserId` | `{ user_id }` | `VehicleList` |
| `GetVehiclesByIds` | `{ ids[] }` | `VehicleList` |

The `Vehicle` message carries the same listing-detail fields as the HTTP API (additive — all optional, absent on legacy docs): `condition`, `variant`, `engine_capacity_cc`, the NEW-flow block (`availability`, `delivery_time`, `ex_showroom_price`, `on_road_price`, `emi_available`, `down_payment`, `monthly_emi`, `special_offers[]`), the USED-flow block (`manufacturing_year`, `registration_year`, `ownership`, `condition_grade`, `expected_price`, `is_negotiable`, `km_driven`, `insurance_valid_till`, `rc_available`, `pollution_certificate`, `service_history`), `videos[]`, and `seller_name` / `seller_mobile`.

> The proto changes are **purely additive** (new field numbers ≥ 26); existing consumers reading the older fields are unaffected. The same service also exposes facility/gallery/live-photo/testimonial/contact RPCs (unchanged).

---

## Frontend Integration Sequence

```
Step 1: Pick vehicle type + condition + detail options
  GET /vehicles/types       → category / sub_category / type
  GET /vehicles/conditions  → condition (NEW / USED)
  GET /vehicles/options     → availability, delivery_time, special_offers (NEW)
                              ownership, condition_grade (USED)

Step 2: Upload photos / videos (per file) — preferred: size-capped POST
  GET /upload/init-v2?fileName=front.jpg&fileType=image/jpeg
  POST multipart/form-data to <url> (all fields first, then file last)
  → Save publicUrl → cover_image / images[] / videos[]
  (legacy: GET /upload/init then PUT <uploadUrl> with file binary)

Step 3: Pre-fill seller contact, then create the vehicle
  GET  /vehicles/seller-defaults  → seller_name / seller_mobile (editable)
  POST /vehicles/create
  Body: { name, category, sub_category, type, condition, ...condition-specific fields,
          cover_image, images[], seller_name, seller_mobile, ... }

Step 4: Vehicle is publicly discoverable
  GET /vehicles?category=PASSENGER&sub_category=PASSENGER_2W&type=SCOOTER&condition=USED&pincode=110001&q=activa
  GET /vehicles/get/{id}

Step 5 (optional): Manage media
  POST   /vehicles/{id}/images   Body: { images: ["url1","url2"] }
  DELETE /vehicles/{id}/images   Body: { image: "url" }

Step 6 (optional): Edit / delist / delete
  PUT    /vehicles/update/{id}   Body: { expected_price, is_active, ... }  (type & condition immutable; cross-flow fields rejected)
  DELETE /vehicles/delete/{id}                                            (soft delete)

Owner's own dashboard:
  GET /vehicles/me/list?page=1&limit=20
```

---

## Error Response Format

All errors follow this structure:

```json
{
  "status": false,
  "message": "Human-readable error message"
}
```

> Show the `message` directly to the user. (The `/upload/init` endpoint uses `{ "error": "..." }` instead.)

Common HTTP status codes:
- `400` — Validation error / bad request (e.g. `name is required`, `type is required`, `"km_driven" is not applicable to a NEW vehicle`, `"availability" is required for a NEW vehicle`, `price must be a non-negative number`, `Invalid id`)
- `401` — Missing or invalid auth token
- `403` — Not the owner of the resource
- `404` — Resource not found
- `500` — Internal server error

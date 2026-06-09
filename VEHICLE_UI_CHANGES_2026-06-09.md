# Vehicle Service - Complete API Documentation

**Base URLs:**
- Production: `https://be.beapp.in/api/vehicle-service`
- Development: `http://localhost:3009`
- Swagger UI: `/api-docs`

**Authentication:** Bearer token in `Authorization` header for protected routes. Public routes need no auth.

---

## Table of Contents

1. [Vehicle Creation Flow (Page-wise)](#vehicle-creation-flow)
2. [Vehicle Types API](#vehicle-types-api)
3. [Vehicles API](#vehicles-api)
4. [Vehicle Images API](#vehicle-images-api)
5. [Upload API](#upload-api)
6. [Owner Enrichment (Public Reads)](#owner-enrichment)
7. [Frontend Integration Sequence](#frontend-integration-sequence)
8. [Error Response Format](#error-response-format)

---

## Vehicle Creation Flow

This section describes the **page-wise flow** a frontend should follow to list a vehicle and make it publicly discoverable. Each step maps to a frontend page/screen.

### Flow Diagram

```
PAGE 1: Pick Vehicle Type
  User selects the vehicle type (drives the rest of the form)
    GET /vehicles/types
      └── CAR / BIKE / SCOOTER / TRUCK / AUTO / BUS / OTHER
           └── chosen `value` (e.g. "CAR") is sent as `category`

PAGE 2: Upload Photos
  For each photo: get a pre-signed S3 URL, PUT the file, keep publicUrl
    GET /upload/init?fileName=front.jpg&fileType=image/jpeg
      └── PUT raw bytes to uploadUrl
      └── keep returned publicUrl  →  cover_image / images[]

PAGE 3: Vehicle Details + Submit (Owner)
  User fills the form and submits
    POST /vehicles/create
      └── owner = authenticated user (server-set, never client-set)
      └── publicUrls become cover_image / images[]

PAGE 4: Vehicle is now live
  Anyone can browse and view
    GET  /vehicles?category=CAR&pincode=110001
    GET  /vehicles/get/{id}
```

> **New today (2026-06-09):** `GET /vehicles/types` (step 1). Everything else already existed; `POST /vehicles/create` and `PUT /vehicles/update/{id}` got **stricter write validation** (see below).

---

### PAGE 1: Vehicle Type Picker

Populate the type picker from the API — **do not hardcode** the list. The chosen `value` is sent back as `category` on create/update.

---

### PAGE 2: Photo Upload

Each photo is uploaded directly to S3 via a pre-signed URL, then its `publicUrl` is attached to the vehicle. See [Upload API](#upload-api).

---

### PAGE 3: Vehicle Submission (Owner)

Owner submits the vehicle with the chosen `category` and uploaded image URLs. See [Create Vehicle](#create-vehicle).

---

### PAGE 4: Discovery (Public)

Public list + detail screens. The embedded owner is trimmed to a safe display subset (see [Owner Enrichment](#owner-enrichment)).

---

## Vehicle Types API

### List Vehicle Types (step 1 of upload)

```
GET /vehicles/types
```

Public. No auth. Returns the canonical, server-controlled type taxonomy.

**Response (200):**
```json
{
  "status": true,
  "vehicleTypes": [
    { "value": "CAR", "label": "Car", "icon": "car" },
    { "value": "BIKE", "label": "Bike", "icon": "bike" },
    { "value": "SCOOTER", "label": "Scooter", "icon": "scooter" },
    { "value": "TRUCK", "label": "Truck", "icon": "truck" },
    { "value": "AUTO", "label": "Auto", "icon": "auto" },
    { "value": "BUS", "label": "Bus", "icon": "bus" },
    { "value": "OTHER", "label": "Other", "icon": "other" }
  ]
}
```

> Send the chosen `value` (e.g. `"CAR"`) as `category` when creating/editing a vehicle. Unknown or omitted categories are **normalized to `OTHER`** server-side — never rejected.

---

## Vehicles API

### Endpoint Summary

| # | Screen / action | Method & path | Auth |
|---|-----------------|---------------|------|
| 1 | Vehicle type picker (upload step 1) | `GET /vehicles/types` | Public |
| 2 | Browse / list vehicles | `GET /vehicles` | Public |
| 3 | Vehicle detail | `GET /vehicles/get/{id}` | Public |
| 4 | Create vehicle | `POST /vehicles/create` | Auth |
| 5 | My vehicles list | `GET /vehicles/me/list` | Auth |
| 6 | Edit vehicle | `PUT /vehicles/update/{id}` | Auth (owner) |
| 7 | Delete vehicle | `DELETE /vehicles/delete/{id}` | Auth (owner) |
| 8 | Add images | `POST /vehicles/{id}/images` | Auth (owner) |
| 9 | Remove image | `DELETE /vehicles/{id}/images` | Auth (owner) |
| 10 | Presigned S3 upload URL | `GET /upload/init` | Auth |

---

### List Vehicles (Public)

```
GET /vehicles?category=CAR&pincode=110001&q=innova&page=1&limit=20
```

**Query Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | string | No | Type filter (e.g. `CAR`, `BIKE`) |
| `sub_category` | string | No | Sub-type filter (e.g. `SUV`, `Sedan`) |
| `pincode` | integer | No | Filter by `location.pincode` |
| `user_id` | string | No | Filter by owner |
| `q` | string | No | Free-text search (name / description / brand / model) |
| `page` | integer | No | Default: `1` |
| `limit` | integer | No | Default: `20`, max `100` |

> Only `is_active: true` vehicles are returned. Results are sorted newest-first.

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
      "name": "Toyota Innova Crysta",
      "description": "Well maintained, single owner",
      "category": "CAR",
      "sub_category": "SUV",
      "brand": "Toyota",
      "model": "Innova Crysta",
      "year": 2022,
      "color": "White",
      "registration_no": "DL01AB1234",
      "fuel_type": "DIESEL",
      "transmission": "AUTOMATIC",
      "seating_capacity": 7,
      "mileage": "11 kmpl",
      "price": 1850000,
      "currency": "INR",
      "location": { "lat": 28.6139, "lon": 77.2090, "address": "Connaught Place", "city": "New Delhi", "state": "Delhi", "pincode": 110001 },
      "cover_image": "https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/front.jpg",
      "images": ["https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/side.jpg"],
      "is_active": true,
      "is_verified": false,
      "created_at": "2026-06-09T10:00:00.000Z",
      "updated_at": "2026-06-09T10:00:00.000Z",
      "user": {
        "id": "683user12345abcdef678901",
        "name": "Rahul Sharma",
        "username": "rahul_s",
        "profile_image": "https://s3.../user.jpg",
        "account_type": "personal",
        "profileType": "USER",
        "profession": "Engineer",
        "designation": "Owner",
        "bio": "Car enthusiast"
      },
      "business": null
    }
  ]
}
```

---

### Get Vehicle by ID (Public)

```
GET /vehicles/get/{id}
```

Owner `user` + `business` are hydrated via the user-service gRPC and trimmed to public-safe fields.

**Response (200):**
```json
{
  "status": true,
  "vehicle": {
    "_id": "683def456789012345abcdef",
    "name": "Toyota Innova Crysta",
    "category": "CAR",
    "sub_category": "SUV",
    "brand": "Toyota",
    "model": "Innova Crysta",
    "year": 2022,
    "price": 1850000,
    "currency": "INR",
    "cover_image": "https://bucket.s3.../front.jpg",
    "images": ["https://bucket.s3.../side.jpg"],
    "is_active": true,
    "is_verified": false,
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

The owner (`user_id`) is taken from the JWT — it is **never** read from the body. Server-controlled fields (`user_id`, `is_verified`, timestamps) cannot be set by the client.

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Vehicle title |
| `description` | string | No | Free text |
| `category` | string | No | A `value` from `/vehicles/types`. Defaults to `OTHER` if omitted/unknown |
| `sub_category` | string | No | e.g. `SUV`, `Sedan` |
| `brand` | string | No | e.g. `Toyota` |
| `model` | string | No | e.g. `Innova Crysta` |
| `year` | number | No | Non-negative |
| `color` | string | No | |
| `registration_no` | string | No | |
| `fuel_type` | string | No | `PETROL` / `DIESEL` / `ELECTRIC` / `CNG` / `HYBRID` / `OTHER` |
| `transmission` | string | No | `MANUAL` / `AUTOMATIC` / `AMT` / `CVT` |
| `seating_capacity` | number | No | Non-negative |
| `mileage` | string | No | e.g. `"11 kmpl"` |
| `price` | number | No | Non-negative |
| `currency` | string | No | Default: `INR` |
| `location` | object | No | `{ lat, lon, address, city, state, pincode }` |
| `cover_image` | string (URL) | No | A `publicUrl` from `/upload/init` |
| `images` | string[] (URLs) | No | Array of `publicUrl`s |
| `is_active` | boolean | No | Default: `true` |
| `business_id` | string | No | Optional explicit business id |

**Validation (HTTP 400 on failure — show `message`):**
- `name` is required.
- `category` — normalized to a known `value`; unknown/missing falls back to `OTHER` (never rejected).
- `year`, `price`, `seating_capacity` — must be a finite, non-negative number when supplied.
- `cover_image` — must be a string.
- `images` — must be an array of non-empty strings.

**Example request:**
```json
{
  "name": "Toyota Innova Crysta",
  "description": "Well maintained, single owner",
  "category": "CAR",
  "sub_category": "SUV",
  "brand": "Toyota",
  "model": "Innova Crysta",
  "year": 2022,
  "color": "White",
  "registration_no": "DL01AB1234",
  "fuel_type": "DIESEL",
  "transmission": "AUTOMATIC",
  "seating_capacity": 7,
  "mileage": "11 kmpl",
  "price": 1850000,
  "currency": "INR",
  "location": { "lat": 28.6139, "lon": 77.2090, "address": "Connaught Place", "city": "New Delhi", "state": "Delhi", "pincode": 110001 },
  "cover_image": "https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/front.jpg",
  "images": ["https://bucket.s3.ap-south-1.amazonaws.com/vehicle-service/uid/side.jpg"]
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Vehicle created",
  "vehicle": {
    "_id": "683def456789012345abcdef",
    "user_id": "683user12345abcdef678901",
    "business_id": null,
    "name": "Toyota Innova Crysta",
    "category": "CAR",
    "is_active": true,
    "is_verified": false,
    "created_at": "2026-06-09T10:00:00.000Z",
    "updated_at": "2026-06-09T10:00:00.000Z",
    "...": "all vehicle fields"
  }
}
```

**Error Responses:**
- `400` — `name is required` / validation error (e.g. `price must be a non-negative number`)
- `401` — Unauthorized (missing/invalid token)

---

### List My Vehicles

```
GET /vehicles/me/list
Authorization: Bearer <user_token>
```

Returns all vehicles owned by the authenticated user, newest-first. Owner enrichment is **not** applied here (it's the owner's own list).

**Response (200):**
```json
{
  "status": true,
  "vehicles": [
    { "_id": "683def...", "name": "Toyota Innova Crysta", "category": "CAR", "is_active": true, "...": "all fields" }
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

Only the vehicle's owner may update it. Same writable fields and validation as [Create](#create-vehicle) (all optional on update). Only whitelisted fields are applied; server-controlled fields are ignored.

**Request Body (partial example):**
```json
{
  "price": 1799000,
  "description": "Price reduced — quick sale",
  "is_active": true
}
```

**Response (200):**
```json
{
  "status": true,
  "message": "Vehicle updated",
  "vehicle": { "_id": "683def...", "price": 1799000, "...": "updated vehicle" }
}
```

**Error Responses:**
- `400` — Invalid id / validation error
- `403` — Not the owner (`Not allowed`)
- `404` — Vehicle not found

---

### Delete Vehicle (Owner)

```
DELETE /vehicles/delete/{id}
Authorization: Bearer <user_token>
```

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

Images are URLs that were already uploaded via the [`/upload/init`](#upload-api) flow. These endpoints just attach/detach those URLs on a vehicle. Both require the authenticated **owner**.

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
  "vehicle": { "_id": "683def...", "images": ["https://.../img1.jpg", "https://.../img2.jpg"], "...": "..." }
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
  "vehicle": { "_id": "683def...", "images": ["https://.../img2.jpg"], "...": "..." }
}
```

**Error Responses:**
- `400` — Invalid id / `image required`
- `403` — Not the owner
- `404` — Vehicle not found

---

## Upload API

### Generate Pre-signed S3 Upload URL

```
GET /upload/init?fileName=front.jpg&fileType=image/jpeg
Authorization: Bearer <user_token>
```

**Query Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `fileName` | string | Yes | Original file name (extension is preserved) |
| `fileType` | string | Yes | MIME type, e.g. `image/jpeg` |

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
3. Use `publicUrl` in subsequent API calls (`cover_image`, `images[]`).

**Error Responses:**
- `400` — Missing `fileName` / `fileType`
- `500` — S3 error

---

## Owner Enrichment

On **public** reads (`GET /vehicles`, `GET /vehicles/get/{id}`), the embedded owner is fetched from the user-service via gRPC and **trimmed** to a safe display subset — PII (email, phone, address, exact geo, tokens) is never exposed.

**`user` object fields:**
`id`, `name`, `username`, `profile_image`, `account_type`, `profileType`, `profession`, `designation`, `bio`

**`business` object fields (null when the owner has no business):**
`id`, `business_name`, `logo`, `website_url`, `business_description`, `category_of_business`, `sub_category_of_business`, `pincode`

> If the gRPC enrichment fails, the vehicle still ships with `user: null` / `business: null` rather than failing the request.

---

## Frontend Integration Sequence

```
Step 1: Pick vehicle type
  GET /vehicles/types
  → user selects a `value` (e.g. "CAR") → use as `category`

Step 2: Upload photos (per image)
  GET /upload/init?fileName=front.jpg&fileType=image/jpeg
  PUT <uploadUrl> with file binary (Content-Type: image/jpeg)
  → Save publicUrl

Step 3: Create the vehicle
  POST /vehicles/create
  Body: { name, category, cover_image: publicUrl, images: [publicUrl, ...], ... }

Step 4: Vehicle is publicly discoverable
  GET /vehicles?category=CAR&pincode=110001&q=innova
  GET /vehicles/get/{id}

Step 5 (optional): Manage media
  POST   /vehicles/{id}/images   Body: { images: ["url1","url2"] }
  DELETE /vehicles/{id}/images   Body: { image: "url" }

Step 6 (optional): Edit / delist
  PUT    /vehicles/update/{id}   Body: { price, is_active, ... }
  DELETE /vehicles/delete/{id}
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
- `400` — Validation error / bad request (e.g. `name is required`, `price must be a non-negative number`, `Invalid id`)
- `401` — Missing or invalid auth token
- `403` — Not the owner of the resource
- `404` — Resource not found
- `500` — Internal server error

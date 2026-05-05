# Favorite Locations — Frontend Integration Guide

This guide explains how the frontend integrates with the **Favorite Locations** feature in `be_rider_service`. Favorite locations are saved address snapshots that the frontend uses to populate quick-select pickup/drop options when a user books a ride.

---

## 1. Overview

Each favorite stores:

- A **GeoJSON Point** (`[longitude, latitude]`)
- A **human-readable address** (string)
- An **optional label** (e.g. `"Mom's house"`)
- A **tag** — either a predefined value (`home`, `office`, `gym`, …) or any custom user-defined string
- Optional **metadata** (houseNo, landmark, city, state, pincode, notes)

Tags are auto-normalized server-side (lowercased, spaces → underscores). The server automatically marks any tag that is not in the predefined list as a custom tag, and the `GET /favorite-locations/tags` endpoint exposes both lists for UI rendering.

All endpoints are scoped to the authenticated user — favorites cannot be read or written across users.

---

## 2. Authentication

Every endpoint requires a Bearer token in the `Authorization` header:

```
Authorization: Bearer <jwt>
```

The server resolves `userId` from the token (via gRPC session validation, with JWT fallback). The frontend never needs to send `userId` in the request body.

---

## 3. Base URL

Mounted at:

```
/favorite-locations
```

Full Swagger UI is available at `/api-docs` (look for the **FavoriteLocation** tag) and the raw OpenAPI spec at `/swagger.json`.

---

## 4. Data Model

### `FavoriteLocation` response object

```jsonc
{
  "_id": "65fa1c9e2b9c8a001f8c4d12",
  "userId": "65f9b2a01c2d3e4f5a6b7c8d",
  "label": "My House",
  "address": "B-12, Sector 21, Noida, UP 201301",
  "location": {
    "type": "Point",
    "coordinates": [77.3910, 28.5355]   // [longitude, latitude]
  },
  "tag": "home",
  "isCustomTag": false,
  "metadata": {
    "houseNo": "B-12",
    "landmark": "Near Apollo Hospital",
    "city": "Noida",
    "state": "UP",
    "pincode": "201301",
    "notes": ""
  },
  "createdAt": "2026-05-05T12:34:56.789Z",
  "updatedAt": "2026-05-05T12:34:56.789Z"
}
```

> Note: `location.coordinates` is **`[longitude, latitude]`** — GeoJSON order, not the typical `(lat, lng)` UI order. The frontend should swap before passing to map widgets that expect `(lat, lng)`.

---

## 5. Endpoints

### 5.1 Create — `POST /favorite-locations`

Save a new favorite for the authenticated user.

**Request body**

```jsonc
{
  "label": "My House",                                  // optional, max 100 chars
  "address": "B-12, Sector 21, Noida, UP 201301",       // required, max 500 chars
  "location": {                                         // required
    "type": "Point",
    "coordinates": [77.3910, 28.5355]                   // [lng, lat]
  },
  "tag": "home",                                        // required, predefined or custom
  "metadata": {                                         // optional, all subfields optional
    "houseNo": "B-12",
    "landmark": "Near Apollo Hospital",
    "city": "Noida",
    "state": "UP",
    "pincode": "201301",
    "notes": ""
  }
}
```

**Responses**

| Code | Meaning |
|------|---------|
| 201  | Created — returns the saved `FavoriteLocation` object |
| 400  | Validation error (missing required fields, invalid coordinates) |
| 401  | Missing or invalid token |
| 500  | Internal error |

**Example**

```ts
await fetch(`${API_BASE}/favorite-locations`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    label: 'Office',
    address: 'Cyber Hub, Gurugram, HR 122002',
    location: { type: 'Point', coordinates: [77.0876, 28.4949] },
    tag: 'office',
    metadata: { city: 'Gurugram', state: 'HR', pincode: '122002' },
  }),
});
```

---

### 5.2 List — `GET /favorite-locations`

Returns the user's favorites. Sorted by `createdAt` descending.

**Query params**

| Name   | Type    | Default | Description |
|--------|---------|---------|-------------|
| `tag`    | string  | —       | Filter by tag (case-insensitive, normalized) |
| `search` | string  | —       | Substring match (case-insensitive) on `address` and `label` |
| `page`   | integer | `1`     | Page number |
| `limit`  | integer | `20`    | Page size, max `100` |

**Response — 200**

```jsonc
{
  "favorites": [ /* FavoriteLocation[] */ ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 4,
    "totalPages": 1
  }
}
```

**Examples**

```ts
// All favorites
GET /favorite-locations

// Only home favorites
GET /favorite-locations?tag=home

// Search by partial address
GET /favorite-locations?search=lajpat

// Paginate
GET /favorite-locations?page=2&limit=10
```

---

### 5.3 Tags — `GET /favorite-locations/tags`

Returns the predefined tag allowlist plus the distinct custom tags the current user has created. Use this to render tag chips and offer custom-tag autocomplete.

**Response — 200**

```jsonc
{
  "predefined": [
    "home", "office", "gym", "school", "college",
    "family", "friends", "hospital", "restaurant", "cafe",
    "shopping", "mall", "market", "hotel", "airport",
    "station", "gas_station", "parking", "park", "place_of_worship",
    "other"
  ],
  "custom": ["yoga", "co-working_space"]
}
```

> Frontend tip: render `predefined` as quick-pick chips, and merge `custom` into the autocomplete dropdown when the user starts typing in the tag field.

---

### 5.4 Nearby — `GET /favorite-locations/nearby`

Returns the user's favorites near a coordinate, ordered by proximity (uses MongoDB `2dsphere` `$near`). Useful for "your nearby saved places" suggestions while choosing a pickup point.

**Query params**

| Name          | Type    | Default | Description |
|---------------|---------|---------|-------------|
| `longitude`   | number  | —       | **Required**, range `[-180, 180]` |
| `latitude`    | number  | —       | **Required**, range `[-90, 90]` |
| `maxDistance` | integer | `5000`  | Search radius in meters; max `100000` |
| `limit`       | integer | `20`    | Max results, max `100` |

**Response — 200**

```jsonc
{
  "favorites": [ /* FavoriteLocation[] */ ],
  "maxDistance": 5000,
  "count": 3
}
```

---

### 5.5 Get one — `GET /favorite-locations/:id`

Returns a single favorite by Mongo ObjectId. Returns `403` if the favorite belongs to another user, `404` if missing, `400` if `id` is not a valid ObjectId.

---

### 5.6 Update — `PATCH /favorite-locations/:id`

Partial update — send any subset of fields. `metadata` is **shallow-merged** with the existing value (so you can update one metadata field without overwriting the others).

**Request body** (all fields optional)

```jsonc
{
  "label": "Mom's house",
  "address": "Updated address",
  "location": { "type": "Point", "coordinates": [77.42, 28.61] },
  "tag": "family",
  "metadata": { "notes": "Use back gate" }
}
```

**Responses**

| Code | Meaning |
|------|---------|
| 200  | Updated — returns the new `FavoriteLocation` |
| 400  | Validation error / invalid id |
| 403  | Caller does not own the favorite |
| 404  | Not found |

---

### 5.7 Delete — `DELETE /favorite-locations/:id`

Hard delete. Ownership-checked.

**Response — 200**

```jsonc
{ "message": "Favorite location deleted.", "id": "65fa1c9e2b9c8a001f8c4d12" }
```

---

## 6. Validation Rules (Server-Side)

| Field | Rule |
|-------|------|
| `address` | Required, non-empty string, max 500 chars |
| `tag` | Required, non-empty string, max 50 chars; auto lowercased + spaces→underscores |
| `location.coordinates` | Required `[lng, lat]`; `lng ∈ [-180, 180]`, `lat ∈ [-90, 90]` |
| `label` | Optional string, max 100 chars |
| `metadata.notes` | Optional string, max 500 chars |
| `id` (path param) | Must be a valid Mongo ObjectId |

Invalid input returns `400` with a `{ "message": "..." }` body.

---

## 7. Error Response Shape

All non-2xx responses use:

```jsonc
{ "message": "Human-readable error" }
```

Common codes used by this feature: `400`, `401`, `403`, `404`, `500`.

---

## 8. Suggested UX Flows

### Booking flow — quick-pick pickup/drop

1. Call `GET /favorite-locations/tags` once on app load → cache for chip rendering.
2. On the booking screen, call `GET /favorite-locations` (or filter by `?tag=home` for the user's home only).
3. Render each favorite as a card showing `label || tag` and `address`.
4. On select, pass `location.coordinates` (swap to `[lat, lng]` for your map widget) and `address` into the booking form.

### Add new favorite from map picker

1. User long-presses a point on the map and chooses a tag from the chips returned by `/tags`.
2. Reverse-geocode the coordinate to fill `address` (frontend's responsibility — use your map provider).
3. `POST /favorite-locations` with the result.

### Custom tag entry

1. Show `predefined` tags as chips + an "Add custom" option.
2. When the user types a custom tag, call `POST` with that string in `tag`. The server normalizes it and marks `isCustomTag: true`.
3. Next call to `GET /tags` will return the new value in `custom`.

### Nearby suggestions

When the user opens the pickup picker with their current location available, call:

```
GET /favorite-locations/nearby?longitude=<lng>&latitude=<lat>&maxDistance=2000
```

to surface saved places within 2 km, ordered by proximity.

---

## 9. Coordinate Order Cheat-Sheet

| Context | Order |
|---------|-------|
| API request/response (`location.coordinates`) | **`[longitude, latitude]`** (GeoJSON) |
| Most map widgets (Leaflet, Google Maps `LatLng`) | `(latitude, longitude)` |
| URL query params on `/nearby` | `longitude=<lng>&latitude=<lat>` |

Convert at the boundary, not inside business logic.

---

## 10. Quick Reference

```
POST   /favorite-locations            → create
GET    /favorite-locations            → list (?tag, ?search, ?page, ?limit)
GET    /favorite-locations/tags       → predefined + user's custom tags
GET    /favorite-locations/nearby     → geo $near (?longitude, ?latitude, ?maxDistance, ?limit)
GET    /favorite-locations/:id        → single
PATCH  /favorite-locations/:id        → partial update (metadata shallow-merged)
DELETE /favorite-locations/:id        → delete
```

All routes require `Authorization: Bearer <jwt>`.

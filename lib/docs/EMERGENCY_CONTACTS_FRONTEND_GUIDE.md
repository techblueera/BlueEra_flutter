# Emergency Contacts — Frontend Integration Guide

This guide explains how the frontend integrates with the **Emergency Contacts** feature in `be_rider_service`. Emergency contacts let users save up to **3** "in case of emergency" people (name + phone) that the app can surface during rides, share with safety partners, or display on the user's profile.

---

## 1. Overview

Each emergency contact stores:

- A **name** (required, 1–100 chars)
- A **phone number** (`contactNo`, required, Indian format)
- An optional **relation** label (e.g. `"Mother"`, `"Spouse"`, `"Friend"`)
- An optional **priority** (1–3, lower = higher priority — used purely for UI ordering)

**Key business rules**

- A user can save **at most 3** emergency contacts. The server rejects further creates with HTTP `400`.
- A user cannot save the same phone number twice (per-user uniqueness). Duplicates return `409`.
- Phone numbers must match the Indian pattern `(?:\+91|91)?[6-9]\d{9}` (10 digits, leading 6–9, optional `+91` / `91` prefix). Spaces and dashes in the input are stripped before save.
- All endpoints are scoped to the authenticated user — cross-user reads/writes return `403`.

---

## 2. Authentication

Every endpoint requires a Bearer token in the `Authorization` header:

```
Authorization: Bearer <jwt>
```

The server resolves `userId` from the token (gRPC session validation, with JWT fallback). The frontend never sends `userId` in the body.

---

## 3. Base URL

Mounted at:

```
/emergency-contacts
```

Full Swagger UI is available at `/api-docs` (look for the **EmergencyContact** tag) and the raw OpenAPI spec at `/swagger.json`.

---

## 4. Data Model

### `EmergencyContact` response object

```jsonc
{
  "_id": "65fa1d1f3a1e8b001f9d4c01",
  "userId": "65f9b2a01c2d3e4f5a6b7c8d",
  "name": "Mom",
  "contactNo": "+919876543210",
  "relation": "Mother",
  "priority": 1,
  "createdAt": "2026-05-05T12:34:56.789Z",
  "updatedAt": "2026-05-05T12:34:56.789Z"
}
```

| Field        | Type                | Notes |
|--------------|---------------------|-------|
| `_id`        | string (ObjectId)   | |
| `userId`     | string              | Owning user (server-set). |
| `name`       | string              | 1–100 chars. |
| `contactNo`  | string              | Indian phone, normalized (no spaces/dashes). |
| `relation`   | string              | Optional, max 50 chars. Empty string when unset. |
| `priority`   | integer or `null`   | 1, 2, or 3. `null` means unranked. |
| `createdAt`  | ISO 8601 timestamp  | |
| `updatedAt`  | ISO 8601 timestamp  | |

---

## 5. Endpoints

### 5.1 Create — `POST /emergency-contacts`

Add a single emergency contact for the authenticated user.

**Request body**

```jsonc
{
  "name": "Mom",                   // required
  "contactNo": "+919876543210",    // required, Indian phone
  "relation": "Mother",            // optional
  "priority": 1                    // optional, 1-3
}
```

**Responses**

| Code | Meaning |
|------|---------|
| 201  | Created — returns the saved `EmergencyContact` |
| 400  | Validation error **or** per-user 3-contact cap reached |
| 401  | Missing or invalid token |
| 409  | Duplicate phone number for this user |
| 500  | Internal error |

**Cap-reached error body**

```jsonc
{
  "message": "You can save at most 3 emergency contacts. Delete one before adding another.",
  "limit": 3,
  "current": 3
}
```

**Example**

```ts
await fetch(`${API_BASE}/emergency-contacts`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    name: 'Mom',
    contactNo: '+919876543210',
    relation: 'Mother',
    priority: 1,
  }),
});
```

---

### 5.2 List — `GET /emergency-contacts`

Returns all the user's emergency contacts. Sorted by `priority` ascending (with unset priorities last) then `createdAt` ascending.

**Response — 200**

```jsonc
{
  "contacts": [ /* EmergencyContact[] */ ],
  "count": 2,
  "limit": 3
}
```

The `count` and `limit` fields make it easy for the UI to render `2 / 3 contacts saved`.

---

### 5.3 Count — `GET /emergency-contacts/count`

Lightweight helper that returns just the count and remaining slots — useful for hiding the "Add" button when the cap is reached without fetching the full list.

**Response — 200**

```jsonc
{ "count": 2, "limit": 3, "remaining": 1 }
```

---

### 5.4 Bulk replace — `PUT /emergency-contacts/bulk`

Replaces the user's **entire** emergency-contact set in one call. Intended for an "edit all" form where the UI sends the final desired state. Atomic via Mongo transaction when the deployment supports it (replica set), with a non-transactional fallback otherwise.

**Request body**

```jsonc
{
  "contacts": [
    { "name": "Mom",         "contactNo": "+919876543210", "relation": "Mother", "priority": 1 },
    { "name": "Dad",         "contactNo": "9876543211",    "relation": "Father", "priority": 2 },
    { "name": "Best Friend", "contactNo": "9876543212",    "relation": "Friend", "priority": 3 }
  ]
}
```

- `contacts` may be **empty** (`[]`) — that **clears all** the user's emergency contacts.
- `contacts.length` must be **≤ 3**.
- Phone numbers in the payload must be unique to each other.

**Response — 200** — same shape as the list endpoint:

```jsonc
{ "contacts": [ /* EmergencyContact[] */ ], "count": 3, "limit": 3 }
```

**Errors**

| Code | When |
|------|------|
| 400  | Too many contacts, missing required fields, or duplicate phones inside the payload |
| 409  | Duplicate phone numbers across the payload (race-condition fallback) |

> **Tip:** prefer `PUT /bulk` over chained `POST` / `DELETE` calls when the user is editing the whole list — it's atomic and avoids partial states.

---

### 5.5 Get one — `GET /emergency-contacts/:id`

Returns a single contact by Mongo ObjectId. Returns `403` if the contact belongs to another user, `404` if missing, `400` if `id` is not a valid ObjectId.

---

### 5.6 Update — `PATCH /emergency-contacts/:id`

Partial update — send any subset of `name`, `contactNo`, `relation`, `priority`. Per-user phone-number uniqueness is still enforced.

**Request body** (all fields optional)

```jsonc
{
  "name": "Mummy",
  "contactNo": "9876543299",
  "relation": "Mother",
  "priority": 2
}
```

**Responses**

| Code | Meaning |
|------|---------|
| 200  | Updated — returns the new `EmergencyContact` |
| 400  | Validation error / invalid id |
| 403  | Caller does not own the contact |
| 404  | Not found |
| 409  | Phone number already used by another contact for this user |

> To **clear** `priority`, send `"priority": null`.

---

### 5.7 Delete — `DELETE /emergency-contacts/:id`

Hard delete. Ownership-checked.

**Response — 200**

```jsonc
{ "message": "Emergency contact deleted.", "id": "65fa1d1f3a1e8b001f9d4c01" }
```

---

## 6. Validation Rules (Server-Side)

| Field        | Rule |
|--------------|------|
| `name`       | Required, non-empty string, trimmed, max 100 chars |
| `contactNo`  | Required, must match `^(?:\+91|91)?[6-9]\d{9}$`. Spaces and dashes are stripped before validation. |
| `relation`   | Optional string, max 50 chars |
| `priority`   | Optional integer in `[1, 3]`. `null` allowed to clear. |
| `id` (path)  | Must be a valid Mongo ObjectId |
| Per-user cap | At most **3** contacts per `userId` |
| Phone uniqueness | Per-user — duplicates of the same `contactNo` rejected with `409` |

Invalid input returns `400` with a `{ "message": "..." }` body.

---

## 7. Error Response Shape

All non-2xx responses use:

```jsonc
{ "message": "Human-readable error" }
```

Some errors include extra fields (e.g. `limit`, `current`, `remaining`) for UI use. Always treat `message` as the canonical human-readable text.

Common codes used by this feature: `400`, `401`, `403`, `404`, `409`, `500`.

---

## 8. Suggested UX Flows

### Onboarding / first-time setup

1. Show a one-screen form with **3 input rows** (name + phone + optional relation).
2. On submit, call **`PUT /emergency-contacts/bulk`** with the filled rows. Empty rows should be omitted from the payload.
3. The single bulk call replaces whatever was previously saved — perfect for an "edit all" form.

### Profile screen — "Emergency Contacts"

1. Call `GET /emergency-contacts` to render a card per saved contact.
2. Show "Add contact" button only when `count < limit` (or check `GET /emergency-contacts/count` if you want to skip the list payload).
3. Tap "Add" → modal form → `POST /emergency-contacts`.
4. Tap "Edit" on a card → `PATCH /emergency-contacts/:id`.
5. Swipe to delete → `DELETE /emergency-contacts/:id`.

### Phone-number input

- Accept formats like `9876543210`, `+91 98765 43210`, or `91-9876543210` — the server strips spaces/dashes and validates the canonical form.
- For best UX, mask the input as `+91 XXXXX XXXXX` but submit the raw 10-digit form (or the `+91` form). The server stores whatever passes validation.

### Cap-reached UX

- After hitting the cap, hide the "Add" button. If the user opens the form anyway, the server returns `400` with `{ message, limit: 3, current: 3 }` — show the message and offer "Manage existing contacts" as the action.

### Duplicate phone

- On `409`, show: *"You already have a contact with this number. Edit that one instead."*

---

## 9. Quick Reference

```
POST   /emergency-contacts            → create one (max 3 per user)
GET    /emergency-contacts            → list with {contacts, count, limit}
GET    /emergency-contacts/count      → {count, limit, remaining}
PUT    /emergency-contacts/bulk       → atomic replace-all (max 3, send [] to clear)
GET    /emergency-contacts/:id        → single
PATCH  /emergency-contacts/:id        → partial update
DELETE /emergency-contacts/:id        → delete
```

All routes require `Authorization: Bearer <jwt>`.

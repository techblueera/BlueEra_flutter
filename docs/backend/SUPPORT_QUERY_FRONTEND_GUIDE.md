# Support Queries ("Contact Us") — Frontend Integration Guide

This guide explains how the frontend integrates with the **Support Query** feature in `be_rider_service`. It powers the rider **"Contact Us"** sheet: the rider picks a category, describes their concern, and taps **Submit Query**. The query is saved and the support team is notified.

---

## 1. Overview

Each support query stores:

- A **category** (required, one of a fixed set — see below; defaults to `General`)
- A **description** (required, 1–500 chars — the "Describe your query" text)
- A server-managed **status** (`open` → `in-progress` → `resolved`)
- An optional **adminResponse** written by the support team

**Key business rules**

- Riders can **submit** and **view their own** queries only — there are no edit/delete endpoints for riders. Once submitted, a query is read-only from the app's side.
- On submit the server saves the query **and** fires a best-effort notification to the support team. Notification failures never fail the request.
- `status` and `adminResponse` are managed by support downstream — riders cannot set them.
- All endpoints are scoped to the authenticated rider — cross-user reads return `403`.

**Category values** (must match exactly — mirror the UI chips):

```
General
Document Issue
Verification Delay
Technical Issue
Other
```

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
/support-queries
```

Full Swagger UI is available at `/api-docs` (look for the **SupportQuery** tag) and the raw OpenAPI spec at `/swagger.json`.

---

## 4. Data Model

### `SupportQuery` response object

```jsonc
{
  "_id": "66a1d1f3a1e8b001f9d4c012",
  "userId": "65f9b2a01c2d3e4f5a6b7c8d",
  "category": "Document Issue",
  "description": "My Aadhaar upload keeps failing verification.",
  "status": "open",
  "adminResponse": "",
  "createdAt": "2026-07-03T12:34:56.789Z",
  "updatedAt": "2026-07-03T12:34:56.789Z"
}
```

| Field           | Type               | Notes |
|-----------------|--------------------|-------|
| `_id`           | string (ObjectId)  | |
| `userId`        | string             | Owning rider (server-set). |
| `category`      | string             | One of the 5 fixed values. |
| `description`   | string             | 1–500 chars, trimmed. |
| `status`        | string             | `open` \| `in-progress` \| `resolved`. Server-managed; starts at `open`. |
| `adminResponse` | string             | Support's reply. Empty string until answered. |
| `createdAt`     | ISO 8601 timestamp | |
| `updatedAt`     | ISO 8601 timestamp | |

---

## 5. Endpoints

### 5.1 Submit — `POST /support-queries`

Create a support query for the authenticated rider and notify support.

**Request body**

```jsonc
{
  "category": "Document Issue",                       // optional, defaults to "General"
  "description": "My Aadhaar upload keeps failing."   // required, 1-500 chars
}
```

**Responses**

| Code | Meaning |
|------|---------|
| 201  | Created — returns the saved `SupportQuery` |
| 400  | Validation error (invalid category, or missing / too-long description) |
| 401  | Missing or invalid token |
| 500  | Internal error |

**Validation error bodies**

```jsonc
// Invalid category
{ "message": "category must be one of: General, Document Issue, Verification Delay, Technical Issue, Other." }

// Missing description
{ "message": "description is required." }

// Too long
{ "message": "description must be at most 500 characters.", "limit": 500, "provided": 512 }
```

**Example**

```ts
await fetch(`${API_BASE}/support-queries`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    category: 'Document Issue',
    description: 'My Aadhaar upload keeps failing verification.',
  }),
});
```

---

### 5.2 List — `GET /support-queries`

Returns all queries submitted by the authenticated rider, **newest first**.

**Response — 200**

```jsonc
{
  "queries": [ /* SupportQuery[] */ ],
  "count": 2
}
```

---

### 5.3 Get one — `GET /support-queries/:id`

Returns a single query by Mongo ObjectId.

**Responses**

| Code | Meaning |
|------|---------|
| 200  | The `SupportQuery` |
| 400  | `id` is not a valid ObjectId |
| 403  | Query belongs to another user |
| 404  | Not found |

---

## 6. Validation Rules (Server-Side)

| Field         | Rule |
|---------------|------|
| `category`    | Optional. If sent, must be one of the 5 fixed values. Defaults to `General` when omitted/blank. |
| `description` | Required, non-empty string, trimmed, max 500 chars. |
| `id` (path)   | Must be a valid Mongo ObjectId. |
| `status`      | Not accepted from the client — server-managed. |
| `adminResponse` | Not accepted from the client — support-managed. |

Invalid input returns `400` with a `{ "message": "..." }` body.

---

## 7. Error Response Shape

All non-2xx responses use:

```jsonc
{ "message": "Human-readable error" }
```

Some errors include extra fields (e.g. `limit`, `provided`) for UI use. Always treat `message` as the canonical human-readable text.

Common codes used by this feature: `400`, `401`, `403`, `404`, `500`.

---

## 8. Suggested UX Flow

### The "Contact Us" sheet

1. Render the category chips from the fixed list; default the selection to **General**.
2. Bind the text area to `description`; show a live `N/500` counter and disable **Submit Query** when the field is empty or exceeds 500 chars.
3. On submit → `POST /support-queries` with `{ category, description }`.
4. On `201`, show a success toast (e.g. *"Your query has been submitted. Our team will get back to you."*) and close the sheet.
5. On `400`, show the returned `message` inline.

### "My queries" history (optional)

- Call `GET /support-queries` to list the rider's past queries with their `status` badge (`open` / `in-progress` / `resolved`).
- Tap a row → `GET /support-queries/:id` to show the full description and `adminResponse` when present.

> There is no edit or delete for riders. If a rider needs to change something, they submit a new query.

---

## 9. Backend Configuration Note

The submit notification to support requires the `SUPPORT_NOTIFY_USER_ID` environment variable (the support team's user ID). If unset, queries still save normally — the notification step is skipped with a logged warning. The notification is emitted via the existing Kafka notification flow with `operation: "SUPPORT_QUERY_CREATED"`; the downstream notification service must handle that operation to deliver the alert.

---

## 10. Quick Reference

```
POST   /support-queries        → submit a query (saves + notifies support)
GET    /support-queries        → list my queries {queries, count}, newest first
GET    /support-queries/:id    → single query (own only)
```

All routes require `Authorization: Bearer <jwt>`.

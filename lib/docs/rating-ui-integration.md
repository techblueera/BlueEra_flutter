# Ratings — UI Integration Guide

Rating submit/read for **businesses** and **user profiles**. The rating data
itself is owned by **be_user_service**; **be_other_service** only surfaces the id
and the totals you need to call it.

**Flow:** user opens a business listing (from other-service search) → taps rate →
app POSTs to be_user_service keyed on the **business id** → user-service
recomputes the business's average → the new average flows back into the
other-service listing payload on the next fetch (≤30s, gRPC cache TTL).

> ⚠️ **Read §1 first.** A profile payload carries **three different ObjectIds**
> and the rating endpoints accept only one of them. Sending the wrong one used to
> return `200 Rating submitted successfully` and silently write a row nothing
> could ever read. That now returns **404** — see §4.

---

## 1. Which id do I rate against?

`POST .../business/{businessId}/ratings` expects the **be_user_service
`businesses._id`** — the same value the JWT carries as `business_id`. It is *not*
the other-service profile id and *not* the owner's user id.

| Key in the profile payload | Collection | Use it for |
|---|---|---|
| `profile._id` | other-service `businessprofiles` | fetching gallery / staff / timings / contactUs |
| `profile.userId` | user-service `users` | follow, chat, owner lookup |
| **`profile.businessId`** | **user-service `businesses`** | **ratings, business detail** ← |

`profile.businessId` is **new**. Before it existed the app had no way to derive
this id from a search result, which is the root cause of the "rating not working"
reports.

```jsonc
// GET /api/other-service/business-profile/search  →  data[].profile
{
  "_id":     "6a3a106979cd1a691c0d7b33",   // businessprofiles  — NOT ratable
  "userId":  "6a3a0f5b8050e1e108a2010e",   // users             — NOT ratable
  "businessId": "6a3a10a4…",               // businesses        — rate against THIS
  "avg_rating": 4.5,
  "total_ratings": 12,
  "rating": 4.5,
  "profileName": "Agency for Placement"
}
```

`businessId` is `""` when the owner has no business record in user-service, or
when the gRPC enrichment call fails. **Hide the rating UI when it is empty** —
do not fall back to `_id` or `userId`.

### Where `businessId` is available

| Endpoint | Auth |
|---|---|
| `GET /api/other-service/business-profile?type=other` | ✅ owner's own profile |
| `GET /api/other-service/business-profile/search` | – |
| `GET /api/other-service/business-profile/{id}/full` | – |

Same keys, same position (on `profile`, or on `data` for the first one).

---

## 2. Endpoint map — what is live, 410, and 404

Only **three** rating endpoints are live. Several URLs currently in the app were
never implemented or have been retired.

### ✅ Live

| Method | Path | Auth |
|---|---|---|
| `POST` | `/api/user-service/business/{businessId}/ratings` | Bearer |
| `GET`  | `/api/user-service/business/{businessId}/ratings` | public |
| `POST` | `/api/user-service/user/{userProfileId}/ratings` | Bearer |

### ⛔ Retired — returns **410 Gone**, not a redirect

These respond `410 {"success": false, "code": "endpoint_deprecated"}` with
`Deprecation` / `Sunset` headers. They do **not** fall through to a handler.

| Method | Path |
|---|---|
| `DELETE` | `/api/user-service/business/{businessId}/ratings` |
| `GET` | `/api/user-service/business/{businessId}/ratings/filter` |
| `GET` | `/api/user-service/business/{businessId}/rating-details` |
| `GET` | `/api/user-service/user/{userProfileId}/ratings` |
| `GET` | `/api/user-service/user/{userProfileId}/rating-details` |

### ❌ Never existed — returns **404**

These URLs are built in the app today and cannot succeed. Remove them.

| App symbol | URL it builds |
|---|---|
| `submitRatingToBusiness` | `user-service/business/rating/{id}` |
| `getBusinessDetailedRating` | `user-service/business/business/{id}/ratings/count` |
| `getBusinessRatingsSummary` | `user-service/business/{id}/rating-summary` |
| `getRattingSummary` | `user-service/business/rating/{id}/summary` |
| `getCountRating` | `user-service/business/getCountOfRating/{id}` |

> ⚠️ There are **two** submit methods on `view_business_details_controller`.
> `submitRatingToBusinessAccount` (→ `/{id}/ratings`) is correct;
> `submitRatingToBusiness` (→ `/rating/{id}`) 404s. Any screen wired to the
> second one fails silently. Consolidate on the first.

---

## 3. Submit a rating

`POST /api/user-service/business/{businessId}/ratings` — `Authorization: Bearer <token>`

```json
{ "rating": 3, "comment": "wonderful" }
```

`rating` must be a **number** 1–5 (not a string). `comment` is optional.

Re-posting as the same user **updates** the existing rating (upsert) — there is
no separate edit call, and no 409 on a normal repeat.

**`200`**

```json
{
  "status": true,
  "message": "Rating submitted successfully.",
  "data": {
    "_id": "6a687603c0fe0e5cb455bc8b",
    "id": "6a687603c0fe0e5cb455bc8b",
    "user": "6a634e79562b9bae1171bc6c",
    "rateableId": "6a3a1067709f7e99cf8a91b2",
    "rateableType": "Business",
    "rating": 3,
    "comment": "wonderful",
    "created_at": "2026-07-28T09:27:31.351Z",
    "formatted_created_at": "28 July 2026, 02:57 PM",
    "__v": 0
  }
}
```

### Error responses — two are new

| Code | `message` | Meaning |
|---|---|---|
| `400` | `A valid target ID is required.` | id is not a valid ObjectId |
| `400` | `Rating must be a number between 1 and 5.` | bad/missing `rating` |
| `400` | `You cannot rate yourself.` | user rating their own profile |
| **`400`** | **`You cannot rate your own business.`** | **NEW** — owner rating their own business |
| `401` | `Authentication error.` | missing/invalid token |
| **`404`** | **`No business found with this id.`** | **NEW** — id doesn't resolve |
| `409` | `You have already rated this profile.` | concurrent double-submit race |
| `500` | `An internal server error occurred.` | — |

> ⚠️ **Behaviour change.** This endpoint previously returned `200` for *any*
> well-formed ObjectId. If you see `404 No business found with this id.`, the app
> is sending the wrong id — see §1. Surface the server `message` rather than a
> generic failure toast so this is diagnosable in the field.

For user profiles the shape is identical at
`POST /api/user-service/user/{userProfileId}/ratings`, with
`rateableType: "User"` and `404 No user found with this id.`

---

## 4. List ratings

`GET /api/user-service/business/{businessId}/ratings?page=1&limit=10` — public.

```json
{
  "status": true,
  "data": [
    {
      "_id": "6a687603c0fe0e5cb455bc8b",
      "rateableId": "6a3a1067709f7e99cf8a91b2",
      "rateableType": "Business",
      "rating": 3,
      "comment": "wonderful",
      "created_at": "2026-07-28T09:27:31.351Z",
      "formatted_created_at": "28 July 2026, 02:57 PM",
      "user": {
        "_id": "6a634e79562b9bae1171bc6c",
        "name": "NK Furniture",
        "username": "nk_furniture",
        "profile_image": "https://…",
        "account_type": "BUSINESS",
        "business_details": [{ "business_name": "…", "logo": "…", "business_isVerified": true }]
      }
    }
  ],
  "pagination": { "totalRecords": 12, "totalPages": 2, "currentPage": 1 }
}
```

> ⚠️ **Date field is `created_at`, not `createdAt`.** The current
> `BusinessRatingsData.fromJson` reads `json['createdAt']`, so every timestamp
> parses as `null`. Read `created_at`, or `formatted_created_at` for a
> ready-to-display IST string.

**Known limitation — pagination is not stable.** The documents have no
`createdAt` field, so the server's sort is a no-op and page 2 may repeat or skip
rows from page 1. Prefer loading a single large page until this is fixed
server-side; do not build infinite scroll on it yet.

---

## 5. Where to get the average / star breakdown

`rating-details` (the star-count histogram) is **410**. Use these instead:

**Listing card** — read straight off the profile payload from §1:
`avg_rating` (double), `total_ratings` (int), `rating` (same as `avg_rating`,
rounded to 1 dp, kept for existing readers).

**Business detail screen** — `GET /api/user-service/business/{businessId}`
(Bearer) additionally returns the caller's own rating:

| Field | Type | Note |
|---|---|---|
| `avg_rating` | int | rounded |
| `total_ratings` | int | |
| `user_has_rated` | bool | authenticated caller only |
| `user_rating` | int \| null | prefill the star picker with this |

There is **no live endpoint** for the 1★–5★ count breakdown. If a screen needs
it, ask backend to un-retire `rating-details` — the controller still exists, only
the route is gated.

---

## 6. Freshness

Submitting a rating updates the business's stored average immediately, but
other-service reads it over gRPC behind a **30s cache**. After a successful
submit, update the star display optimistically from the `200` response rather
than re-fetching the listing — a refetch inside 30s can still show the old value.

---

## 7. Migration checklist

1. Read `profile.businessId` from the other-service payload; hide rating UI when
   it is `""`.
2. Submit via `POST /user-service/business/{businessId}/ratings` only. Delete
   `submitRatingToBusiness`, `getBusinessDetailedRating`,
   `getBusinessRatingsSummary`, `getRattingSummary`, `getCountRating`.
3. Handle the new `404` and `You cannot rate your own business.` `400`; show the
   server `message`.
4. Parse `created_at` (or `formatted_created_at`), not `createdAt`.
5. Read `avg_rating` / `total_ratings` from the listing payload; drop any call to
   `rating-details`.
6. Prefill the star picker from `user_rating` on the business detail response.

## 8. Not covered / still open

- Rating list pagination ordering (§4) — server-side fix pending.
- 1★–5★ histogram — no live endpoint.
- Deleting a rating — `DELETE .../ratings` is 410; no replacement.
- `searchFullBusinessProfile` in other-service is implemented but **not routed**;
  ignore it.

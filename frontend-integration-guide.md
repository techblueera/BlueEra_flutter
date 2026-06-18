# Video Platform — Frontend Integration Guide

This guide documents the backend APIs available to the frontend, based on the
current route definitions and controller implementations. Where the controller
behavior differs from the Swagger annotations, **the controller behavior is
documented here** (and the difference is flagged), because that's what the API
actually returns.

> **Coverage note**
> - **Video** and **Likes** endpoints are documented from both routes *and* controllers (full detail).
> - **Admin** endpoints are documented from routes/Swagger only — I don't have `admin.controller.js` yet, so request/response details there are best-effort. Send me that file for exact shapes.
> - **Likes** controller (`videoLike.controller.js`) was not provided either; like shapes come from the route Swagger. Send it if you want exact response bodies verified.

---

## 1. Base URL & Conventions

All routers in `index.js` are mounted on a single parent router (`/videos`, `/likes`, `/admin`, …). That parent router is itself mounted under an app-level prefix in your `app.js` (commonly `/api` or `/api/v1`).

```
{{BASE_URL}} = https://<your-host>/<api-prefix>
            e.g. https://api.example.com/api
```

> ⚠️ **Confirm the prefix.** I don't have `app.js`, so the `/api` part is an assumption. All paths below are written relative to `{{BASE_URL}}`. So "`GET /videos/hot/short`" means `GET {{BASE_URL}}/videos/hot/short`.

- **Content type:** JSON for all request bodies (`Content-Type: application/json`). The upload route's controller reads JSON, not multipart, even though it deals with video.
- **IDs:** MongoDB ObjectIds — 24-character hex strings (`^[0-9a-fA-F]{24}$`).
- **Dates:** ISO 8601 strings (e.g. `2023-10-01T12:34:56Z`).

---

## 2. Authentication

Protected endpoints require a **JWT** sent as a Bearer token:

```
Authorization: Bearer <token>
```

The `protect` middleware first tries gRPC session validation (using a `sessionId` inside the token) and transparently falls back to plain JWT verification. From the frontend's perspective you don't need to care which path runs — **just send the token you received at login**.

### 401 responses you should handle

| Message | Meaning | Suggested frontend action |
|---|---|---|
| `Not authorized, no token provided.` | Missing/!Bearer header | Redirect to login |
| `Not authorized, token has expired.` | JWT expired | Refresh token, then retry |
| `Not authorized, token invalid or malformed.` | Bad token | Force re-login |

All 401s have shape: `{ "success": false, "message": "..." }`.

### A minimal API client (fetch)

```js
const BASE_URL = "https://<your-host>/api"; // confirm prefix

function getToken() {
  return localStorage.getItem("accessToken"); // or your auth store
}

async function api(path, { method = "GET", body, auth = false, query } = {}) {
  const url = new URL(`${BASE_URL}${path}`);
  if (query) {
    Object.entries(query).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== "") url.searchParams.set(k, v);
    });
  }

  const headers = { "Content-Type": "application/json" };
  if (auth) headers.Authorization = `Bearer ${getToken()}`;

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw Object.assign(new Error(data.message || `HTTP ${res.status}`), {
      status: res.status,
      data,
    });
  }
  return data;
}
```

All examples below use this `api()` helper.

---

## 3. Common Response Shapes

### 3.1 Unified Video Feed

Used by: **channel feed**, **user videos**, **search**, **category**, and **single video** (`GET /videos/:videoId`).

```jsonc
{
  "success": true,
  "message": "Channel feed retrieved successfully",
  "data": {
    "success": true,
    "feedType": "channel",      // "channel" | "search" | "category" | "single"
    "videos": [ /* VideoFeedItem[] */ ]
  },
  "metadata": {
    "totalVideos": 42,
    "algorithm": "channel",
    "lastUpdated": "2023-10-01T12:34:56Z",
    "version": "2.0",
    "composition": { "channel": 42 }
  },
  "timestamp": "2023-10-01T12:34:56Z",
  "version": "2.1",
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalVideos": 42,
    "totalPages": 3,
    "hasMore": true
  }
}
```

> ⚠️ **`GET /videos/:videoId` quirk:** for the single-video endpoint, `data.videos` is a **single object**, not an array. Every other feed endpoint returns `data.videos` as an **array**. Handle both: `Array.isArray(data.videos) ? data.videos : [data.videos]`.

### 3.2 VideoFeedItem

Each item in a feed wraps the raw video plus resolved author/channel/interaction data:

```jsonc
{
  "videoId": "60d5...",
  "position": 1,
  "score": 0,
  "reason": "channel",          // matches feedType source
  "video": { /* Video object — see 3.3 — bankDetails removed */ },
  "author": {
    "_id": "60d5...",
    "username": "john_doe",
    "name": "John Doe",
    "profile_image": "https://...",
    "designation": "Content Creator",
    "account_type": "BUSINESS",  // or null
    "isVerified": false,
    "followersCount": 0
    // business accounts also include: natureOfBusiness, categoryOfBusiness, subCategoryOfBusiness
  },
  "channel": {
    "_id": "60d5...",
    "name": "Travel Channel",
    "username": "travel_channel",
    "bio": "Discover new places!",
    "logoUrl": "https://...",
    "coverImageUrl": "https://...",
    "category": "travel",
    "websites": null,
    "gstCode": "GST123456",
    "isVerified": true,
    "claimedBy": "60d5...",
    "isFollowing": false,
    "createdAt": null,
    "updatedAt": null
  },
  "interactions": {
    "isLiked": true,
    "isBookmarked": false,       // currently always false (not yet wired)
    "isFollowing": true
  },
  "metadata": {
    "addedAt": "2023-10-01T12:34:56Z",
    "source": "channel",
    "watchedBefore": false       // currently always false
  }
}
```

> **Author/channel come from gRPC services.** If the lookup fails, you'll still get the object with the `_id` populated and the rest `null`/`false` — so always null-check before rendering (`author?.username ?? "Unknown"`).
> `interactions.isBookmarked` and `metadata.watchedBefore` are placeholders (hardcoded `false`) today — don't build UI that depends on them being real yet.

### 3.3 Video object (full shape, from the Mongoose model)

```jsonc
{
  "_id": "60d5...",
  "userId": "60d5...",
  "channelId": "60d5...",          // optional
  "seriesId": "60d5...",           // optional (OTT/series)
  "episodeNumber": 1,              // present only if seriesId set
  "type": "short",                 // "short" | "long"
  "status": "published",           // see status enum below
  "rejectionReason": null,         // string when status === "rejected"
  "title": "My Travel Vlog",
  "subheading": "...",
  "description": "...",
  "caption": "Adventure awaits!",  // used by shorts
  "coverUrl": "https://...",
  "videoUrl": "https://...",       // original source
  "duration": 360,                 // seconds
  "transcodedUrls": {
    "master": "https://....m3u8",
    "360p": "https://...",
    "432p": "https://...",
    "540p": "https://...",
    "720p": "https://...",
    "720p-high": "https://...",
    "1080p": "https://...",
    "1200p": "https://..."
  },
  "thumbnails": { "default": "", "high": "", "medium": "", "low": "" },
  "visibility": "public",          // "public" | "private" | "unlisted"
  "tags": ["travel", "vlog"],
  "keywords": ["mountain", "adventure"],
  "categories": [                  // populated objects in feed responses
    { "_id": "60d5...", "name": "Travel", "slug": "travel", "description": "..." }
  ],
  "location": { "name": "Mountain Range", "lat": 45.253, "lng": -68.469 },
  "song": { "id": "60d5...", "name": "Song", "artist": "Artist", "coverUrl": "https://..." },
  "isCollaboration": false,
  "allowComments": true,
  "allowGifting": false,
  "taggedUsers": [ /* resolved to user objects in feed responses */ ],
  "isMatureContent": false,
  "relatedVideoLink": "https://...",
  "acceptBookingsOrEnquiries": false,
  "isFlagged": false,
  "reports": [{ "userId": "...", "reason": "...", "createdAt": "..." }],
  "stats": { "views": 1000, "likes": 500, "shares": 200, "comments": 150 },
  "createdAt": "2023-10-01T12:34:56Z",
  "updatedAt": "2023-10-02T12:34:56Z"
}
```

> **`bankDetails` is always stripped** from every read response. It's never returned to clients.

**Status enum (model source of truth):**
`creator_draft`, `submitted_for_review`, `processing`, `published`, `failed`, `approved_published`, `rejected`

> ⚠️ The Swagger lists an older set (`draft/processing/published/failed`). Use the model's list above. Note the channel-feed `status` **filter** only accepts `draft | processing | published | failed | all` (see that endpoint) — which doesn't fully line up with the model's real statuses. If you need to filter owner drafts, confirm with backend which value to send (likely needs a fix to accept `creator_draft`).

### 3.4 Generic error shape

Most error responses look like:

```json
{ "message": "Failed to retrieve video", "error": "..." }
```

Auth errors (from `protect`) use `{ "success": false, "message": "..." }`. So when handling errors, read `data.message` (present in both).

---

## 4. Video Endpoints

### Quick reference

| Method | Path | Auth | Response shape |
|---|---|:---:|---|
| POST | `/videos/upload` | ✅ | Custom (`{ message, videoId, ... }`) |
| GET | `/videos/upload-status` | ✅ | Cooldown status object |
| GET | `/videos/metadata/:videoId` | ❌ | `{ success, data: Video }` |
| GET | `/videos/:videoId` | ✅ | Unified Feed (single object in `data.videos`) |
| GET | `/videos/hot/:type` | ❌ | `{ success, data: Video[], pagination }` |
| GET | `/videos/channel/:channelId` | ✅ | Unified Feed |
| GET | `/videos/users/:userId/videos` | ✅ | Unified Feed |
| GET | `/videos/category/:categoryId` | ❌ | Unified Feed |
| GET | `/videos/search` | ❌ | Unified Feed |
| PUT | `/videos/:videoId` | ✅ | `{ success, data: Video }` |
| DELETE | `/videos/:videoId` | ✅ | `{ success, message }` |
| POST | `/videos/batch-prepare` | ✅ | `{ success, message, data }` |
| GET | `/videos/categories` | ❌ | ⚠️ **Unreachable** — see §6.1 |

---

### 4.1 POST `/videos/upload` — Register an uploaded video & start transcoding

**Auth:** required.

This does **not** upload the file bytes. It registers a video whose file you've **already uploaded** (you pass the resulting `videoUrl` + `videoKey`) and kicks off transcoding. Typical flow:

1. Upload the file via the chunked upload routes (`/upload/...` — `upload.routes.js`, not covered here) → receive `videoUrl` + `videoKey` (and maybe `coverUrl`).
2. Call this endpoint with metadata + those URLs → get back a `videoId` with `status: "processing"`.
3. Poll `GET /videos/metadata/:videoId` (or `/videos/:videoId`) until `status` becomes `published`/`approved_published` and `transcodedUrls` populate.

**Required fields:** `title`, `type` (`short`|`long`), `videoUrl`, `videoKey`.

**Body fields:**

| Field | Type | Notes |
|---|---|---|
| `title` | string | required, 1–200 chars |
| `type` | `short`\|`long` | required |
| `videoUrl` | string (uri) | required — from upload step |
| `videoKey` | string | required — storage key from upload step |
| `description` | string | used for `long`; for `short` falls back into `caption` |
| `caption` | string | shorts |
| `coverUrl` | string (uri) | optional |
| `channelId` | ObjectId | optional — omit to post as the user |
| `categories` | string[] / JSON string | ObjectIds; accepts a real array or a stringified array |
| `tags`, `keywords` | string[] / JSON string | same parsing flexibility |
| `taggedUsers` | ObjectId[] | |
| `taggedChannelProducts` | string[] | |
| `visibility` | `public`\|`private`\|`unlisted` | default `public` |
| `duration` | number | seconds, clamped 0–28800; invalid → 0 |
| `location` | `{ name, lat, lng }` or JSON string | needs valid numeric lat/lng or it's dropped |
| `song` | `{ id, name, artist }` | |
| `isCollaboration`, `allowComments`, `isMatureContent`, `acceptBookingsOrEnquiries`, `isBrandPromotion` | boolean | strings like `"true"` are accepted |
| `brandPromotionLink` | string (uri) | only stored if `isBrandPromotion` is true |
| `relatedVideoLink` | string (uri) | |
| `bankDetails` | object | stored, never returned |

**Success `200`:**

```json
{
  "message": "Video Uploaded Successfully",
  "videoId": "60d5...",
  "videoUrl": "https://...",
  "coverUrl": "https://...",
  "status": "processing"
}
```

> If transcoding fails to start, you still get `200` but `status` will be `"failed"`.

**Errors:** `400` (missing/invalid title, type, videoUrl, or videoKey; malformed array JSON), `401`, `500`.

```js
const res = await api("/videos/upload", {
  method: "POST",
  auth: true,
  body: {
    title: "My Amazing Video",
    type: "short",
    caption: "Check this out!",
    videoUrl: "https://cdn.example.com/raw/abc.mp4",
    videoKey: "videos/<userId>/abc.mp4",
    coverUrl: "https://cdn.example.com/covers/abc.jpg",
    categories: ["60d5f9b8b60e4661d8f0a1b2"],
    tags: ["travel", "vlog"],
    visibility: "public",
    duration: 42,
  },
});
// poll res.videoId for status
```

---

### 4.2 GET `/videos/upload-status` — Can the user upload now?

**Auth:** required. Enforces a **60-minute cooldown** between uploads. Use it to enable/disable the upload button.

Returns the object produced by the cooldown service (exact shape lives in `uploadService.js`, not provided). Expect something like a `canUpload` boolean and, when blocked, remaining-time info. **Send me `uploadService.js` if you want the precise fields.**

```js
const status = await api("/videos/upload-status", { auth: true });
// render upload button based on status
```

**Errors:** `401`, `500`.

---

### 4.3 GET `/videos/metadata/:videoId` — Single video (raw) + increment views

**Auth:** not required (but reads the token if present, to allow owners to view private/unpublished videos).

> ⚠️ **Side effect: this increments `stats.views` on every call.** Use it when a user actually opens/plays a video — **not** for list rendering or background refreshes, or you'll inflate view counts.

Returns the raw video (categories + song populated, `bankDetails` removed):

```json
{ "success": true, "data": { /* Video object */ } }
```

**Access rules:** if the video is not `public` **and** not `published`, only the owner (matching token) can read it — otherwise `403`.

**Errors:** `400` (bad ObjectId), `403`, `404`, `500`.

```js
const { data: video } = await api(`/videos/metadata/${videoId}`);
```

---

### 4.4 GET `/videos/:videoId` — Single video as a feed item (no view increment)

**Auth:** required.

Returns the **Unified Feed** shape with author/channel/interactions resolved, but `data.videos` is a **single object** (not an array). Does **not** increment views.

> ⚠️ **Returns `200`, not `404`, when the video doesn't exist** — with `message: "Video not found"`, `feedType: "single"`, and `data.videos: []` (an empty array in the not-found case). Check `data.videos` is non-empty before using it.

**When to use which single-video endpoint:**

| | `/videos/metadata/:id` | `/videos/:id` |
|---|---|---|
| Auth | Not required | Required |
| Increments views | **Yes** | No |
| Includes author/channel/isLiked | No | **Yes** |
| Not-found status | `404` | `200` + empty |

```js
const resp = await api(`/videos/${videoId}`, { auth: true });
const item = Array.isArray(resp.data.videos) ? resp.data.videos[0] : resp.data.videos;
if (!item) { /* not found */ }
```

**Errors:** `400`, `500` (and `200`-empty for not found).

---

### 4.5 GET `/videos/hot/:type` — Trending videos

**Auth:** not required. `:type` must be `short` or `long`.

Ranked by `hotnessScore = views*0.6 + likes*0.3 + comments*0.1`, then newest.

**Query:** `limit` (1–50, default 10), `page` (default 1).

> ⚠️ **Different response shape** — this is *not* the unified feed. `data` is a flat **array of Video objects** (categories + song populated, `isLiked` hardcoded `false`, no `author`/`channel` resolution):

```json
{
  "success": true,
  "data": [ /* Video[] */ ],
  "pagination": { "page": 1, "limit": 10, "total": 120, "totalPages": 12 }
}
```

```js
const { data: videos, pagination } = await api(`/videos/hot/short`, {
  query: { limit: 10, page: 1 },
});
```

**Errors:** `400` (bad type), `500`.

---

### 4.6 GET `/videos/channel/:channelId` & 4.7 GET `/videos/users/:userId/videos`

**Auth:** required. Both hit the **same** controller; one filters by `channelId`, the other by `userId`. Both return the **Unified Feed**.

**Query params (identical for both):**

| Param | Type | Default | Notes |
|---|---|---|---|
| `limit` | int 1–50 | 20 | |
| `page` | int | 1 | |
| `status` | enum | `published` | Owner-only filter; accepts `draft`\|`processing`\|`published`\|`failed`\|`all` (see status caveat §3.3) |
| `typeFilter` | `short`\|`long` | — | |
| `sortBy` | `latest`\|`oldest`\|`popular`\|`trending` | `latest` | |
| `post_via` | `user`\|`channel`\|`all` | `all` | `channel` = only videos posted under a channel; `user` = only videos with no channel |

**Visibility logic:** if the requester (from token) is **not** the owner of the requested id, results are forced to `status: published` + `visibility: public`. Owners can see their own non-public videos via `status`.

```js
const feed = await api(`/videos/channel/${channelId}`, {
  auth: true,
  query: { page: 1, limit: 20, sortBy: "popular", typeFilter: "short" },
});
const items = feed.data.videos; // array
```

**Errors:** `400` (bad `post_via`), `401`, `403`, `404`, `500`.

---

### 4.8 GET `/videos/category/:categoryId` — Videos in a category

**Auth:** not required. Always returns published + public videos. **Unified Feed.**

**Query:** `limit` (1–50, default 20), `page`, `sortBy` (`latest`|`oldest`|`popular`|`trending`).

```js
const feed = await api(`/videos/category/${categoryId}`, {
  query: { sortBy: "trending", limit: 20 },
});
```

**Errors:** `400` (missing/invalid categoryId), `404`, `500`.

---

### 4.9 GET `/videos/search` — Search with filters

**Auth:** not required. **Unified Feed** (`feedType: "search"`).

Uses Atlas Search when enabled on the backend, otherwise a regex fallback — transparent to you.

**Query params:**

| Param | Type | Default | Notes |
|---|---|---|---|
| `query` | string | — | **required** |
| `category` | ObjectId | — | |
| `channelId` | string | — | |
| `userId` | ObjectId | — | |
| `type` | `short`\|`long` | — | |
| `minDuration` / `maxDuration` | int (sec) | — | |
| `startDate` / `endDate` | date | — | ISO date strings |
| `sortBy` | `relevance`\|`uploadDate`\|`views`\|`likes` | `relevance` | |
| `sortOrder` | `asc`\|`desc` | `desc` | |
| `visibility` | `public`\|`private`\|`unlisted` | `public` | |
| `page` | int | 1 | |
| `limit` | int 1–50 | 20 | |

```js
const feed = await api("/videos/search", {
  query: { query: "travel vlog", type: "short", sortBy: "views", page: 1, limit: 20 },
});
```

**Errors:** `400` (missing query / invalid date), `500`.

---

### 4.10 PUT `/videos/:videoId` — Edit video (owner only)

**Auth:** required. Only the **owner** can edit (else `403`).

**Editable fields (anything else is ignored):**
`title`, `description`, `caption`, `visibility`, `tags`, `keywords`, `categories`, `location`, `song`, `allowComments`, `isMatureContent`, `relatedVideoLink`, `acceptBookingsOrEnquiries`, `isBrandPromotion`, `brandPromotionLink`.

`tags`/`keywords`/`categories`/`location` accept the same flexible array/JSON parsing as upload.

**Success `200`:** `{ "success": true, "data": { /* updated Video, bankDetails removed */ } }`

```js
const { data: updated } = await api(`/videos/${videoId}`, {
  method: "PUT",
  auth: true,
  body: { title: "New title", visibility: "unlisted", tags: ["a", "b"] },
});
```

**Errors:** `400` (bad ObjectId), `401`, `403` (not owner), `404`, `500`.

---

### 4.11 DELETE `/videos/:videoId` — Delete video (owner or admin)

**Auth:** required. Allowed for the **owner** or an **Admin** account (`account_type === "Admin"`). Permanent delete.

**Success `200`:** `{ "success": true, "message": "Video deleted" }`

```js
await api(`/videos/${videoId}`, { method: "DELETE", auth: true });
```

**Errors:** `400`, `401`, `403`, `404`, `500`.

---

### 4.12 POST `/videos/batch-prepare` — Warm the cache for a set of videos

**Auth:** required. Mostly an optimization hook (pre-caches published+public videos). Useful before showing a known list.

**Body:** `{ "videoIds": ["<id>", ...] }` — 1–100 valid ObjectIds (invalid ones are dropped).

**Success `200`:**

```json
{
  "success": true,
  "message": "3 videos prepared",
  "data": [{ "videoId": "...", "title": "...", "userId": "...", "cached": true }]
}
```

**Errors:** `400` (empty/all-invalid/over 100), `401`, `500`.

---

## 5. Likes Endpoints

Mounted at `/likes`. Here `:id` is the **video** id (except the user-likes routes where it's the user id). Shapes below come from the route Swagger — send `videoLike.controller.js` to confirm exact bodies.

| Method | Path | Auth | Purpose |
|---|---|:---:|---|
| POST | `/likes/:id/like` | ✅ | Like a video |
| DELETE | `/likes/:id/like` | ✅ | Unlike (soft delete) |
| GET | `/likes/:id/like/status` | ✅ | Did **I** like this video? |
| GET | `/likes/:id/likes` | ❌ | Paginated likers of a video |
| GET | `/likes/users/:id/likes` | ❌ | Paginated likes made by a user |
| POST | `/likes/users/:userId/likes/status` | ❌ | Bulk like-status for many videos |

### 5.1 POST `/likes/:id/like`
Like a video. **`201`** → the created like record. `400` if already liked, `404` video missing.
```js
await api(`/likes/${videoId}/like`, { method: "POST", auth: true });
```

### 5.2 DELETE `/likes/:id/like`
Soft-delete the like. **`200`** → `{ "success": true, "data": { "message": "Unliked" } }`. `404` if no like.
```js
await api(`/likes/${videoId}/like`, { method: "DELETE", auth: true });
```

### 5.3 GET `/likes/:id/like/status`
Whether the **authenticated** user liked this video.
**`200`** → `{ "success": true, "data": { "liked": true } }`
```js
const { data } = await api(`/likes/${videoId}/like/status`, { auth: true });
// data.liked
```

### 5.4 GET `/likes/:id/likes`
Paginated likers of a video (with full video data). **Query:** `page` (default 1), `limit` (1–100, default 50).
**`200`** → `{ "likes": [...], "total": 42, "page": 1, "pages": 3 }`

### 5.5 GET `/likes/users/:id/likes`
Paginated likes a given user made. Same pagination, same `LikeList` shape. Great for a user's "Liked videos" tab.

### 5.6 POST `/likes/users/:userId/likes/status` — Bulk status
Best for rendering a feed: check many videos at once.
**Body:** `{ "videoIds": ["<id1>", "<id2>"] }`
**`200`** → `{ "success": true, "data": { "<id1>": true, "<id2>": false } }`
```js
const { data: likeMap } = await api(`/likes/users/${userId}/likes/status`, {
  method: "POST",
  body: { videoIds: visibleVideoIds },
});
```

> Tip: feed endpoints already include `interactions.isLiked` for the requesting user, so you mainly need the bulk endpoint for the `hot` feed (which doesn't resolve likes) or when stitching data client-side.

---

## 6. Admin Endpoints

Mounted at `/admin`, all `protect`-ed. Documented from Swagger only — **send `admin.controller.js` for exact response bodies and any role checks.**

| Method | Path | Key query params |
|---|---|---|
| GET | `/admin/video-stats` | `start_date`, `end_date`, `filter_type` (`day`\|`week`\|`month`\|`year`), `video_type` (`short`\|`long`) |
| GET | `/admin/video-overview-chart` | `year`, `filter_type` (`all`\|`views`\|`likes`\|`comments`), `video_type` |
| GET | `/admin/video-details` | `limit`, `offset`, `start_date`, `end_date`, `search_query`, `category_id`, `sort_by`, `sort_order` (`asc`\|`desc`), `video_type` |
| GET | `/admin/users/:userId/details` | `limit`, `page`, `sort_by`, `sort_order`, `filter_type` (`short`\|`long`\|`published`\|`draft`) |

- **`/admin/video-stats`** — dashboard totals (total/successful/pending/reported) with trend deltas.
- **`/admin/video-overview-chart`** — monthly series for a chosen year/metric.
- **`/admin/video-details`** — paginated list of videos with metrics (note: uses `offset`, not `page`).
- **`/admin/users/:userId/details`** — a user's profile + paginated videos. `400` invalid id, `404` not found.

```js
const stats = await api("/admin/video-stats", {
  auth: true,
  query: { filter_type: "month", video_type: "short" },
});
```

---

## 7. Known Issues & Caveats (read before building)

These are real behaviors of the current backend that will affect frontend work:

### 7.1 `GET /videos/categories` is unreachable ⚠️
The route `GET /videos/:videoId` is registered **before** `GET /videos/categories`. Express matches in order, so a request to `/videos/categories` is captured by `:videoId` (with `videoId = "categories"`) and never reaches the categories handler — you'll get a `500`/error, not a category list.
**What to do:** use the dedicated categories router instead — `index.js` mounts a separate `/categories` router (`category.route.js`). Point category fetches there. (Send me `category.route.js` and I'll document those endpoints.) Alternatively, ask backend to reorder the routes (put `/categories` above `/:videoId`).

### 7.2 Response shapes are not uniform
Three different shapes are in play:
- **Unified Feed** (`data.videos`): channel, users/videos, search, category, single (`/:videoId`).
- **Flat array** (`data: []`): `hot`.
- **Raw single** (`data: {}`): `metadata`, `PUT` edit.
Write a small adapter per shape rather than assuming one envelope.

### 7.3 `data.videos` is sometimes an object
Only on `GET /videos/:videoId`. Normalize with `[].concat(data.videos)` before iterating.

### 7.4 Not-found is sometimes `200`
`GET /videos/:videoId` returns `200` with an empty `videos` array when the video doesn't exist (everywhere else uses `404`). Don't rely solely on HTTP status — check payload emptiness too.

### 7.5 `GET /videos/metadata/:videoId` increments views
Every hit counts as a view. Use it only on real playback, debounce/guard against re-fetches.

### 7.6 Status enum mismatch
The model's real statuses (`creator_draft`, `submitted_for_review`, `approved_published`, `rejected`, …) differ from the Swagger and from the channel-feed `status` filter's accepted values. Confirm with backend which value filters drafts before wiring an owner "Drafts" tab.

### 7.7 Placeholder fields
`interactions.isBookmarked` and `metadata.watchedBefore` are hardcoded `false` today. Don't ship features that assume they're populated.

### 7.8 gRPC-sourced author/channel can be partial
If the user/channel gRPC services error, you still get the object with only `_id` set and the rest null. Always null-guard in the UI.

---

## 8. To make this guide more complete

If you send these files, I'll fill in the exact request/response details (no guessing):

1. **`app.js` / server entry** — to confirm the real base path prefix.
2. **`upload.routes.js`** + its controller — the actual file-upload step that produces `videoUrl`/`videoKey` (the missing first half of the upload flow).
3. **`uploadService.js`** — exact shape of the upload-status / cooldown response.
4. **`videoLike.controller.js`** — to verify like response bodies.
5. **`admin.controller.js`** — exact admin response shapes + role checks.
6. **`category.route.js`** (and controller) — the working categories endpoints (replacement for the unreachable `/videos/categories`).
7. **`comment.route.js`**, **`song.route.js`**, **`share.routes.js`**, **`ott.routes.js`** — if you want those resources documented in the same guide.

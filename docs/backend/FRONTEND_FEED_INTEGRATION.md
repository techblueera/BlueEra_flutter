# Feed Integration Guide (Frontend)

How to integrate the **mixed user feed** — a single endpoint that returns posts, videos/reels,
business cards, and products interleaved in one list. This document is the contract the frontend
should build against.

> **Golden rule:** `GET /feed` returns a **heterogeneous list**. Every item has a `type` field.
> The UI must **switch on `item.type`** to choose the renderer. Do not assume a fixed order or
> ratio — the interleave pattern is controlled by the backend and can change.

---

## 1. Endpoint

```
GET /feed
```

**Base URL:** `https://<feed-service-host>` (feed router is mounted at `/feed`).

### Auth
Send one of:
- `Authorization: Bearer <jwt>` — preferred, or
- `x-user-id: <userId>` header.

A request with no resolvable user returns `401`.

### Query parameters

| Param | Type | Default | Purpose |
|---|---|---|---|
| `lat` | number | – | **Required to receive `business` items.** User latitude. |
| `long` | number | – | **Required to receive `business` items.** User longitude. |
| `content_types` | csv string | `posts,videos,products` | Which sources to include. Leave unset to get everything. e.g. `posts,videos`. |
| `limit` | number | `20` | Page size. Max `100`. |
| `cursor` | string | – | Pagination cursor. Pass back `meta.next_cursor` from the previous page. |
| `refresh` | boolean | `false` | `true` bypasses the 60s server cache (use for pull-to-refresh). |
| `post_types` | csv string | – | Optional. Restrict to specific post types (`message_post,poll_post,image_post`). |

**Example**

```
GET /feed?lat=28.6139&long=77.2090&limit=20&refresh=true
Authorization: Bearer eyJhbGciOi...
```

---

## 2. Response envelope

```jsonc
{
  "success": true,
  "data": [ /* array of feed items — already interleaved & CDN-rewritten */ ],
  "meta": {
    "has_more": true,
    "next_cursor": "timestamp:1737012345000,postPage:2,videoPage:2",
    "current_cursor": null,
    "count": 20,
    "requested_limit": 20,
    "refresh_interval": 60,
    "fetched_at": "2026-07-16T10:00:00.000Z",
    "total_fetched": 20,
    "processing_time_ms": 143,
    "request_id": "req_...",
    "user_id": "...",
    "content_types_requested": "posts,videos,products",
    "source": "aggregated"
  }
}
```

- `data` — the feed items (see §4).
- `meta.has_more` / `meta.next_cursor` — drive pagination (see §5).

> **Media URLs are already CDN-rewritten server-side** (`profile_image`, `media[]`, `thumbnail`,
> `video_url`, `logo`, product `images[]`, etc.). Render them as-is — no URL rewriting on the client.

---

## 3. The `type` discriminator

There are **7 possible values**. Build a renderer switch on `item.type`:

| `type` | Renders as |
|---|---|
| `message_post` | Text post (may include media) |
| `image_post` | Photo post |
| `poll_post` | Poll |
| `short_video` | Reel / short video |
| `long_video` | Long-form video |
| `business` | Business / place card |
| `product` | Product or service card |

---

## 4. Item schemas

### 4.1 Fields present on EVERY item

```jsonc
{
  "_id": "string",                 // unique id — use as React key
  "type": "message_post",          // the discriminator (see §3)
  "createdAt": "2026-07-16T09:58:00.000Z",
  "repost_count": 0,
  "user": {                        // author — populated for every item
    "_id": "string",
    "name": "Jane Doe",
    "username": "@janedoe",
    "profile_image": "https://cdn.../avatar.jpg",  // may be null
    "verified": false,
    "account_type": "INDIVIDUAL",  // or "BUSINESS"
    "designation": "Software Engineer",
    "location": null,
    "business_id": null,
    "business_name": null,
    "categoryOfBusiness": null,
    "is_following": false
  }
}
```

> For `product` and `business`, the author may resolve to `"name": "Unknown User"` when the
> underlying id is a business id the user service does not return. Render defensively.

### 4.2 `message_post` / `image_post`

Both share the same shape (`image_post` is a photo-first post).

```jsonc
{
  "_id": "post_123",
  "type": "image_post",
  "createdAt": "2026-07-16T09:58:00.000Z",
  "text": "Great day at the beach!",
  "media": ["https://cdn.../1.jpg", "https://cdn.../2.jpg"],
  "media_types": ["image/jpeg", "image/jpeg"],  // may contain "video/mp4"
  "title": "Beach day",
  "sub_title": null,
  "nature_of_post": null,
  "location": "Goa",
  "tagged_users": ["userId1", "userId2"],
  "song": {                                      // null if no audio
    "id": "song_1", "name": "Summer", "artist": "X", "cover_url": "https://cdn.../cover.jpg"
  },
  "thumbnail": "https://cdn.../thumb.jpg",
  "media_height": 1080,
  "media_width": 1080,
  "duration": null,
  "likes_count": 12,
  "comments_count": 3,
  "shares_count": 1,
  "views_count": 200,
  "isLiked": false,
  "is_reposted": false,
  "children_post": null,          // when is_reposted=true, this is a nested feed item (same shape)
  "user": { /* see §4.1 */ }
}
```

> **A post can contain video.** If `media_types` includes `"video/mp4"`, render a video player,
> not an image grid. Decide per item on `media_types`, not on `type`.
>
> **Reposts:** when `is_reposted` is `true`, `children_post` holds the original post (same schema,
> with its own `user`). Render it as a quoted/embedded card.

### 4.3 `poll_post`

```jsonc
{
  "_id": "poll_123",
  "type": "poll_post",
  "createdAt": "2026-07-16T09:58:00.000Z",
  "poll": {
    "question": "Best language?",
    "options": [
      { "text": "JS", "votes": ["userId1", "userId2"], "isCorrect": false },
      { "text": "Python", "votes": ["userId3"], "isCorrect": false }
    ]
  },
  "total_votes": 3,
  "user_has_voted": false,
  "expires_at": null,
  "content": {
    "text": "Vote now",
    "images": ["https://cdn.../poll.jpg"]
  },
  "likes_count": 5,
  "comments_count": 1,
  "shares_count": 0,
  "views_count": 40,
  "isLiked": false,
  "user": { /* see §4.1 */ }
}
```

> Per-option vote counts = `option.votes.length`. `total_votes` is the sum.

### 4.4 `short_video` / `long_video`

`short_video` = reels. Same shape for both; the `type` tells you the surface.

```jsonc
{
  "_id": "video_123",
  "type": "short_video",
  "createdAt": "2026-07-16T09:58:00.000Z",
  "title": "My Reel",
  "description": "Check this out",
  "video_url": "https://cdn.../video.mp4",
  "thumbnail": "https://cdn.../cover.jpg",
  "duration": 30,
  "live": false,                 // true = live stream
  "channel": {                   // null if the video has no channel
    "_id": "chan_1",
    "name": "My Channel",
    "username": "@mychannel",
    "bio": "...",
    "logoUrl": "https://cdn.../logo.jpg",
    "coverImageUrl": "https://cdn.../cover.jpg",
    "websites": ["https://example.com"],
    "category": "Tech",
    "is_verified": true,
    "is_following": false
  },
  "views_count": 1000,
  "likes_count": 50,
  "comments_count": 10,
  "shares_count": 5,
  "tags": ["fun", "travel"],
  "categories": ["lifestyle"],
  "location": { "name": "Delhi", "lat": 28.6, "lng": 77.2 },  // may be null
  "user": { /* see §4.1 */ }
}
```

### 4.5 `business`

```jsonc
{
  "_id": "biz_123",
  "type": "business",
  "createdAt": "2026-07-16T09:58:00.000Z",
  "name": "Cafe Aroma",
  "logo": "https://cdn.../logo.jpg",
  "category": "Restaurant",
  "description": "Cozy coffee shop",
  "location": {
    "address": "123 Main St",
    "city_state_pincode": "Delhi, DL 110001",
    "lat": 28.61,
    "long": 77.21
  },
  "avg_rating": 4.5,
  "total_ratings": 120,
  "user": { /* see §4.1 */ }
}
```

> Only appears when the request includes `lat` and `long`.

### 4.6 `product`

```jsonc
{
  "_id": "prod_123",
  "type": "product",
  "createdAt": "2026-07-16T09:58:00.000Z",
  "name": "Wireless Headphones",
  "price": 2999,
  "currency": "INR",             // INR | USD | EUR
  "description": "Noise cancelling",
  "brand": "Acme",
  "images": ["https://cdn.../p1.jpg"],
  "video_urls": ["https://cdn.../p1.mp4"],
  "store": { "name": "Acme Store", "url": "https://acme.example" },
  "rating": 4.2,
  "category": "electronics",
  "tags": ["audio", "wireless"],
  "warranty": "1 year",
  "is_returnable": true,
  "return_period_days": 7,
  "product_type": "Product",     // "Product" | "Service"
  "options": [
    { "attribute": "Color", "values": ["Black", "White"] }
  ],
  "features": ["40h battery", "Bluetooth 5.3"],
  "additional_details": [
    { "title": "In the box", "description": "Headphones, cable, case" }
  ],
  "user": { /* see §4.1 */ }
}
```

---

## 5. Pagination (infinite scroll)

1. First page: `GET /feed?lat=..&long=..&limit=20`.
2. Read `meta.has_more` and `meta.next_cursor`.
3. Next page: `GET /feed?cursor=<next_cursor>&limit=20&lat=..&long=..`
   (keep sending the same `lat`/`long`).
4. Stop when `meta.has_more === false`.

> The cursor is opaque (`timestamp:..,postPage:..,videoPage:..`). **Do not parse or construct it**
> on the client — just echo `next_cursor` back verbatim.

---

## 6. Behavioral notes & gotchas

1. **Business needs geolocation.** No `lat`/`long` → no `business` items. Send device location.
2. **Order is backend-controlled.** Render items in the order received. Do not hard-code a layout
   that assumes "every 5th item is a video," etc.
3. **Posts can be videos.** Check `media_types` for `video/mp4` on `message_post`/`image_post`.
4. **Reposts** arrive as `children_post` nested inside a parent post.
5. **Unknown future types:** if `item.type` is not one you handle, skip/hide it gracefully rather
   than crashing — new types may be added server-side.
6. **Empty sections are normal.** A given page may contain zero of some type (e.g. no products in
   this window). That is expected; the next page may include them.

---

## 7. Related endpoints (optional, type-specific screens)

| Endpoint | Returns |
|---|---|
| `GET /feed/videos` | Video-only feed (backed by video-bearing posts). |
| `GET /feed/posts?type=MESSAGE_POST\|POLL_POST\|PHOTO_POST` | Posts filtered by a single type. |
| `GET /feed/stats` | Feed stats. |
| `POST /feed/refresh` | Force-refresh the user's cached feed. |

---

## 8. Quick reference — TypeScript types

```ts
type FeedItemType =
  | 'message_post' | 'image_post' | 'poll_post'
  | 'short_video' | 'long_video'
  | 'business' | 'product';

interface Author {
  _id: string;
  name: string;
  username: string;
  profile_image: string | null;
  verified: boolean;
  account_type: 'INDIVIDUAL' | 'BUSINESS';
  designation: string;
  location: string | null;
  business_id: string | null;
  business_name: string | null;
  categoryOfBusiness: string | null;
  is_following: boolean;
}

interface FeedItemBase {
  _id: string;
  type: FeedItemType;
  createdAt: string;      // ISO-8601
  repost_count: number;
  user: Author;
}

interface FeedResponse {
  success: boolean;
  data: FeedItemBase[];   // narrow by `type`
  meta: {
    has_more: boolean;
    next_cursor: string | null;
    count: number;
    requested_limit: number;
    refresh_interval: number;
    fetched_at: string;
  };
}
```

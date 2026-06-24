# Reels in Feed — Frontend Integration Guide

This describes the **mixed post/reel feed** now returned by the post-list feeds.
Reels (short videos from the video service) are interleaved between posts at a fixed
interval on the server. The frontend only needs to render two item types.

> Backend ref: `injectReelsAtInterval` / `computeReelPlan` in
> [feed.service.js](src/utils/feed.service.js), config in
> [reels.config.js](src/config/reels.config.js), wired into the feed handlers in
> [post.controller.js](src/controllers/post.controller.js) (`getAllPostsHomePosts`,
> `searchPosts`, `getMyPosts`, `getOtherUserPosts`).

---

## 1. Endpoints

Reels are injected into **most post-list feeds** (see the table — the channel feed is
posts-only). The request contract for each is unchanged — reels are added to the response
transparently, with the same mixed-array shape described below.

**Which reels you get depends on the feed's scope:**

| Endpoint | Feed | Reel source |
|---|---|---|
| `GET /post/allPosts` | Home feed | **Global** hot/trending shorts |
| `GET /post/search` | Search results | **Global** hot/trending shorts |
| `GET /post/my-posts` | Your own posts | **Your own** reels |
| `GET /post/user-posts` | Another user's posts | **That user's** reels |
| `GET /post/channel-posts-filtered` | Channel feed (latest/popular/oldest) | **No reels** (posts only) |

The two **user-scoped** feeds (`my-posts`, `user-posts`) follow the same rule as their
posts: just as the posts on those pages belong to one user, the reels mixed in are
**that same user's reels** (newest first) — not global trending. The two **global** feeds
(home, search) keep showing global hot reels. The **channel feed**
(`channel-posts-filtered`) returns **posts only** — no reels are injected there.

If the scoped user has **no reels of their own** for that page, the page is returned
**posts-only** (no reels injected, no fallback to global reels).

Query params (unchanged): `page`, `limit`, `filter` (`popular` | `latest` | `oldest`),
`refresh` (`"true"` to bypass cache), plus `query` (search) / `authorId` (profile &
channel) where applicable. Auth: same bearer token as before.

### Controlling reels per request — `includeReels`

The client decides per request whether the response contains posts-only or posts+reels:

| `includeReels` | Response |
|---|---|
| omitted (default) | posts **+ reels** (mixed `item_type` array) |
| `true` | posts **+ reels** |
| `false` | **posts only** — no reels, no `item_type` tagging at all |

```
GET /post/allPosts?page=1&limit=40&includeReels=false   # posts only
GET /post/allPosts?page=1&limit=40                       # posts + reels (default)
```

Notes:
- Only the exact string `includeReels=false` disables reels. Any other value (or omitting
  it) returns the mixed feed.
- When `includeReels=false`, the response is byte-for-byte the **old posts-only shape**
  (flat posts, no `item_type` key) — so a screen that wants a pure post feed gets exactly
  the legacy contract.
- This is independent of the server master switch (`POST_REELS_ENABLED`). If the master
  switch is off, no feed gets reels regardless of `includeReels`.

**Nothing else about the request changes.** Every feed returns the same `item_type`-tagged
mixed array (unless `includeReels=false`), so a single rendering path handles all of them.

---

## 2. What changed in the response

`data` is now a **mixed, ordered array** of two item kinds, each tagged with a
discriminator field `item_type`:

- `item_type: "post"` — an existing post (all previous fields preserved, just with the tag added)
- `item_type: "reel"` — a short video to render as a reel card

`pagination` is **unchanged** — counts and `limit` still refer to **posts only**.
Reels are extra items layered on top and do **not** count toward `totalPosts` /
`totalPages` / `limit`.

> ⚠️ Important: **you cannot assume `data.length === limit` anymore.** A page with
> `limit=10` may return 10 posts + up to 4 reels = 14 items. Drive pagination off the
> `pagination` object, not `data.length`.

### Discriminator-first rendering

```js
data.map((item) => {
  if (item.item_type === "reel") return <ReelCard reel={item.reel} />;
  return <PostCard post={item} />;        // item is the post itself (flat)
});
```

Note the asymmetry, by design:
- **post** items are **flat** — the post fields sit directly on the item alongside `item_type`.
- **reel** items nest the payload under a `reel` key.

---

## 3. Reel item shape

```jsonc
{
  "item_type": "reel",
  "reel": {
    "id": "665f...",
    "user_id": "660a...",          // author user id (nullable)
    "channel_id": "661b...",        // nullable
    "title": "string|null",
    "caption": "string|null",
    "description": "string|null",
    "coverUrl": "https://.../cover.jpg|null",   // poster/thumbnail
    "videoUrl": "https://.../video.mp4|null",   // playable source
    "duration": 30,                  // seconds (0 if unknown)
    "thumbnails": {},                // object, may be empty
    "song": null,                    // audio metadata or null
    "stats": { "views": 0, "likes": 0, "shares": 0, "comments": 0 },
    "type": "short",
    "created_at": { "seconds": "1718900000", "nanos": 0 }  // protobuf timestamp, or null
  }
}
```

Defensive notes:
- Any field can be `null`/`0`/`{}` — render with fallbacks. Guard `videoUrl` and
  `coverUrl` before use.
- `stats` is always present with all four keys (defaulting to 0).
- `created_at` is **not** an ISO string — it's the raw gRPC timestamp object
  `{ seconds, nanos }` (`seconds` is a numeric string). To get a JS date:
  `new Date(Number(reel.created_at.seconds) * 1000)`. May be `null`.
- The server already drops unpublished/private/flagged/mature reels, so anything you
  receive is safe to display.

---

## 4. Placement rules (so you know what to expect)

Driven by [reels.config.js](src/config/reels.config.js):

| Rule | Value | Meaning |
|---|---|---|
| `INTERVAL` | 5 | One reel after every 5 posts |
| `START_OFFSET` | 5 | No reel before the 5th post, *once there are enough posts to interleave* |
| `MIN_PER_PAGE` | 4 | Minimum reels per page, even on sparse/empty pages |
| `MAX_PER_PAGE` | 4 | Hard cap of reels per page |

Because `MIN_PER_PAGE` and `MAX_PER_PAGE` are both **4**, each enabled page targets
**4 reels** (capped by how many are actually available). They're placed like this: one
reel is interleaved after each `INTERVAL` block of posts starting at `START_OFFSET`
(after post #5, #10, …); any of the 4 that don't land in an interleave slot on this page
are **appended after the last post**.

So on a 10-post page there are two interleave slots (after #5 and #10) and the remaining
two reels are appended at the end — meaning **reels can appear adjacent at the tail** of a
page. If fewer reels are available than the 4 targeted, the missing ones are simply skipped
(no placeholders).

**Sparse and empty pages (important):** because of `MIN_PER_PAGE`, reels appear even
when there aren't enough posts to interleave. Reels that can't be placed between posts
are **appended after the last post**. Concretely:

- A page with **few posts** (fewer than `START_OFFSET`) → posts first, then the reels
  appended at the end. They may be **adjacent** at the tail.
- A page with **zero posts** (e.g. a profile/`my-posts` feed for a user who hasn't posted)
  → if reels are available for that page it becomes **reels-only** (`data` contains only
  `item_type: "reel"` items and `pagination.totalPosts` is `0`). On the user-scoped feeds
  this only happens when *that user* actually has reels; a user with neither posts nor
  reels returns an empty `data`.

So the client must **not** assume a feed page always starts with a post, and must handle
a `data` array that is entirely reels (or empty).

These are server-side constants — placement may be tuned without a frontend change,
so **don't hardcode the interval on the client**. Always render by walking `data` in order.

---

## 5. Feature flag / fail-safe behavior

- The feature has a master switch (`POST_REELS_ENABLED`). When **off**, the response is
  exactly the old shape: `data` is plain posts with **no `item_type` tag at all**.
- If the video service is unavailable, the feed **degrades to posts-only** (still works).

Because of the above, write the client to **treat reels as optional**:

```js
// Safe for both old and new responses:
const isReel = item.item_type === "reel";
// A post is anything that isn't a reel (covers the flag-off case where
// item_type is absent entirely).
```

Do **not** assume every item has `item_type`. Only reels are guaranteed to carry it
in the flag-off / posts-only scenarios.

---

## 6. Pagination — concrete guidance

- Keep paging with `page` / `limit` as before.
- Use `pagination.totalPosts` / `pagination.totalPages` to decide "has more" — these
  count posts only.
- Don't compute "next page" from `data.length`; it includes reels.
- Reels are fetched per page with a page offset on the server, so paging forward
  generally won't repeat the same reels (full de-dupe is a future improvement —
  light client-side de-dupe by `reel.id` is a reasonable safeguard if you cache pages).

---

## 7. Quick checklist for the frontend

- [ ] Branch rendering on `item_type` (`"reel"` → reel card; else post card).
- [ ] Read reel data from `item.reel`, post data from the item itself.
- [ ] Null-guard `videoUrl`, `coverUrl`, `song`, `title/caption`.
- [ ] Drive pagination from `pagination`, never `data.length`.
- [ ] Tolerate items with no `item_type` (flag-off / posts-only path).
- [ ] De-dupe by `reel.id` across pages if you keep a merged list (optional).

# Social Section — Flutter Integration Guide

Everything the app needs for the reworked Social section: the merged
post + reel + suggestions feed, the **My Post** tab, reels created from post
videos, and the engagement rules that keep likes and comments consistent
between them.

Backend repos touched: `be_userfeed_service`, `be_video_service`,
`be_posts_service`, `be_user_service`.

---

## 0. What is actually changing

| # | Change | Backend work | Flutter work |
|---|---|---|---|
| 1 | Social section gets three tabs: **Feeds / Bites / My Post** | none | move the API call + render |
| 2 | **Feeds** tab can move to the merged `/feed/home` | new endpoint | swap URL, one new item type |
| 3 | Follow-suggestion cards inside the feed | new | new model + carousel widget |
| 4 | Videos attached to posts now also play as reels in Bites | new | none (they arrive as normal reels) |
| 5 | Likes/comments consistent between a post and its reel | new | **route writes by `origin_post_id`** |
| 6 | Old channel/community reels visible on profiles again | none | delete one line |

Items 1 and 6 need no backend deploy at all. Item 5 is the one that will
silently corrupt data if the client ignores it — read §4 carefully.

---

## 1. Social section tabs (frontend only)

Today's tab bar in `order_main_chat_screen.dart` is **Social / Community / Bites**.
With community removed it becomes **Feeds / Bites / My Post**.

Nothing new is needed server-side. Each tab is an existing endpoint rendered in
a new place:

| Tab | Widget | Endpoint |
|---|---|---|
| **Feeds** | `HomeFeedScreenNew` | `post-service/post/allPosts?includeReels=true` today, or `userfeed-service/feed/home` (§2) |
| **Bites** | `ReelsTabScreen` | `video-service/videos/hot/short` — unchanged |
| **My Post** | reuse `HomeFeedScreenNew` with `PostType.myPosts` | `post-service/post/my-posts` — unchanged |

`GET /post/my-posts` is the same endpoint the profile already calls via
`FeedRepo().getAllMyPosts()`, and it already runs through the reel-injection
path. So **"My Post" is a pure UI move**: same request, same response, new
location. Whether it *also* stays on the profile is your call — the endpoint
does not care how many places call it.

---

## 2. The merged feed — `GET /api/userfeed-service/feed/home`

One call returning posts, reels and suggestion blocks in a single ordered list.

> **Before you migrate:** the Feeds tab already shows posts and reels together
> via `post/allPosts?includeReels=true` (`item_type: "reel"` + `FeedReel`).
> `/feed/home` is not required for mixing — it adds *suggestion blocks*, a
> *seeded-random reel order* matching Bites, and *server-tuned cadence*. If you
> only want suggestions, ask backend to add them to the existing feed instead;
> that is less work than migrating.

### 2.1 Request

```
GET /api/userfeed-service/feed/home
Authorization: Bearer <jwt>
```

| Param | Type | Default | Notes |
|---|---|---|---|
| `cursor` | string | — | Opaque; echo `meta.next_cursor` back. Omit for page 1 |
| `limit` | int | `20` | 1–50, counts suggestion blocks as items |
| `refresh` | bool | `false` | Bypasses cache **and reshuffles reels**. Use for pull-to-refresh |

No `lat`/`long` — this endpoint returns no `business` or `product` items.

### 2.2 Response

The envelope is identical to the existing `userfeed-service/feed`, so
`HomeFeedResponse.fromJson` and `MetaData.fromJson` work **unchanged**.

```json
{
  "success": true,
  "data": [ /* feed items */ ],
  "meta": {
    "count": 20,
    "has_more": true,
    "next_cursor": "eyJwYyI6IjIwMjYtMDgtMTJ...",
    "composition": { "posts": 14, "reels": 4, "suggestion_blocks": 2 },
    "reel_seed": "418923771"
  }
}
```

### 2.3 Ordering

Cadence is server-tuned, not hardcoded in the app. Defaults produce, per
20-item page, roughly **14 posts, 4 reels, 2 suggestion blocks**:

```
P P P R P P P R P S P P R P P P R P P S      (page 1)
P R P P P R P P P S R P P P R P P P R S      (page 2)
```

Counters carry across pages in the cursor, so a reel does not land at the same
index on every page. Within each lane: posts are newest-first, reels are in
seeded-random order (no repeats within a session), suggestions are ranked.

### 2.4 Item types

| `type` | Existing widget | Change |
|---|---|---|
| `message_post` / `image_post` / `poll_post` | `FeedCard` | none |
| `short_video` | `FeedVideoCard` | none |
| `user_suggestions` | — | **new**, see §3 |

`business` and `product` never appear here; leave those cases in the switch.

---

## 3. Suggestion blocks

```json
{
  "_id": "suggestions_0",
  "type": "user_suggestions",
  "title": "Suggested for you",
  "users": [
    {
      "_id": "68f2a1c4e5b7d90012a4f8c1",
      "name": "Rohit Sharma",
      "username": "rohit_s",
      "profile_image": "https://cdn.beapp.in/user/…jpg",
      "account_type": "INDIVIDUAL",
      "designation": "Interior Designer",
      "city": "Indore",
      "verified": false,
      "followers_count": 1240,
      "mutual_followers_count": 3,
      "reason": "mutual",
      "business_category": null,
      "is_following": false
    }
  ]
}
```

- Normally 5 profiles per block, sometimes 3. Render whatever arrives.
- `name` is pre-resolved (business accounts already carry `business_name`).
- `profile_image` is CDN-rewritten and may be `""` — use your avatar fallback.
- `is_following` is always `false` on arrival; the backend never suggests someone
  the viewer already follows. Flip it locally after a follow tap.
- `_id` is unique across pages — safe as a list key and for de-duplication.

`reason` drives the subtitle:

| `reason` | Subtitle |
|---|---|
| `mutual` | `Followed by {mutual_followers_count} others you follow` |
| `profession` | the `designation` value |
| `city` | `From {city}` |
| `popular` | `Popular on BlueEra` |

**Follow action** uses the existing endpoints — nothing new:

```dart
final String follow   = 'user-service/followers/follow';    // POST   /:targetUserId
final String unfollow = 'user-service/followers/unfollow';  // DELETE /:targetUserId
```

Update optimistically, revert on failure, and **do not remove the card from the
row mid-scroll** — it makes the carousel jump under the user's finger.

A standalone "see all" list is available at
`GET /api/user-service/followers/suggestions?limit=20&offset=0`
(also accepts `exclude=id1,id2`).

---

## 4. Engagement consistency — **read this one**

### 4.1 The situation

A video attached to a post is now ingested into video-service and plays as a
reel. That means **one piece of content exists in two places**:

- the **post** — rendered in Feeds and My Post
- the **reel** — rendered in Bites and in the merged feed

They are separate documents. If likes were written to whichever one the user
happened to be looking at, the same content would show two different numbers.

### 4.2 The rule

**The post is the single source of truth for ingested reels.**

The backend already handles the *read* side: any reel that came from a post is
served with the **post's** `likes` / `comments` / `shares` and the **post's**
`isLiked` state, on every endpoint (`hot/:type`, the merged feed, the single-video
detail call). You do not need to fetch or merge anything.

The *write* side is on the client:

> When a reel item carries a non-empty **`origin_post_id`**, every like, unlike,
> comment and share for it MUST go to the **post** endpoints, using that id —
> never the video endpoints.

```dart
// On any reel item from any endpoint:
final originPostId = json['origin_post_id'] as String?;
final isFromPost = originPostId != null && originPostId.isNotEmpty;

// Like
if (isFromPost) {
  await PostRepo().likePost(postId: originPostId);        // post-service/post/like
} else {
  await ChannelRepo().likeVideo(videoId: reel.videoId);   // video-service/likes/:id/like
}

// Comments — list and create
if (isFromPost) {
  await PostRepo().getComments(postId: originPostId);     // post-service/post/comments/:postId
} else {
  await ChannelRepo().getVideoComments(reel.videoId);     // video-service/comments/video/:videoId
}

// Share
if (isFromPost) {
  await PostRepo().sharePost(postId: originPostId);       // post-service/post/shares
} else {
  await ChannelRepo().shareVideo(reel.videoId);           // video-service/share/videos/:videoId
}
```

Writing to the video endpoints for such a reel is not an error the backend can
catch — it lands in a counter nothing reads back, so the like appears to work,
survives the session, and is gone on next launch.

A convenience field `engagement_source: "post"` ships alongside `origin_post_id`
if you prefer branching on that.

### 4.3 Old data behaves identically

| Reel kind | `origin_post_id` | Engagement lives in |
|---|---|---|
| Recorder upload (profile) | absent | video-service — unchanged |
| Legacy channel/community upload | absent | video-service — unchanged |
| Ingested from a post (new **and** backfilled) | **present** | posts-service |

Backfilled old post-videos come through with `origin_post_id` set exactly like
new ones, so one branch covers both. Native reels keep their existing behaviour —
no migration of their likes or comments.

### 4.4 Comment counts

The same rule covers comments: an ingested reel's comment list and count come
from the post, so a comment left in Bites appears on the post in My Post and vice
versa. Native reels keep video-service comments.

---

## 5. Reels created from post videos

No client change is needed to *display* them — they arrive through
`hot/short` and the merged feed as ordinary reels. Worth knowing:

- **Not instant.** Ingestion runs a MediaConvert transcode. A video posted now
  appears in Bites once transcoding finishes (typically a minute or two, longer
  for larger files). Do not expect a just-created post's reel to be in Bites on
  the next pull-to-refresh.
- **Length limit.** Videos longer than `POST_VIDEO_MAX_SHORT_SECONDS`
  (default **90s**) are not ingested at all — they stay posts only. Nothing to
  handle client-side, but it explains why some video posts never show in Bites.
- **Not duplicated on the profile.** Ingested reels are excluded from
  `video-service/videos/users/:id/videos`, so the author's reels tab does not
  show them. They appear on the profile as the post, in the posts tab.
- **Not duplicated in the feed.** The merged feed drops video-bearing
  `MESSAGE_POST`s from the post lane, because the same content is coming through
  the reel lane.
- **Deleting the post** withdraws the reel from Bites and the feed.

---

## 6. Bringing back old channel/community content

One line, no backend deploy, instantly reversible.

Delete the `post_via` parameter at
[`shorts_controller.dart:723`](../BlueEra_flutter/lib/features/common/feed/controller/shorts_controller.dart)
and [`video_controller.dart:525`](../BlueEra_flutter/lib/features/common/feed/controller/video_controller.dart):

```dart
// REMOVE — `post_via` defaults to "all" server-side, which is what we now want.
params[ApiKeys.postVia] = (postVia == PostVia.channel) ? 'channel' : 'user';
```

Sending `post_via=user` restricts the query to videos with no `channelId`, which
is why reels posted through a channel disappeared from profiles when community
was removed. Dropping the param brings them back. **No database migration is
involved** — the data was never lost, only filtered out.

Ship this on its own and verify before touching anything else.

---

## 7. Rollout order

1. **§6 `post_via` removal** — one line, no backend dependency. Ship and verify first.
2. **§1 tab move** — pure UI, no backend dependency.
3. **§4 engagement branching** — ship *before* the backfill runs, so the first
   ingested reels are already handled correctly. Harmless while no reel has an
   `origin_post_id`.
4. **§3 suggestion parsing + widget** — inert against the old `/feed`, which never
   emits `user_suggestions`. Safe to ship early.
5. **§2 URL swap to `/feed/home`** — last, and one line to roll back.

Backend deploys must land before 3 and 5: `be_user_service` →
`be_video_service` → `be_posts_service` → `be_userfeed_service`.

---

## 8. Test checklist

**Feed**
- [ ] Reel roughly every 3 posts, suggestion block roughly every 9 items
- [ ] Page 2 repeats no post, reel or profile
- [ ] Pull-to-refresh visibly changes reel order
- [ ] `has_more: false` stops pagination (not item count)

**Suggestions**
- [ ] Follow flips the button; profile absent from later pages
- [ ] Follow with airplane mode reverts the button
- [ ] Block of 3 users renders without overflow
- [ ] Missing `profile_image` / `designation` render with fallbacks

**Engagement — the important ones**
- [ ] Like an ingested reel in Bites → open My Post → **same count, still liked**
- [ ] Like the post in My Post → open Bites → **same count, still liked**
- [ ] Comment in Bites → comment visible on the post, and counts match
- [ ] Like a *native* reel → count changes in Bites, post surfaces unaffected
- [ ] Force-quit and relaunch after each of the above — counts must persist

**Old data**
- [ ] Channel-era reels appear on the author's profile after §6
- [ ] Backfilled post-videos appear in Bites with the post's real like count

**Degradation**
- [ ] video-service down → feed still loads, posts only
- [ ] suggestions unavailable → feed still full, no empty blocks

---

## 9. Server-side knobs (no app release needed)

| Env var | Default | Effect |
|---|---|---|
| `HOME_FEED_POSTS_PER_REEL` | `3` | One reel after every N posts |
| `HOME_FEED_ITEMS_PER_SUGGESTION` | `9` | One suggestion block every N items |
| `HOME_FEED_SUGGESTION_SIZE` | `5` | Profiles per block |
| `HOME_FEED_DEFAULT_LIMIT` / `HOME_FEED_MAX_LIMIT` | `20` / `50` | Page size |
| `FEED_CACHE_TTL_SECONDS` | `60` | Per-user page cache |
| `POST_VIDEO_MAX_SHORT_SECONDS` | `90` | Longest post video ingested as a reel |

If the feed rhythm feels wrong in testing, ask backend to tune these rather than
compensating on the client.

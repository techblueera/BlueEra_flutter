# Merged Home Feed — Flutter Integration Guide

`GET /api/userfeed-service/feed/home`

One call that returns **posts, reels and "who to follow" blocks** as a single
ordered list — the Instagram-style home feed.

---

## 0. Read this first

Two things in the app already exist and are easy to confuse with this endpoint.
Skipping this section will cost you a day.

| Surface | Endpoint the app calls today | Already merges reels? |
|---|---|---|
| `home_feed_screen_new.dart` (home tab) | `userfeed-service/feed` | **Yes** — `short_video` / `long_video` items |
| `PostType.all` list (`feed_controller.dart`) | `post-service/post/allPosts?includeReels=true` | **Yes** — `item_type: "reel"` + `FeedReel` |

So "posts and reels in one place" is **already shipped, twice**, in two different
shapes. What `/feed/home` adds on top of `userfeed-service/feed` is:

1. **Follow-suggestion blocks** injected into the feed (genuinely new — this did
   not exist anywhere before).
2. **Seeded-random reel ordering**, matching the Reels tab, instead of
   recency/hotness ordering. No reel repeats within a session; pull-to-refresh
   reshuffles.
3. **Server-tuned cadence** — the post:reel:suggestion ratio is env-configurable
   and changes without an app release.

**The good news:** `/feed/home` deliberately reuses the exact envelope and item-type
vocabulary of `userfeed-service/feed`. For `home_feed_screen_new.dart` this is a
near drop-in change — swap the URL and add **one** new item type. `HomeFeedResponse`,
`MetaData`, `Post.fromJson` and the existing `_buildFeedItem` cases all keep working
unchanged.

> If you only want the suggestion blocks and are happy with the current reel
> ordering, say so — adding suggestions to the existing `/feed` response is a
> smaller backend change than migrating. Don't migrate just because this document
> exists.

---

## 1. The endpoint

```
GET /api/userfeed-service/feed/home
Authorization: Bearer <jwt>
```

| Query param | Type | Default | Notes |
|---|---|---|---|
| `cursor` | string | — | Opaque. Echo back `meta.next_cursor` verbatim. Omit for page 1. |
| `limit` | int | `20` | 1–50. Counts suggestion blocks as items. |
| `refresh` | bool | `false` | Bypasses the 60 s server cache **and re-shuffles the reels**. Use for pull-to-refresh. |

**No `lat` / `long`.** Unlike `/feed`, this endpoint returns no `business` or
`product` items, so geolocation is irrelevant. Don't send it.

---

## 2. Response envelope — identical to `/feed`

```json
{
  "success": true,
  "data": [ /* feed items, see §3 */ ],
  "meta": {
    "count": 20,
    "requested_limit": 20,
    "has_more": true,
    "next_cursor": "eyJwYyI6IjIwMjYtMDgtMTJUMDY6MzciLCJycCI6Miwi...",
    "composition": { "posts": 14, "reels": 4, "suggestion_blocks": 2 },
    "reel_seed": "418923771",
    "fetched_at": "2026-08-12T06:37:11.088Z",
    "processing_time_ms": 143
  }
}
```

`HomeFeedResponse.fromJson` and `MetaData.fromJson` parse this **as-is**. No model
change needed at the envelope level.

`composition` and `reel_seed` are diagnostics — useful in logs when a feed looks
wrong, not needed by the UI.

---

## 3. Item types in `data`

### 3.1 Already handled by your existing switch

| `type` | Widget in `_buildFeedItem` | Change needed |
|---|---|---|
| `message_post` | `FeedCard` | none |
| `image_post` | `FeedCard` | none |
| `poll_post` | `FeedCard` | none |
| `short_video` | `FeedVideoCard` | none |

These carry the **same field shape as `/feed`** — `_id`, `text`, `media`,
`media_types`, `user`, `isLiked`, `likes_count`, `comments_count`, `createdAt`,
`tagged_users_details`, and for reels `video_url` / `thumbnail` / `duration`.

Note `business` and `product` never appear here. Leave those cases in place; they
simply won't fire.

### 3.2 The one new type: `user_suggestions`

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

**Field notes**

- `users` is normally 5 profiles (`HOME_FEED_SUGGESTION_SIZE`); a trailing block may
  have as few as 3. Never assume exactly 5 — render whatever arrives.
- `name` is already resolved: business accounts get `business_name`, individuals get
  `name`. Don't re-derive it from `account_type`.
- `profile_image` is already CDN-rewritten and may be `""`. Fall back to your avatar
  placeholder.
- `is_following` is always `false` on arrival — the backend only suggests people the
  viewer does **not** follow. It exists so you can flip it locally after a follow tap.
- `reason` drives the subtitle. Map it:

  | `reason` | Suggested subtitle |
  |---|---|
  | `mutual` | `Followed by N others you follow` (use `mutual_followers_count`) |
  | `profession` | the `designation` value |
  | `city` | `From {city}` |
  | `popular` | `Popular on BlueEra` |

- `_id` is **globally unique across pages** (`suggestions_0`, `suggestions_5`, …).
  Safe to use as a list key and safe for `_id`-based de-duplication.

---

## 4. Flutter changes

### 4.1 API constant

`lib/core/api/apiService/userfeed_service_api.dart`

```dart
mixin UserfeedServiceApi {
  // … existing entries unchanged …
  final String homeFeed = 'userfeed-service/feed';

  /// Merged home feed: posts + reels + follow suggestions in one cursor-paged
  /// list. Superset of [homeFeed] — same envelope, adds `user_suggestions`.
  final String homeFeedMerged = 'userfeed-service/feed/home';
}
```

Keep `homeFeed` — it stays live, and you want a one-line rollback.

### 4.2 Repo

`lib/features/common/home/repo/home_feed_repo.dart`

```dart
Future<ResponseModel> mergedHomeFeedRepo({Map<String, dynamic>? queryParam}) async {
  final response = await ApiBaseHelper().getHTTP(
    homeFeedMerged,
    params: queryParam,
    showProgress: false,
    onError: (error) {},
    onSuccess: (data) {},
  );
  return response;
}
```

### 4.3 Models

`lib/features/common/feed/models/posts_response.dart`

```dart
/// A "who to follow" block injected into the merged home feed.
/// Carried on a [Post] whose `type == "user_suggestions"`.
class FeedSuggestions {
  final String title;
  final List<SuggestedUser> users;

  const FeedSuggestions({this.title = 'Suggested for you', this.users = const []});

  factory FeedSuggestions.fromJson(Map<String, dynamic> json) {
    return FeedSuggestions(
      title: json['title']?.toString() ?? 'Suggested for you',
      users: (json['users'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(SuggestedUser.fromJson)
              .toList() ??
          const [],
    );
  }
}

class SuggestedUser {
  final String id;
  final String name;
  final String username;
  final String? profileImage;
  final String? designation;
  final String? city;
  final bool verified;
  final int followersCount;
  final int mutualFollowersCount;
  final String reason;

  /// Local-only. Server always sends false (it never suggests someone you
  /// already follow); flipped optimistically on tap.
  bool isFollowing;

  SuggestedUser({
    required this.id,
    required this.name,
    required this.username,
    this.profileImage,
    this.designation,
    this.city,
    this.verified = false,
    this.followersCount = 0,
    this.mutualFollowersCount = 0,
    this.reason = 'popular',
    this.isFollowing = false,
  });

  factory SuggestedUser.fromJson(Map<String, dynamic> json) => SuggestedUser(
        id: json['_id']?.toString() ?? '',
        name: (json['name']?.toString().trim().isNotEmpty ?? false)
            ? json['name'].toString()
            : 'BlueEra User',
        username: json['username']?.toString() ?? '',
        profileImage: (json['profile_image']?.toString().isNotEmpty ?? false)
            ? json['profile_image'].toString()
            : null,
        designation: json['designation']?.toString(),
        city: json['city']?.toString(),
        verified: json['verified'] as bool? ?? false,
        followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
        mutualFollowersCount: (json['mutual_followers_count'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? 'popular',
        isFollowing: json['is_following'] as bool? ?? false,
      );

  /// Subtitle line under the name.
  String get subtitle {
    switch (reason) {
      case 'mutual':
        return mutualFollowersCount > 0
            ? 'Followed by $mutualFollowersCount others you follow'
            : 'Suggested for you';
      case 'city':
        return (city?.isNotEmpty ?? false) ? 'From $city' : 'Suggested for you';
      case 'profession':
        return (designation?.isNotEmpty ?? false) ? designation! : 'Suggested for you';
      default:
        return 'Popular on BlueEra';
    }
  }
}
```

Then in `Post`, add the field, the getter and the parse branch — mirroring exactly
how `item_type: "reel"` is already handled:

```dart
final FeedSuggestions? suggestions;

bool get isSuggestions => feedType == 'user_suggestions';
```

```dart
factory Post.fromJson(Map<String, dynamic> json) {
  // Merged home feed: a suggestion block has no post fields at top level.
  // Wrap it in a marker Post carrying only the block; the UI branches on
  // [isSuggestions]. Same pattern as the item_type:"reel" branch above.
  if (json['type'] == 'user_suggestions') {
    return Post(
      id: json['_id']?.toString() ?? '',
      type: 'user_suggestions',
      suggestions: FeedSuggestions.fromJson(json),
    );
  }

  if (json['item_type'] == 'reel') { /* … unchanged … */ }
  // … existing post parsing unchanged …
}
```

`feedType` already lowercases `type`, so `'user_suggestions'` flows through with no
change to that getter.

### 4.4 Render case

`lib/features/common/feed/view/home_feed_screen_new.dart`

```dart
case 'user_suggestions':
  // No trackPostView — a suggestion block is not content.
  return FeedSuggestionsCard(block: item.suggestions!);
```

The existing `default: return const SizedBox.shrink();` already protects you if the
backend later adds another item type, so the migration is safe to ship ahead of any
server-side cadence change.

### 4.5 Widget

New file `lib/features/common/feed/widget/feed_suggestions_card.dart` — a horizontally
scrolling row of profile cards:

```
┌ Suggested for you ─────────────────────────┐
│  ┌──────┐  ┌──────┐  ┌──────┐             │
│  │ (av) │  │ (av) │  │ (av) │   →         │
│  │ Name │  │ Name │  │ Name │             │
│  │ sub  │  │ sub  │  │ sub  │             │
│  │[Follow]│ │[Follow]│ │[Follow]│          │
│  └──────┘  └──────┘  └──────┘             │
└────────────────────────────────────────────┘
```

Implementation notes:

- `SizedBox(height: ~230)` wrapping a horizontal `ListView.builder`, `key:
  ValueKey(user.id)` per card.
- Tapping the card body → existing profile navigation (`feed_profile_navigation.dart`).
- Tapping **Follow** → §5. Flip to a "Following" state in place; **do not** remove the
  card from the row mid-scroll (it makes the row jump under the user's finger).
- If `block.users.isEmpty`, return `SizedBox.shrink()` — never render an empty box.

---

## 5. The follow action

Existing endpoints, already in `user_service_api.dart` — nothing new:

```dart
final String follow   = 'user-service/followers/follow';    // POST   /:targetUserId
final String unfollow = 'user-service/followers/unfollow';  // DELETE /:targetUserId
```

```dart
Future<void> onFollowTap(SuggestedUser user) async {
  final previous = user.isFollowing;
  user.isFollowing = true;            // optimistic
  refreshRow();
  final res = await UserRepo().followUser(targetUserId: user.id);
  if (!res.isSuccess) {
    user.isFollowing = previous;      // revert on failure
    refreshRow();
  }
}
```

The backend excludes anyone you already follow from future suggestion pages, so a
followed profile won't reappear on later pages of the same scroll.

**Optional "see all" screen.** The same ranked list is exposed directly:

```
GET /api/user-service/followers/suggestions?limit=20&offset=0
→ { success, data: [ /* same SuggestedUser shape */ ], meta: { limit, offset, total, has_more } }
```

Also accepts `exclude=id1,id2` to skip profiles already shown.

---

## 6. Pagination rules

1. **`meta.next_cursor` is opaque.** It packs the post cursor, the reel page, the reel
   shuffle seed and the suggestion offset into one base64 blob. Never parse it, never
   build one, never cache a page against a hand-made key.
2. **Stop on `meta.has_more == false`, not on item count.** Three lanes are interleaved,
   so a page can return fewer than `limit` items and still have more behind it. Your
   existing `_resolveHasMore` already does the right thing.
3. **Pull-to-refresh must drop the cursor and send `refresh=true`.** That mints a new
   shuffle seed, so the user gets a genuinely different reel order. Carrying the old
   cursor would silently keep the old seed.
4. **De-duplicate by `_id` when appending pages.** Posts, reels and suggestion blocks
   all carry stable unique `_id`s. This matters most after a refresh races an in-flight
   page-2 request.
5. **Reel prefetch:** keep the existing behaviour of pushing `short_video` items into
   `shortsController.latestShortsPosts`. Skip `user_suggestions` items when you do —
   they have no `video_url` and will throw in `getVideoData`.

---

## 7. Edge cases to handle

| Situation | What the server sends | What the UI should do |
|---|---|---|
| Brand-new user, follows nobody | Suggestion blocks filled from the popular/verified fallback | Nothing special — same rendering |
| Suggestion service down | No `user_suggestions` items at all; slots backfilled with posts/reels | Feed still renders fully |
| Video service down | No `short_video` items; slots backfilled with posts | Feed still renders fully |
| Everything exhausted | `has_more: false`, `next_cursor: null` | Stop paginating, show end-of-feed |
| Stale cursor from an old build | Server restarts the feed from page 1 rather than erroring | Handle a page-1-looking response mid-scroll (de-dupe by `_id`) |

The feed degrades lane-by-lane by design: **no single upstream outage can produce an
error response or an empty feed** as long as posts are available.

---

## 8. Test checklist

- [ ] Page 1 renders with a reel roughly every 3 posts and a suggestion block roughly
      every 9 items.
- [ ] Scroll to page 2 → **no repeated posts, no repeated reels, no repeated profiles**.
- [ ] Pull-to-refresh → reel order visibly changes.
- [ ] Follow from a suggestion card → button flips; profile absent from later pages.
- [ ] Follow with airplane mode on → button reverts to "Follow".
- [ ] Kill video-service in staging → feed still loads, posts only.
- [ ] Suggestion block with 3 users renders without layout overflow.
- [ ] User with no `profile_image` / no `designation` renders with fallbacks.
- [ ] Tapping a reel in the feed still opens the full-screen player at the right video.

---

## 9. Rollout & rollback

Ship the parsing (§4.3) and the render case (§4.4) **first**, pointed at the old
`userfeed-service/feed`. They are inert there — `/feed` never emits
`user_suggestions`, and the `default:` case already ignores unknown types. Then flip
the URL constant in a second step.

**Rollback is one line:** point the repo call back at `homeFeed`. The old endpoint is
unchanged and stays live indefinitely.

**Backend deploy order** (must land before the app flips the URL):
`be_user_service` → `be_video_service` → `be_userfeed_service`.

---

## 10. Server-side tuning knobs

No app release needed to change any of these:

| Env var | Default | Effect |
|---|---|---|
| `HOME_FEED_POSTS_PER_REEL` | `3` | One reel after every N posts |
| `HOME_FEED_ITEMS_PER_SUGGESTION` | `9` | One suggestion block every N items |
| `HOME_FEED_SUGGESTION_SIZE` | `5` | Profiles per block |
| `HOME_FEED_DEFAULT_LIMIT` | `20` | Page size when `limit` is omitted |
| `HOME_FEED_MAX_LIMIT` | `50` | Hard cap on `limit` |
| `FEED_CACHE_TTL_SECONDS` | `60` | Per-user page cache TTL |

If the feed "feels" wrong in testing, ask backend to tune these rather than working
around the ratio on the client.

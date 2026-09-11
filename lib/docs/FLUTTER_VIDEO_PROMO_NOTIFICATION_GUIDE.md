# Flutter — Open the video directly when a video-promo push is tapped

**Operation:** `admin_video_promo`

When an admin promotes a creator's video to a segment of users, every recipient gets a
push with the video thumbnail. Tapping it must open **that video's player**, not the
notification list.

**The good news:** the app already has everything it needs. `deep_link_router.dart`
already handles `https://beapp.in/app/video/<id>`, and
`deepLinkNetworkResources.navigateToVideoDetail(videoId)` already fetches the video,
shows a loader, and branches shorts → `ShareShortPlayerItem` / longs →
`VideoPlayerScreen`. **The required change is one `case` in the notification tap
switch.** Everything after §3 is polish and verification.

---

## 1. The payload

`sendFCMNotification` sends a **data-only** message — no `notification` block — so the
Flutter background handler builds exactly one notification itself. For
`admin_video_promo` the `data` map contains:

| Key | Example | Notes |
|---|---|---|
| `operation` | `admin_video_promo` | **Route on this.** |
| `title` | `Diwali special recipe` | Already rendered by the existing notification builder |
| `body` | `Ravi Kumar just posted…` | |
| `imageUrl` | `https://…/high.jpg` | Video thumbnail; drives `style: bigPicture` |
| `style` | `bigPicture` | |
| `channelId` | `video_promos` | New Android channel, `default` importance |
| `channelName` | `Video Highlights` | |
| `actions` | `[{"id":"watch_video_<id>","text":"Watch now"}]` | JSON string |
| **`videoId`** | `68f0a1b2c3d4e5f60718293a` | **The one field you actually need** |
| `videoType` | `short` \| `long` | Hint only — see the warning below |
| `videoTitle` | `Diwali special recipe` | |
| `videoThumbnail` | `https://…/high.jpg` | |
| `videoDuration` | `42` | Seconds, as a string |
| `deepLink` | `https://beapp.in/app/video/68f0…` | Canonical App Link |
| `targetScreen` | `reel_player` \| `video_player` | Hint only |
| `authorId` / `authorName` | `6512…` / `Ravi Kumar` | |
| `broadcastId` | `68f1…` | For open-rate analytics |
| `payload` | `"{…}"` | Full JSON of the producer payload |

> **Do not route off `videoType` / `targetScreen`.** They are snapshot values captured
> when the admin composed the broadcast, and a scheduled campaign can fire days later.
> `navigateToVideoDetail` branches on the type it gets back from the **live** fetch,
> which is always correct. Use `videoId` and let the existing helper decide.

Every value in an FCM `data` map is a **string**. `data['videoDuration']` is `"42"`,
never `42`.

---

## 2. The three ways a tap arrives

The app already handles all three; they all funnel into
`AppNotification._onTapNotificationFromStatusBar(data, fromColdStart:)`.

| App state | Path | Already wired? |
|---|---|---|
| **Foreground** | `onMessage` → local notification → `onForegroundNotificationResponse` | ✅ |
| **Background** | `FirebaseMessaging.onMessageOpenedApp` | ✅ |
| **Terminated** | `checkNotificationLaunch()` → `getInitialMessage()` / `notificationAppLaunchDetails`, then `_waitForNavigator()` | ✅ |

The terminated path is the one that breaks in most apps, because navigation is attempted
before the navigator exists. This app already solves it with `_waitForNavigator()` and
`pendingDeepLink`, so a new case inherits that for free — **as long as you add your case
to the existing switch and don't build a separate handler.**

---

## 3. The change — one case

In `lib/core/services/app_notification.dart`, inside the
`switch (operation)` in `_onTapNotificationFromStatusBar`, next to the other admin
cases:

```dart
      // Admin promoted a creator's video/short to this user. Open the video
      // itself — the whole point of the push is the video, so landing on the
      // notification list would be a dead end.
      //
      // Routes through the SAME helper as the https://beapp.in/app/video/<id>
      // deep link (deep_link_router.dart → 'video'), so the two entry points
      // can never drift apart. The helper fetches the video and branches on the
      // type it gets BACK — deliberately not on `videoType` from the payload,
      // which is a snapshot taken when the admin composed the broadcast and can
      // be days stale by the time a scheduled campaign fires.
      case 'admin_video_promo':
        final videoId = (data['videoId'] ?? '').toString().trim();
        if (videoId.isEmpty) {
          // No id means nothing to open. The notification hub at least shows
          // the message rather than swallowing the tap entirely.
          logs('VIDEO_PROMO: payload had no videoId — falling back to hub');
          Get.toNamed(RouteHelper.getNotificationScreenRoute());
          break;
        }
        unawaited(deepLinkNetworkResources.navigateToVideoDetail(videoId));
        break;
```

Add the import if it isn't already there:

```dart
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
```

**No cold-start handling is needed in this case.** The block above the switch already
runs `Get.offAllNamed(<bottom nav>)` followed by
`await _waitForRoute(...)` for every `fromColdStart` tap except `admin_broadcast`, so by
the time the switch executes the home shell is on the stack and the navigator is live.
Adding another `_waitForNavigator()` here would be redundant. The push lands on top of
the home shell, so back returns to the app rather than exiting — which is exactly what
you want.

That is the functional change. §4 onward makes it robust.

---

## 4. Action button ("Watch now")

The push carries an action button with id `watch_video_<videoId>`. Action taps are
routed in `_handleActionButtonTap` **before** they reach the body-tap switch, so without
a case there the button does nothing. Add:

```dart
    // "Watch now" on a video promo — same destination as the body tap.
    if (actionId.startsWith('watch_video_')) {
      final videoId = actionId.substring('watch_video_'.length);
      if (videoId.isNotEmpty) {
        unawaited(deepLinkNetworkResources.navigateToVideoDetail(videoId));
      }
      return;
    }
```

---

## 5. Cold start

`_onTapNotificationFromStatusBar` records `pendingDeepLink` at the top for every
payload, and the cold-start boot reads it to decide how much of the home screen to
initialise. Two things to check for this operation:

1. **Map the operation in `PendingDeepLink.deriveTarget`**
   (`lib/core/services/notification/pending_deep_link.dart`). Unknown operations fall
   through to `DeepLinkTarget.notificationHub`, which still works — the tap routes
   correctly either way, since `deriveTarget` only decides *boot work*, not routing —
   but the reel target is the accurate one:

   ```dart
       // Reels (currently routed to the hub, kept here for the contract)
       case 'liked_reel':
       case 'commented_on_reel':
       case 'reposted_reel':
       case 'tagged_in_reel':
       // Admin video promo opens the player directly (see AppNotificationHandler).
       case 'admin_video_promo':
         return DeepLinkTarget.reel;
   ```

   `DeepLinkTarget.reel` has `needsSocket == false`, which is right: the player fetches
   over HTTP and needs no chat socket, so a cold-start promo tap does not pay for a
   socket handshake it will never use.

2. **Check the BlueEra-thread mirror.** Just below the cold-start block there is a
   catch-all that mirrors broadcast/system notifications into the BlueEra thread via
   `BlueEraNotificationController.to.addNotification(...)`. Its exclusion list covers
   chat, call, ride and greeting operations — `admin_video_promo` is **not** excluded,
   so it gets mirrored, same as `admin_broadcast` does today. The backend also emits a
   `chat.service` `ADMIN_BROADCAST` event for the same campaign, so verify on a device
   that the promo appears **once** in the BlueEra thread, not twice. If it duplicates,
   add `admin_video_promo` to that exclusion list rather than changing the backend —
   the server-side chat card is the one with persistence behind it.

3. **The cold-start guard at line ~3277** currently reads:

   ```dart
   if (fromColdStart && operation != 'admin_broadcast') {
   ```

   `admin_broadcast` is excluded because it runs its own `offAllNamed` stack swap.
   `admin_video_promo` does **not** do a stack swap — it pushes a player on top of the
   normal stack, which is what you want (back returns to the app rather than exiting).
   So it should go through the standard path. **Leave this condition alone.**

---

## 6. Android notification channel

The backend sends `channelId: video_promos`, `channelName: Video Highlights`,
`channelImportance: default`. The existing background handler already creates channels
from these fields, so nothing to add — but understand *why* it is a separate channel:

Android lets users disable channels individually. A user who wants marketing highlights
off must be able to turn them off **without** losing account, support and safety
announcements. Reusing the shared `announcements` channel would have forced that
trade-off and is how apps end up with notifications disabled entirely.

If you list channels in an in-app settings screen, add "Video Highlights" with a
description like *"New videos and shorts we think you'll enjoy."*

---

## 7. In-app notification list

The same broadcast also writes an inbox row. When the user taps it there, route it the
same way. The stored document looks like:

```jsonc
{
  "type": "admin_video_promo",
  "status": "UNREAD",
  "metadata": {
    "title": "…", "message": "…",
    "video_id": "68f0a1b2c3d4e5f60718293a",   // ← snake_case here
    "video_type": "short",
    "video_thumbnail": "https://…",
    "video_deep_link": "https://beapp.in/app/video/68f0…",
    "author_name": "Ravi Kumar",
    "broadcast_id": "68f1…"
  }
}
```

> **Watch the casing.** The FCM push uses `videoId` (camelCase); the stored inbox
> metadata uses `video_id` (snake_case). They come from different layers. Read both:

```dart
String? videoIdFrom(Map<String, dynamic> m) {
  final v = (m['videoId'] ?? m['video_id'] ?? '').toString().trim();
  return v.isEmpty ? null : v;
}
```

In the notification-list item tap handler:

```dart
if (item.type == 'admin_video_promo') {
  final id = videoIdFrom(item.metadata ?? {});
  if (id != null) {
    deepLinkNetworkResources.navigateToVideoDetail(id);
    return;
  }
}
```

Render the row with `video_thumbnail` as a leading 16:9 image — a video promo that looks
like a plain text row in the inbox gets ignored.

---

## 8. Let users mute promos

The backend files `admin_video_promo` under a **`promotions`** preference category. It
is deliberately not in the `admin` category, which bypasses preferences because it
carries operational and safety messages. So this one is genuinely mutable — expose it.

```
GET  /notification-service/notifications/settings
→ { success, data: { preferences: { chat: {...}, posts: {...}, promotions: { push: true, inApp: true }, … } } }

PUT  /notification-service/notifications/settings
Body: { "category": "promotions", "channel": "push", "enabled": false }
```

The settings screen is driven by the categories the API returns, so `promotions` appears
automatically once the backend is deployed. Give it a clear label — **"Promotions &
video highlights"** — so a user who mutes it knows exactly what they're muting.

---

## 9. Open tracking

`_onTapNotificationFromStatusBar` already logs a `notification_opened` GA4 event before
routing. Add `broadcast_id` and `video_id` so campaign click-through can be measured —
without them you can see that promos get opened, but not *which* promo:

```dart
    AnalyticsService.I.log(
      'notification_opened',
      AnalyticsService.params({
        'operation': operation,
        'from_cold_start': fromColdStart,
        // Ties an open back to the campaign that sent it. Only present on
        // admin_video_promo, so every other push logs exactly as before.
        if ((data['broadcastId'] ?? '').toString().isNotEmpty)
          'broadcast_id': data['broadcastId'].toString(),
        if ((data['videoId'] ?? '').toString().isNotEmpty)
          'video_id': data['videoId'].toString(),
      }),
    );
```

It is logged **before** routing, so an open is recorded even if the video fetch fails.

---

## 10. Testing

### 10.1 Real end-to-end (do this one)

Ask the backend to send you a single-user test broadcast:

```bash
curl -X POST "$BE/user-service/admin/broadcast" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'content-type: application/json' \
  -d '{"video_id":"<a real published video id>",
       "audience_filter":{"user_ids":["<your user id>"]},
       "schedule_mode":"now"}'
```

Then verify **all three states** — this is where bugs actually live:

| # | State | Steps | Expected |
|---|---|---|---|
| 1 | Foreground | App open on Home → send | Banner with thumbnail; tap → player opens on that video |
| 2 | Background | Home button, app in recents → send | Tap → app resumes → player opens; back returns to app |
| 3 | **Terminated** | Swipe app from recents → send | Tap → app cold-starts → **loader → player**, not Home |
| 4 | Action button | Any state | "Watch now" opens the same video |
| 5 | Long video | Promote a `long` video | Opens `VideoPlayerScreen`, not the shorts player |
| 6 | Inbox | Open notification list | Row shows thumbnail; tap opens the video |
| 7 | Muted | Turn off `promotions` push → send | No push arrives (inbox row may still appear if inApp is on) |

State 3 is the one to test on a **real device**, not an emulator, and on both a fast and
a slow phone. It is where `_waitForNavigator` earns its keep.

### 10.2 Payload-only test (no backend needed)

Firebase Console cannot send data-only messages, so use the FCM HTTP v1 API:

```bash
curl -X POST "https://fcm.googleapis.com/v1/projects/blueera-50c05/messages:send" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H 'content-type: application/json' \
  -d '{
    "message": {
      "token": "<device fcm token>",
      "android": { "priority": "high" },
      "data": {
        "operation": "admin_video_promo",
        "title": "Diwali special recipe",
        "body": "Ravi Kumar just posted a new short — tap to watch.",
        "imageUrl": "https://picsum.photos/800/450",
        "style": "bigPicture",
        "channelId": "video_promos",
        "channelName": "Video Highlights",
        "channelImportance": "default",
        "actions": "[{\"id\":\"watch_video_68f0a1b2c3d4e5f60718293a\",\"text\":\"Watch now\"}]",
        "videoId": "68f0a1b2c3d4e5f60718293a",
        "videoType": "short",
        "videoTitle": "Diwali special recipe",
        "videoThumbnail": "https://picsum.photos/800/450",
        "deepLink": "https://beapp.in/app/video/68f0a1b2c3d4e5f60718293a",
        "targetScreen": "reel_player",
        "authorName": "Ravi Kumar",
        "broadcastId": "test-broadcast-1"
      }
    }
  }'
```

Use a **real** `videoId` — `navigateToVideoDetail` fetches it, and a fake id correctly
shows an error snackbar instead of a player.

---

## 11. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Push arrives, tap opens the notification list | No `admin_video_promo` case; falling through to default | §3 |
| Tap does nothing when app was killed | The case was added outside the existing switch, bypassing the cold-start block | Put it **in** `_onTapNotificationFromStatusBar`'s switch (§3) — that block already waits for the home route |
| "Something went wrong" snackbar after tap | Video deleted / unpublished since the broadcast was composed | Expected. The backend blocks this at compose time, but a scheduled campaign can fire after the creator unpublishes. |
| Opens the shorts player for a long video | Routing off payload `videoType` instead of the helper | Pass only `videoId` to `navigateToVideoDetail` (§3) |
| No thumbnail on the banner | `imageUrl` unreachable or > 1 MB, or not HTTPS | Check the video's `thumbnails.high` in video-service |
| Push never arrives | User muted `promotions`, or no device token | Check `GET /notifications/settings`; confirm token registration |
| "Watch now" button does nothing | Action ids are handled before the body switch | §4 |
| Works on Android, not iOS terminated | iOS surfaces the launch tap only via `getInitialMessage()` | Already handled in `checkNotificationLaunch()` — verify the branch runs for this operation |

---

## 12. Checklist

- [ ] `case 'admin_video_promo'` added to the tap switch (§3)
- [ ] `deeplink_network_resources.dart` imported in `app_notification.dart`
- [ ] `watch_video_` action-id branch added (§4)
- [ ] `PendingDeepLink.deriveTarget` maps it to `DeepLinkTarget.reel` (§5)
- [ ] BlueEra-thread mirror shows the promo once, not twice (§5)
- [ ] Notification-list row routes on `video_id` / `videoId` (§7)
- [ ] "Promotions & video highlights" toggle visible in settings (§8)
- [ ] `broadcast_id` included in the open analytics event (§9)
- [ ] All three app states verified on a real device (§10.1)

---

**Related:** [ADMIN_VIDEO_BROADCAST_NEXTJS_GUIDE.md](ADMIN_VIDEO_BROADCAST_NEXTJS_GUIDE.md)
— the admin side that produces these notifications.

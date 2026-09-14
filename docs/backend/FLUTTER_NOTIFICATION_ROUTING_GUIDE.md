# Flutter — Notification Routing & Implementation Guide

Every notification type produced by the recent work: what arrives, which screen
opens, what UI to show, and what the app must report back.

Scope: `admin_promotion`, `admin_video_promo`, `admin_broadcast`,
`admin_system_announcement` / `admin_urgent_broadcast` / `admin_bulk_notification`,
plus the channel model, the mute toggle and engagement tracking.

**Everything routes through one place** — the `switch (operation)` inside
`AppNotificationHandler._onTapNotificationFromStatusBar`
(`lib/core/services/app_notification.dart`). That block already handles
cold-start navigation, analytics and the BlueEra-thread mirror, so a new case
inherits all of it. Anything added outside it re-implements those and gets the
terminated-app path wrong.

---

## 1. The operations, and where each must land

| `operation` | Sent by | Opens | Status today |
|---|---|---|---|
| `admin_promotion` | **Engagement engine** (auto) + Custom Notification | `deepLink` if present, else notification hub | ⬜ **not handled — §3** |
| `admin_video_promo` | Video Broadcast | The video player | ⬜ see [video guide](FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md) |
| `admin_broadcast` | New Broadcast, legacy | BlueEra chat thread | ✅ handled |
| `admin_system_announcement` | Custom Notification · Announcement | Notification hub | ✅ handled |
| `admin_urgent_broadcast` | Custom Notification · Alert | Notification hub | ✅ handled |
| `admin_bulk_notification` | Generic bulk API | Notification hub | ✅ handled |

An unknown operation already falls through to `default:` and lands on the
notification hub, so nothing dead-ends. But a promo whose entire purpose is to
open a screen landing on a list is a wasted send.

---

## 2. The payload

FCM data is **always strings** — `videoDuration` is `"42"`, never `42`.

### Common to every notification

| Key | Example | Notes |
|---|---|---|
| `operation` | `admin_promotion` | **Route on this** |
| `title` / `body` | `Kal Sunday hai 🫘` | Already rendered by the existing builder |
| `imageUrl` | `https://…jpg` | Drives `style: bigPicture` |
| `style` | `bigPicture` \| `bigText` \| `default` | |
| `channelId` | `announcements`, `video_promos` | Android channel |
| `actions` | `[{"id":"…","text":"…"}]` | JSON string |
| `operation` | | |

### Added by the recent work

| Key | Present when | Use |
|---|---|---|
| **`deepLink`** | the notification has a destination | **The one field to route on.** Normalised from `link` / `url` / `deep_link` / video link, so every producer looks the same |
| **`broadcastId`** | the notification belongs to a campaign | **Report it back** — §6. Without it opens/clicks stay at zero |
| `videoId`, `videoType`, `authorName`, `targetScreen` | `admin_video_promo` only | See the video guide |

> `deepLink` used to be emitted **only** for video notifications. An engagement
> theme pointing at `/app/jobs` carried its destination on the chat card alone,
> so tapping the push went to the hub. Both producers now emit the same flat key.

### Example — an engagement push

```jsonc
{
  "operation": "admin_promotion",
  "title": "Naye jobs aaye hain 💼",
  "body": "Aapke area mein kuch acche openings hain — dekh lo.",
  "imageUrl": "",
  "style": "bigText",
  "channelId": "announcements",
  "deepLink": "https://beapp.in/app/jobs",
  "broadcastId": "6aa4f1b2c3d4e5f607182930"
}
```

---

## 3. `admin_promotion` — the case to add

Everything the engagement engine sends arrives under this operation, at up to
3 per user per day.

```dart
      // Engagement engine + Custom Notification. Marketing, so it is mutable
      // (the `promotions` toggle) and rate-capped server-side.
      //
      // Routes off `deepLink`, which the backend normalises from link/url/
      // deep_link — so this one case covers every destination a theme can
      // point at (a category, jobs, a product) without knowing any of them.
      // No deepLink is normal: plenty of engagement copy is a nudge to open
      // the app at all, and the hub is the right landing for that.
      case 'admin_promotion':
        final link = (data['deepLink'] ?? '').toString().trim();
        if (link.isEmpty) {
          Get.toNamed(RouteHelper.getNotificationScreenRoute());
          break;
        }
        // Reuse the SAME resolver App Links already go through, so a
        // notification and a shared link can never route differently.
        unawaited(DeepLinkRouter.handleUri(Uri.parse(link)));
        break;
```

Add it next to the other `admin_*` cases (~line 3543). Check the exact name of
your App-Links entry point in `lib/core/services/deep_link_router.dart` and call
that — the point is to route through the existing resolver, not to re-implement
path parsing.

### Why not build a promo screen

An engagement notification is a nudge toward something that already exists — a
category, a video, the jobs list. A dedicated promo screen would be a second
surface to maintain that shows nothing the destination does not already show.

---

## 4. What the user actually sees, per channel

The admin picks channels per campaign, and the combination changes what the app
must handle. All four are live:

| Channels | Push banner | Inbox row | BlueEra chat |
|---|---|---|---|
| push + inApp + chat | ✅ | ✅ | ✅ |
| **push only** | ✅ | ❌ | ❌ |
| **inApp only** | ❌ **silent** | ✅ | ❌ |
| chat only | ❌ silent | ❌ | ✅ |

Two consequences for the app:

1. **A notification can arrive with no push at all.** An in-app-only campaign
   appears in the list the next time the user opens the app. The inbox must not
   assume every row was preceded by a banner.
2. **A push can exist with no inbox row.** Push-only is deliberate for
   time-critical, disposable copy. Do not write a local inbox row on push
   receipt to "fix" the gap — that would silently undo the admin's choice.

---

## 5. The in-app notification list

Rows come from `GET /notification-service/notifications`. The same tap routing
applies — a user who opens the list instead of the banner must reach the same
screen.

> **Casing differs by layer.** The FCM push uses `deepLink` / `broadcastId`
> (camelCase); the stored inbox metadata uses `deep_link` / `broadcast_id`
> (snake_case). They come from different producers. Read both:

```dart
String? _link(Map<String, dynamic> m) {
  final v = (m['deepLink'] ?? m['deep_link'] ?? m['link'] ?? m['url'] ?? '')
      .toString().trim();
  return v.isEmpty ? null : v;
}

String? _campaignId(Map<String, dynamic> m) {
  final v = (m['broadcastId'] ?? m['broadcast_id'] ??
             m['bulkNotificationId'] ?? '').toString().trim();
  return v.isEmpty ? null : v;
}
```

On tap of a row whose `type` is `admin_promotion`:

```dart
final meta = item.metadata ?? {};
unawaited(trackNotification(meta, kind: 'open'));      // §6
final link = _link(meta);
if (link != null) {
  unawaited(DeepLinkRouter.handleUri(Uri.parse(link)));
} else {
  // Already on the list — just mark it read.
}
```

Render `imageUrl` as a leading thumbnail when present. An engagement row that
looks like plain text gets scrolled past.

---

## 6. Tracking — without this the dashboard is half dead

`opened`, `clicked` and `converted` do not exist until the app reports them.
**Until this ships those three read zero for every campaign**, and the admin
dashboard's whole engagement half is empty. That is expected, not a backend bug.

```dart
/// Report engagement with a campaign notification.
///
/// Fire-and-forget by design: analytics must never delay the screen the user
/// asked for, and must never surface an error to them. The endpoint is
/// idempotent — a repeat returns counted:false — so there is nothing to guard
/// against on the client.
Future<void> trackNotification(
  Map<String, dynamic> data, {
  String kind = 'open',
  String? actionId,
  bool? fromColdStart,
}) async {
  final campaignId = _campaignId(data);
  if (campaignId == null) return;   // transactional push — nothing to track

  try {
    await ApiBaseHelper().postHTTP(
      'notification-service/notifications/track',
      params: {
        'campaignId': campaignId,
        'kind': kind,                 // open | click | convert
        'operation': (data['operation'] ?? '').toString(),
        if (actionId != null) 'actionId': actionId,
        'platform': Platform.isIOS ? 'ios' : 'android',
        if (fromColdStart != null) 'fromColdStart': fromColdStart,
      },
      showProgress: false,
    );
  } catch (_) {
    // Swallowed on purpose — a lost analytics ping is not worth a snackbar.
  }
}
```

Three call sites:

```dart
// 1. Body tap — in _onTapNotificationFromStatusBar, beside the existing
//    AnalyticsService.I.log('notification_opened', …).
unawaited(trackNotification(data, kind: 'open', fromColdStart: fromColdStart));

// 2. Action-button tap — in _handleActionButtonTap.
unawaited(trackNotification(data, kind: 'click', actionId: actionId));

// 3. Destination reached — e.g. the video actually started playing.
unawaited(trackNotification(data, kind: 'convert'));
```

`open` is a tap. `convert` is arrival. They differ more than they look: a tap
that lands on a dead screen still counts as an open, and the gap between the two
is the clearest signal that a destination is broken.

---

## 7. The mute toggle — required, not optional

`admin_promotion` and `admin_video_promo` sit in the **`promotions`** category,
which is genuinely mutable. `admin_broadcast` and `admin_system_announcement`
sit in `admin`, which bypasses preferences because it carries operational and
safety messages.

```
GET  /notification-service/notifications/settings
PUT  /notification-service/notifications/settings
     { "category": "promotions", "channel": "push", "enabled": false }
```

The settings screen is driven by the categories the API returns, so
`promotions` appears on its own. Label it **"Promotions & suggestions"** so a
user muting it knows exactly what stops — and that order updates and calls will
not.

This matters more now than it did: an automated engine sends up to 3 marketing
pushes a day. The mute is the pressure valve. If users cannot find it they
disable notifications at OS level instead, and on iOS that is permanent.

> Verified in production: with `promotions.push` off, a promo records
> `suppressed=1, attempted=0` — it is never even sent — while an announcement
> under the same mute still arrives.

---

## 8. Android channels

The backend sets `channelId` per operation and the existing handler creates the
channel from the payload. Nothing to add — but know why they are separate:

| Operation | Channel | Importance |
|---|---|---|
| `admin_video_promo` | `video_promos` | default |
| `admin_promotion`, `admin_*` | `announcements` | default |
| calls | `incoming_calls` | max |
| chat | `messages` | high |

Android lets users disable channels individually. Marketing on its own channel
means someone can silence promos **without** losing account, support and safety
notifications. Merging them would force that trade and is how an app ends up
fully muted.

---

## 9. Test matrix

Ask the backend to target your user id only
(`audience_filter: { user_ids: ["<you>"] }`).

| # | Send | Expect |
|---|---|---|
| 1 | `admin_promotion`, no deepLink | Push → tap → notification hub |
| 2 | `admin_promotion` + `deepLink: /app/jobs` | Push → tap → **jobs screen** |
| 3 | `admin_video_promo` | Push with thumbnail → tap → **player on that video** |
| 4 | `admin_broadcast` | Push → tap → BlueEra chat thread |
| 5 | `admin_system_announcement` | Push → tap → notification hub |
| 6 | channels `["inApp"]` | **Silent.** Row appears on next app open |
| 7 | channels `["push"]` | Buzzes. **No** inbox row afterwards |
| 8 | Tap, then check the campaign | `opened` becomes 1 |
| 9 | **Tap again** | Still **1** — unique, not a tap count |
| 10 | Mute promotions → send `admin_promotion` | **Nothing arrives** |
| 11 | Mute promotions → send announcement | Still arrives |
| 12 | Terminated app, tap | Cold start → correct screen, not Home |

**12 is the one that breaks in most apps.** Test it on a real device, both a
fast and a slow one — it is where the cold-start wait earns its keep.

---

## 10. Checklist

- [ ] `case 'admin_promotion'` added to the tap switch (§3)
- [ ] `admin_video_promo` case added ([video guide](FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md) §3)
- [ ] `watch_video_` action-id branch (video guide §4)
- [ ] Inbox rows route on `deep_link` / `deepLink`, reading both casings (§5)
- [ ] `trackNotification` wired at all three call sites (§6)
- [ ] "Promotions & suggestions" toggle visible in settings (§7)
- [ ] All 12 rows of §9 verified on a real device

---

**Related:** [FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md](FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md) ·
[ADMIN_NOTIFICATION_CENTER_GUIDE.md](ADMIN_NOTIFICATION_CENTER_GUIDE.md) ·
[ENGAGEMENT_ENGINE_PLAN.md](ENGAGEMENT_ENGINE_PLAN.md)

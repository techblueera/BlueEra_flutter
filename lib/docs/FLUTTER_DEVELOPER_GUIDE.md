# Go-Live Daily Reminder — Flutter Developer Guide

---

## The answer

> **No Flutter code changes required. Existing notification infrastructure automatically
> supports this reminder.**

You can ship the backend without an app release. Users on the **current production build**
will receive the reminder correctly: it displays, it plays by their notification settings,
tapping it opens the app, and it appears in the notification list.

Read §6 only if product later wants the tap to land on the Go-Live screen specifically
rather than the notification hub. That is an **enhancement, not a fix**.

---

## 1. Why nothing is needed

The BlueEra notification pipeline is **data-driven, not operation-driven**. The backend
sends a data-only FCM message and the app builds the notification from generic fields it
already reads for every notification type.

| Concern | Existing handling | Change needed |
|---|---|---|
| Foreground display | `FirebaseMessaging.onMessage` → `_showLocalNotification` | none |
| Background / terminated display | `firebaseMessagingBackgroundHandler` (`main.dart:662`) | none |
| Tap while backgrounded | `FirebaseMessaging.onMessageOpenedApp` | none |
| Tap from terminated (cold start) | `FirebaseMessaging.instance.getInitialMessage()` | none |
| Android channel | Created at runtime from `data.channelId/channelName/channelImportance` | none |
| iOS presentation | Existing APNs alert config | none |
| Permissions | Already requested at onboarding | none |
| Routing on tap | `AppNotificationHandler.routeNotificationData` `default:` branch | none |
| Action button | Unknown `actionId` → generic tap handler | none |
| Notification list entry | Backend persists a `notifications` row; the list renders it | none |
| Mute / settings | Category `orders`, already in the settings UI | none |

The only way an app change would be required is if the backend introduced a **new data
key** or a **new channel id** the app does not understand. It does neither.

---

## 2. The FCM payload the app receives

The message is **data-only** — there is no `notification` block, so the OS does not
auto-display it and the Flutter handler builds exactly one local notification.

```jsonc
{
  "data": {
    "title": "Good Morning ☀️",
    "body": "Go Live now and unlock today's earning opportunities in your area.",
    "imageUrl": "",
    "style": "default",

    "channelId": "default",
    "channelName": "Notifications",
    "channelImportance": "default",

    "groupKey": "go_live_daily_reminder",
    "actions": "[{\"id\":\"go_live_now\",\"text\":\"Go Live\"}]",

    "operation": "go_live_daily_reminder",
    "notificationId": "1753166401234",
    "timestamp": "2026-07-22T02:30:01.000Z",

    "senderId": "",
    "senderName": "Blue Era",
    "senderProfileImage": "",

    "mediaUrl": "", "mediaType": "", "mediaThumbnail": "",
    "mediaDuration": "", "mediaFileName": "",

    "payload": "{\"title\":\"Good Morning ☀️\",\"body\":\"…\",\"message\":\"…\",\"cta\":\"go_live\",\"reminder_date\":\"2026-07-22\",\"variant\":\"good_morning\",\"run_id\":\"glr_m9x2k1_a7b3c9\"}"
  }
}
```

Every key is one the app **already** consumes. Notes:

* `channelId` is `default` — the operation matches no entry in the backend's `channelMap`
  and no prefix rule (`sent_message*`, `ride_*`, `admin_*`, `channel_*`, `follower_*`), so
  it falls back to `{ id: "default", name: "Notifications", importance: "default" }`.
  `_mapImportanceFromString("default")` → `Importance.defaultImportance`. Correct for a
  daily nudge: it posts a normal banner, not a heads-up interrupt.
* `style` is `default` (no image, body under 100 chars) → a standard notification.
* `payload` carries the full original `data` blob, including `run_id` — useful for support:
  a user's screenshot can be traced back to an exact backend run in CloudWatch.
* `groupKey` bundles reminders on Android. Since only one is sent per day, bundling is
  effectively a no-op.

---

## 3. Behaviour on the current build

### Android

| State | Result |
|---|---|
| Foreground | `onMessage` → local notification on the `default` channel with a **Go Live** action button |
| Background | Background handler → same notification |
| Terminated | Same — data-only messages wake the handler on Android |
| Tap notification body | App opens → notification hub screen |
| Tap **Go Live** button | Unknown `actionId` → generic tap path → notification hub |

### iOS

| State | Result |
|---|---|
| Foreground | `onMessage` → local notification |
| Background | APNs alert (`apns-priority: 10`, `mutable-content: 1`) displays the banner |
| Terminated | Banner displays; payload delivered via `getInitialMessage()` on launch |
| Tap | Same routing as Android |

> This reminder does **not** use the VoIP/PushKit path — that is reserved for ringing call
> operations with a real `call_id`. This is a normal alert push.

---

## 4. Verifying without an app release

1. Ensure a test account has `profileType` = `GIG_WORKER` or `SELF_EMPLOYED` and a valid
   `device_token`.
2. Ask a backend engineer to trigger a run on demand — no need to wait for 08:00:

   ```bash
   # in be_user_service (KAFKA_BROKERS must be set)
   node --input-type=module -e "
     import('./src/workers/goLiveDailyReminder.worker.js')
       .then(m => m.runDailyReminder())
       .then(s => { console.log(s); process.exit(0); });
   "
   ```

   Re-running the same day intentionally sends nothing (one reminder per user per
   day). To force a repeat while testing, pass a different day:
   `m.runDailyReminder({ dateKey: '2026-01-01' })`.

3. Check:
   - [ ] Notification appears with the correct title and body
   - [ ] A **Go Live** action button is present (Android)
   - [ ] Tapping opens the app without a crash
   - [ ] The reminder appears in the in-app notification list
   - [ ] Muting **Orders → Push** in notification settings suppresses the next one
   - [ ] Running the worker again the same day sends **nothing**

---

## 5. Do NOT reuse `actionId: "go_live"`

The backend deliberately uses **`go_live_now`**, not `go_live`.

`AppNotificationHandler` already routes `actionId == 'go_live'` to
`RouteConstant.BusinessOwnProfileScreen` using `data['business_id']` — that path belongs to
the **business** go-live reminder. Gig Worker and Self Employed users are **individuals**
with no `business_id`, so reusing that id would push them into a business profile screen
with a null id.

If you add explicit handling (§6), key it on `go_live_now` and route to the **individual**
go-live surface.

---

## 6. Enhancement — deep-link the tap to Go Live — **IMPLEMENTED**

Implemented in `lib/core/services/app_notification.dart`. The tap (body or **Go Live**
button) now lands on the user's own profile — Me → Overview — instead of the notification
hub. Both call sites share a `_openMeOverview()` helper, which `profile_completion_reminder`
also now uses.

### 6.1 Route the operation

`lib/core/services/app_notification.dart` — in the `switch` inside
`routeNotificationData`, next to the existing `profile_completion_reminder` case:

```dart
// Daily go-live nudge for GIG_WORKER / SELF_EMPLOYED individuals → the user's
// own Me tab, which hosts the Go Live control. Reuse the live bottom-nav shell
// when present (pop pushed screens, then switch tab); otherwise route fresh.
case 'go_live_daily_reminder':
  if (Get.isRegistered<BottomBarController>()) {
    Get.until((route) => route.isFirst);
    Get.find<BottomBarController>().openMeOverviewTab();
  } else {
    Get.offAllNamed(
      RouteHelper.getBottomNavigationBarScreenRoute(),
      arguments: {ApiKeys.initialIndex: BottomBarController.meTabIndex},
    );
  }
  break;
```

This mirrors the `profile_completion_reminder` case exactly and reuses
`BottomBarController.openMeOverviewTab()` / `meTabIndex`, which already exist.

### 6.2 Route the action button

In `_handleNotificationAction`, before the generic fallback:

```dart
// Individual go-live CTA. Distinct from 'go_live' (business), which deep-links
// to BusinessOwnProfileScreen using a business_id an individual does not have.
if (actionId == 'go_live_now') {
  if (Get.isRegistered<BottomBarController>()) {
    Get.until((route) => route.isFirst);
    Get.find<BottomBarController>().openMeOverviewTab();
  } else {
    Get.offAllNamed(
      RouteHelper.getBottomNavigationBarScreenRoute(),
      arguments: {ApiKeys.initialIndex: BottomBarController.meTabIndex},
    );
  }
  return;
}
```

### 6.3 Files touched

| File | Change |
|---|---|
| `lib/core/services/app_notification.dart` | +1 `case` in the routing switch, +1 `if` in the action handler |

No new routes, no new screens, no new dependencies, no manifest or `Info.plist` change.

### 6.4 Test matrix for the enhancement

| State | Tap target | Expected |
|---|---|---|
| Foreground | body / button | Me tab, overview |
| Background | body / button | Me tab, overview |
| Terminated | body / button | app boots → Me tab, overview |
| Already on Me tab | body / button | stays, no duplicate push |

---

## 7. Backward and forward compatibility

* **Old app + new backend** — works. Unknown operations hit the `default:` branch and land
  on the notification hub. This is exactly why no coordinated release is needed.
* **New app + old backend** — works. The new `case` simply never fires until the backend
  starts emitting the operation.
* **Rollout order is free.** Backend and app can ship in either order, independently.

---

## 8. What the app must NOT do

* Do not schedule this reminder locally. It is server-driven so it can be tuned,
  audited, muted and killed without an app release.
* Do not treat `go_live_daily_reminder` as a call or ring notification — it is a normal
  alert on the `default` channel.
* Do not read `data.business_id` for this operation. It is not sent, and these users are
  individuals.
* Do not add a dedicated Android channel for it. The backend controls channel assignment;
  adding a client-side override would desynchronise the two.

---

## 9. Related

* `BlueEra_flutter/lib/core/services/app_notification.dart` — the notification handler
  (routing switch, action handler, local-notification builder)
* `be_notification_service/FLUTTER_NOTIFICATION_GUIDE.md` — platform-wide FCM data contract
* `be_notification_service/public/notification-templates.json` — the push copy template
  (`go_live_daily_reminder`)
* `be_user_service/src/workers/goLiveDailyReminder.worker.js` — the producer; its header
  comment documents the payload contract, scheduling and idempotency model

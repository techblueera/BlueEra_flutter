# WhatsApp-Style Notification Fast-Open — Design Doc

**Goal:** Tapping any push notification (from killed / background / foreground) opens the
app **smoothly and instantly** to the correct target screen, rendered **cache-first**, with
**at most one small incremental API call** — and **without** booting the full home/Discover
feed in the background on every notification open.

**Scope:** Chat messages, Calls, Posts/Reels/Social, Ride/Orders.

**Status:** Design — no code changes yet.

---

## 1. Current state (baseline)

The notification system is already solid. What works today:

| Capability | Where | Notes |
|---|---|---|
| Background FCM handler registered before `runApp` | `lib/main.dart:570` | Killed-state pushes (calls) reach Dart. Keep as-is. |
| Splash "hold" until routing done | `splash_screen.dart:104-116` | Uses `launchedFromNotification` + `notificationNavigationCompleter`. |
| Direct routing by `operation` | `app_notification.dart` `_onTapNotificationFromStatusBar()` (≈2146-2414) | Big switch over operation types. |
| **No API call just to navigate** (most types) | `app_notification.dart` | Data comes from the FCM payload. Chat persists message to Hive from payload. |
| Cold-start de-dupe guard | `app_notification.dart:677-692` (`_lastHandledLaunchNotificationIdKey`) | Stops the same notification re-opening on every launch. |
| Cold-start call accept/decline (native + CallKit) | `main.dart:633-780` | Already handles Accept/Decline before `runApp`. |

### The actual problem

Opening from a notification still triggers a **full home boot in parallel**, independent of the
deep link. On every cold start the app pays:

1. **`_initDeferred` heavy batch** — `main.dart:858-868`:
   `getChannelData`, `getServiceProviderStatusUtils`, `getDeviceInfo`, `LocationService.fetchLocation`,
   `InterstitialAdManager.initialize`, multiple `Hive.openBox`, cache services.
2. **Home / Discover tab init** — `bottom_navigation_bar_screen.dart`:
   - `loadCategoriesCacheFirstThenRefresh()` (categories API) — line ~270.
   - `getChannelDetails()` for individual users (~2s delayed) — lines ~286-305 / 365.
   - Socket connect (`ChatViewController`), profile fetches (`ViewPersonalDetailsController`,
     `ViewBusinessDetailsController`).
   - Discover sections gated on location readiness.
3. **No lazy tabs** — all tabs are built upfront (switch in `bottom_navigation_bar_screen.dart:488-507`);
   there is **no** mechanism to skip/defer home init when deep-linking.

So tapping a chat notification renders the chat *and* boots the entire home+Discover feed behind it.
That is the "multiple APIs on every notification open" the user is reporting.

---

## 2. Target model (WhatsApp)

1. **Payload carries everything to render** the target → **0 APIs to open**.
2. Target screen shows **cache-first** (Hive) instantly, then fires **one delta** fetch
   (e.g. "messages since lastSync"), never a full reload.
3. **Home/feed does not initialize** until the user actually navigates to it.

We are already at (1). The work is (2) and (3).

**Per-notification-open budget:** `0` navigation APIs + `≤ 1` incremental fetch on the target screen.

---

## 3. Design

### 3.1 Canonical deep-link payload contract (Phase 1)

Today routing branches on `operation` with ad-hoc field names per type. Standardize **one**
data shape across all FCM pushes (backend contract). Backward-compatible: keep reading legacy
fields, add the canonical ones.

```jsonc
{
  "operation": "sent_message",      // existing event type (kept)
  "dl_version": "1",                // deep-link schema version
  "dl_target": "chat",             // chat | call | post | reel | connection | ride | rider_order | notification_hub
  "dl_entity_id": "<id>",          // conversationId | postId | orderId | callId ...
  "dl_secondary_id": "<id>",       // optional (repost_id, room_id, message_id)
  "dl_title": "...",
  "dl_body": "...",
  "notificationId": "<unique>"      // existing; used by the de-dupe guard
}
```

- `dl_target` removes the need to map every `operation` string in the router — unknown
  operations fall through to the notification hub safely.
- If `dl_*` fields are absent (old backend), derive `dl_target` from `operation` via a single
  mapping table so nothing breaks during rollout.

### 3.2 One deep-link object + one router (Phase 1)

Introduce a single value object and a single entry point. Consolidates routing currently
spread across `main.dart` (call cold-start), `checkNotificationLaunch()`,
`firebaseNotificationSetup()`, and `getInitialMsg()`.

```dart
// new: lib/core/services/notification/pending_deep_link.dart
class PendingDeepLink {
  final String target;        // dl_target (or derived from operation)
  final String entityId;
  final String? secondaryId;
  final Map<String, dynamic> raw;
  const PendingDeepLink({required this.target, required this.entityId, this.secondaryId, required this.raw});
  static PendingDeepLink? fromData(Map<String, dynamic> data) { /* parse + derive target */ }
}
```

- `AppNotificationHandler` exposes a static `PendingDeepLink? pendingDeepLink` set the moment a
  launch payload is detected (cold start) — **before** the home boot decisions run.
- A single `NotificationRouter.route(PendingDeepLink, {required bool fromColdStart})` owns the
  `switch (target)` and calls the per-type openers (chat/call/post/ride). The existing
  `_onTapNotificationFromStatusBar` becomes a thin adapter that builds a `PendingDeepLink` and
  delegates, so we don't rewrite every case at once.
- Keep the existing **de-dupe guard** (`_lastHandledLaunchNotificationIdKey`) and the
  **completer** that splash awaits — no behavior change there.

### 3.3 Lazy home — the core fix (Phase 2)

**File:** `lib/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart`

1. Replace the upfront tab switch with a **lazy `IndexedStack`**: keep a `List<Widget?>` of tab
   bodies initialized to `null`; build a tab the first time its index is visited. Visited tabs
   stay alive (state preserved); unvisited tabs never run their `initState`/API calls.
2. Add a constructor flag `bool deferHeavyInit` (default `false`). Set it `true` when the screen
   is created as the *background* host while a deep link is being routed.
3. Gate the eager startup calls in this screen on `!deferHeavyInit`:
   - `loadCategoriesCacheFirstThenRefresh()` (line ~270)
   - `getChannelDetails()` individual-user block (lines ~286-305)
   These then run the first time the user actually opens Home/Discover instead of on cold start.

**Effect:** When you tap a chat notification, only the chat tab/screen builds; Discover, its
categories, channel-details, and section APIs stay dormant until the user taps Home.

### 3.4 Defer the `_initDeferred` heavy batch on deep-link (Phase 3)

**File:** `lib/main.dart` `_initDeferred()` (≈846-907)

When `AppNotificationHandler.pendingDeepLink != null`:

- **Run immediately (target needs them):** notification setup + token sync, Hive boxes the target
  reads, and — for chat — socket connectivity (`ChatViewController` connect) + `PendingMessageDrainer`.
- **Postpone until first frame is settled / user returns Home:** `getChannelData`,
  `getServiceProviderStatusUtils`, `getDeviceInfo` (non-blocking already), `LocationService.fetchLocation`,
  `InterstitialAdManager.initialize`, language preload, version check.

Implementation: split `_initDeferred` into `_initEssential()` (always) and `_initBackground()`
(scheduled via a post-frame callback, or triggered when the user first lands on Home). On a normal
(non-notification) launch, both run as today.

### 3.5 Cache-first target screens (Phase 4)

| Type | Open behavior | API budget |
|---|---|---|
| **Chat** | Persist payload message to Hive (already done), open thread from Hive instantly, connect socket, request **delta** (messages since last sync) — no full reload. | ≤1 delta |
| **Call** | Cold-start accept/decline already handled pre-`runApp` (`main.dart:633-780`); body-tap opens `IncomingCallScreen` from payload (`app_notification.dart:701-718`). Keep. | 0 to open (accept fires its own join) |
| **Post/Reel** | Render header/preview from `dl_*` payload, fetch the single post detail lazily (1 API). Don't load any feed list. | ≤1 |
| **Ride/Order** | Fare-ride incoming populates `CallController` from payload (no API). Ride/order status opens the order screen and fetches that **one** order, not the list. | ≤1 |

### 3.6 Startup API de-dup guard (Phase 5)

Add a lightweight "fired this session" set (or per-endpoint timestamp) so the same endpoint
isn't called by both `_initBackground()` and a home controller after a deep-link defer. Goal:
verify the per-open budget (`0` + `≤1`) holds for each type.

---

## 4. Per-type routing summary (after refactor)

```
dl_target == "chat"      -> open chat thread (Hive-first + delta)        [Phase 4]
dl_target == "call"      -> cold-start accept/decline OR IncomingCallScreen (existing)
dl_target == "post"/"reel" -> PostDetailPage (payload preview + 1 fetch)
dl_target == "connection"  -> NotificationScreen hub (no API)
dl_target == "ride"        -> RiderServiceScreen / order screen (1 order fetch)
dl_target == "rider_order" -> IncomingRiderOrderScreen (payload only)
default                    -> NotificationScreen hub
```

In all cases the home/Discover boot is deferred (Phase 2 + 3) until the user navigates Home.

---

## 5. Files touched

| File | Change | Phase |
|---|---|---|
| `lib/core/services/notification/pending_deep_link.dart` *(new)* | `PendingDeepLink` value object + parser/derive-target | 1 |
| `lib/core/services/notification/notification_router.dart` *(new)* | Single `route()` switch over `dl_target` | 1 |
| `lib/core/services/app_notification.dart` | Set `pendingDeepLink`; make `_onTapNotificationFromStatusBar` delegate to router; keep de-dupe + completer | 1,4 |
| `lib/main.dart` | Split `_initDeferred` → essential vs background; gate on `pendingDeepLink` | 3 |
| `lib/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart` | Lazy `IndexedStack`; `deferHeavyInit` flag; gate categories/channel-details | 2 |
| `lib/features/common/onboarding/view/splash_screen.dart` | Pass `deferHeavyInit: true` when home is the background host during deep-link | 2 |
| Chat screen/controller | Ensure cache-first open + delta-only fetch | 4 |
| Post detail open path | Single-post fetch from payload | 4 |
| Ride/order open path | Single-order fetch from payload | 4 |

---

## 6. Risks & mitigations

- **Chat needs the socket** even when home is deferred → explicitly connect socket in
  `_initEssential()` for `dl_target == chat`.
- **FCM token sync** must still happen → keep in essential path (can run a few seconds after first
  frame; not blocking).
- **Lazy IndexedStack** can break code that assumes all tab controllers exist at startup → audit
  `Get.find<…>()` calls that currently rely on home building every tab; make them `Get.put` lazily
  or null-safe.
- **iOS APNs cold start** path differs (payload only via `getInitialMessage`) — already handled in
  `checkNotificationLaunch()` (`app_notification.dart:648-658`); route through the same
  `PendingDeepLink`.
- **Backend rollout** — `dl_*` fields optional; derive from `operation` so old payloads still route.

---

## 7. Test matrix

App state × type × platform:

- States: **killed**, **background**, **foreground**.
- Types: **chat**, **call** (incoming body-tap / accept action / decline / missed), **post/reel**,
  **ride** (fare-incoming / order status).
- Platforms: **Android**, **iOS**.

For each: assert (a) lands on correct screen, (b) screen renders from cache before network,
(c) network calls during open ≤ budget (verify via Dio interceptor log), (d) Discover/home APIs
do **not** fire until Home is tapped.

---

## 8. Rollout order

1. **Phase 1** — payload contract + `PendingDeepLink` + router (no behavior change; safety net).
2. **Phase 2** — lazy home + `deferHeavyInit` (biggest smoothness win).
3. **Phase 3** — defer `_initDeferred` background batch on deep-link.
4. **Phase 4** — cache-first chat/post/ride open.
5. **Phase 5** — de-dup guard + budget verification.
6. **Phase 6** — full test matrix.

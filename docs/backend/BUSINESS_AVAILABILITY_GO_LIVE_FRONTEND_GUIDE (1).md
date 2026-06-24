# Business Availability & Go-Live — Flutter Integration Guide

New backend (be_user_service) feature: businesses set a **weekly day-by-day
opening/closing schedule** (with fully-closed days), and must **go live** at
their open time. If a business does not go live within **5 minutes** of its
scheduled open time, the backend pushes a **`business_go_live_reminder`** push
notification to the owner.

This guide maps the integration onto the **current** BlueEra Flutter patterns
(GetX, Dio, `user_service_api.dart` mixin, existing `AvailabilityData` model,
`app_notification.dart` operation switch). Nothing here breaks existing flows.

---

## 0. Backward compatibility (read first)

- The new endpoints write the **same `Availability` document** the business
  profile already returns under `availability`. Your existing
  `AvailabilityData.fromJson` keeps working — new fields are additive and
  unknown keys are ignored by `fromJson`.
- The backend now mirrors each open day's `shopOpenTime`/`shopCloseTime` into a
  `timeSlots` entry. So your **existing** `BusinessAvailabilityWidget`
  (`lib/features/business/widgets/business_availability_widget.dart`) and the
  `Schedule.timeSlots` model **render correctly with no change**.
- You only need frontend work to (a) let a business *edit* the new schedule with
  explicit open/close times, (b) add a **Go Live** button, and (c) handle the
  new reminder notification operation.

New fields now present on the availability response:

```jsonc
{
  "schedule": [
    {
      "day": "Monday",
      "isOpen": true,
      "shopOpenTime": "09:00",   // NEW (string HH:MM)
      "shopCloseTime": "21:00",  // NEW (string HH:MM)
      "timeSlots": [ { "startTime": "09:00", "endTime": "21:00" } ] // auto-mirrored
    },
    { "day": "Sunday", "isOpen": false, "timeSlots": [] }
  ],
  "liveState": {                 // NEW
    "isLive": false,
    "wentLiveAt": null,
    "liveDate": "2026-06-24",
    "reminderSentForDate": "2026-06-24"
  }
}
```

---

## 1. Add endpoints

File: `lib/core/api/apiService/user_service_api.dart` (the `UserServiceApi` mixin,
near the existing business endpoints around lines 58–73).

```dart
// Business availability / go-live
String get businessAvailabilityHours => '/user-service/business/availability/hours';
String get businessAvailabilityToday => '/user-service/business/availability/today';
String get businessGoLive          => '/user-service/business/availability/go-live';
String get businessEndLive         => '/user-service/business/availability/end-live';
```

> Match the `/user-service/...` prefix exactly like the existing
> `updateBusinessProfile = '/user-service/business/updateBusinessProfile'`.
> Auth bearer token is injected automatically by the Dio interceptor in
> `api_base_helper.dart:144-150` — no manual header needed.

---

## 2. Models

Your existing `Schedule` (in
`lib/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart`)
only has `day`, `isOpen`, `timeSlots`. Add the two new time fields and a
`liveState`. Backward-safe — old JSON without them just yields null.

```dart
// availability_model.dart -> class Schedule
class Schedule {
  String? day;
  bool? isOpen;
  String? shopOpenTime;   // NEW "HH:MM"
  String? shopCloseTime;  // NEW "HH:MM"
  List<TimeSlots>? timeSlots;

  Schedule({this.day, this.isOpen, this.shopOpenTime, this.shopCloseTime, this.timeSlots});

  Schedule.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    isOpen = json['isOpen'];
    shopOpenTime = json['shopOpenTime'];
    shopCloseTime = json['shopCloseTime'];
    if (json['timeSlots'] != null) {
      timeSlots = (json['timeSlots'] as List)
          .map((e) => TimeSlots.fromJson(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'isOpen': isOpen,
        if (isOpen == true) 'shopOpenTime': shopOpenTime,
        if (isOpen == true) 'shopCloseTime': shopCloseTime,
      };
}
```

New `LiveState` model + add it onto `AvailabilityData`:

```dart
class LiveState {
  bool? isLive;
  String? wentLiveAt;        // ISO date-time
  String? liveDate;          // "YYYY-MM-DD"
  String? reminderSentForDate;

  LiveState({this.isLive, this.wentLiveAt, this.liveDate, this.reminderSentForDate});

  factory LiveState.fromJson(Map<String, dynamic> j) => LiveState(
        isLive: j['isLive'] ?? false,
        wentLiveAt: j['wentLiveAt'],
        liveDate: j['liveDate'],
        reminderSentForDate: j['reminderSentForDate'],
      );
}

// In AvailabilityData.fromJson, add:
//   liveState = json['liveState'] != null ? LiveState.fromJson(json['liveState']) : null;
```

Your existing `SpecialOverrides` model already maps `date`, `isOpen`,
`timeSlots`. Add `dateKey`, `shopOpenTime`, `shopCloseTime` (all nullable) so a
day-override round-trips fully — additive, old JSON still parses:

```dart
// SpecialOverrides.fromJson — add:
dateKey = json['dateKey'];
shopOpenTime = json['shopOpenTime'];
shopCloseTime = json['shopCloseTime'];
```

`todayEffective` (top-level on the `GET /hours` response, **not** inside `data`)
is a small flat object — read it as a plain `Map` in the controller (§4); no
model class needed.

---

## 3. Repo methods

Extend `BusinessProfileRepo`
(`lib/features/business/auth/repo/business_profile_repo.dart`) — same pattern as
the existing `updateBusinessProfileDetails`.

```dart
Future<ResponseModel> setBusinessHours(Map<String, dynamic> params) async {
  return ApiBaseHelper().putHTTP(
    businessAvailabilityHours,
    params: params,
    isMultipart: false,          // JSON, not multipart
    showProgress: true,
    onError: (e) {},
    onSuccess: (d) {},
  );
}

Future<ResponseModel> getBusinessHours() async {
  return ApiBaseHelper().getHTTP(
    businessAvailabilityHours,
    showProgress: false,
    onError: (e) {},
    onSuccess: (d) {},
  );
}

// Today-only override (beats weekly for today, auto-reverts tomorrow)
Future<ResponseModel> setTodayHours(Map<String, dynamic> params) async {
  return ApiBaseHelper().putHTTP(
    businessAvailabilityToday,
    params: params,
    isMultipart: false,
    showProgress: true,
    onError: (e) {},
    onSuccess: (d) {},
  );
}

Future<ResponseModel> clearTodayHours() async {
  return ApiBaseHelper().deleteHTTP(   // use your existing delete helper
    businessAvailabilityToday,
    showProgress: true,
    onError: (e) {},
    onSuccess: (d) {},
  );
}

Future<ResponseModel> goLive() async {
  return ApiBaseHelper().postHTTP(
    businessGoLive,
    params: {},
    showProgress: true,
    onError: (e) {},
    onSuccess: (d) {},
  );
}

Future<ResponseModel> endLive() async {
  return ApiBaseHelper().postHTTP(
    businessEndLive,
    params: {},
    showProgress: true,
    onError: (e) {},
    onSuccess: (d) {},
  );
}
```

### `PUT /hours` request body

```jsonc
{
  "timezone": "Asia/Kolkata",          // optional, defaults Asia/Kolkata
  "bookingType": "Offline",            // optional: Online | Offline | Both
  "durationInMinutes": 60,             // optional
  "instructions": "Ring the bell",     // optional
  "schedule": [
    { "day": "Monday",    "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
    { "day": "Tuesday",   "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
    { "day": "Wednesday", "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
    { "day": "Thursday",  "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
    { "day": "Friday",    "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
    { "day": "Saturday",  "isOpen": true,  "shopOpenTime": "10:00", "shopCloseTime": "18:00" },
    { "day": "Sunday",    "isOpen": false }
  ]
}
```

Rules enforced by backend (handle these in the UI/validation):
- `day` must be one of `Sunday..Saturday` (full names, capitalized).
- `isOpen: false` ⇒ fully closed; open/close times ignored — don't require them.
- `isOpen: true` ⇒ `shopOpenTime` **and** `shopCloseTime` required, format `HH:MM`
  (24-hour, zero-padded). Missing/invalid ⇒ **400**.
- Days omitted from the array are stored as closed.
- Invalid `timezone` ⇒ **400**. Empty body ⇒ **400** (`Nothing to update`).
- `403` if a non-franchise user tries to manage another business; `404` if no
  business for the caller.

Send the whole 7-day array each save (it replaces the stored schedule).

### `PUT /today` — override TODAY only (auto-reverts tomorrow)

Lets a business change just today's hours without touching the weekly schedule.
The override is keyed to today's date in the business timezone, so it **stops
applying automatically tomorrow** — the weekly hours for that weekday come back
with no extra call. (`DELETE /today` reverts immediately, same day.)

Request body:
```jsonc
// Open late just for today
{ "isOpen": true, "shopOpenTime": "11:00", "shopCloseTime": "23:00" }

// Closed today (e.g. holiday / emergency)
{ "isOpen": false }
```
Rules: `isOpen:true` ⇒ `shopOpenTime` + `shopCloseTime` (HH:MM) required else
**400**; `404` if weekly hours not set yet. `timeSlots` auto-mirrored.

Response `data`: `{ date, override, specialOverrides }`.

> **Effective hours = override-if-today, else weekly.** The go-live reminder
> worker honors the override too: change today to closed ⇒ no reminder; open
> late ⇒ reminder fires 5 min after the *new* open time.

### Reading what's in effect today — `GET /hours`

`GET /hours` now also returns a `todayEffective` block so the UI can show the
*actual* hours for today without re-implementing the override logic:

```jsonc
{
  "status": true,
  "data": { /* full Availability incl. schedule[], specialOverrides[], liveState */ },
  "todayEffective": {
    "date": "2026-06-24",
    "day": "Wednesday",
    "isOpen": true,
    "shopOpenTime": "11:00",
    "shopCloseTime": "23:00",
    "source": "override"   // "override" = today was explicitly changed; else "weekly"
  }
}
```
Use `source == 'override'` to show a "Today's hours changed — revert?" affordance
(calls `DELETE /today`).

---

## 4. Controller (GetX)

Add to `ViewBusinessDetailsController`
(`lib/features/business/auth/controller/view_business_details_controller.dart`),
beside the existing `shopOpenTime` / `shopCloseTime` observables.

```dart
final RxBool isLive = false.obs;
final RxList<Schedule> weeklySchedule = <Schedule>[].obs;

Future<void> saveBusinessHours() async {
  final body = {
    'timezone': 'Asia/Kolkata',
    'schedule': weeklySchedule.map((s) => s.toJson()).toList(),
  };
  final res = await repo.setBusinessHours(body);
  if (res.isSuccess) {
    final data = res.response?.data['data'];
    final avail = AvailabilityData.fromJson(data);
    weeklySchedule.value = avail.schedule ?? [];
    isLive.value = avail.liveState?.isLive ?? false;
  }
}

Future<void> goLiveNow() async {
  final res = await repo.goLive();
  if (res.isSuccess) {
    isLive.value = res.response?.data['data']?['isLive'] ?? true;
    // success toast: "You are now live"
  }
}

Future<void> endLiveNow() async {
  final res = await repo.endLive();
  if (res.isSuccess) isLive.value = false;
}

// ---- Today override ----
final RxMap<String, dynamic> todayEffective = <String, dynamic>{}.obs;

Future<void> loadHours() async {
  final res = await repo.getBusinessHours();
  if (res.isSuccess) {
    final body = res.response?.data;
    final avail = AvailabilityData.fromJson(body['data']);
    weeklySchedule.value = avail.schedule ?? [];
    isLive.value = avail.liveState?.isLive ?? false;
    todayEffective.value = (body['todayEffective'] as Map?)?.cast<String, dynamic>() ?? {};
  }
}

Future<void> setTodayHours({
  required bool isOpen,
  String? open,
  String? close,
}) async {
  final body = {
    'isOpen': isOpen,
    if (isOpen) 'shopOpenTime': open,
    if (isOpen) 'shopCloseTime': close,
  };
  final res = await repo.setTodayHours(body);
  if (res.isSuccess) await loadHours(); // refresh todayEffective
}

Future<void> revertTodayHours() async {
  final res = await repo.clearTodayHours();
  if (res.isSuccess) await loadHours();
}
```

`isLive` initial value: hydrate from the business profile response you already
fetch — `availability.liveState.isLive` **and** confirm
`liveState.liveDate == today` (the flag is per-day).

Whether today is overridden: `todayEffective['source'] == 'override'`.

---

## 5. UI

### 5a. Edit hours screen
Build a 7-row editor (one per day): a day label, an `isOpen` toggle, and two
time pickers (open / close) enabled only when `isOpen`. On save call
`saveBusinessHours()`. Use `showTimePicker` and format to `HH:MM` 24-hour.

### 5b. Display
No change required — the existing `BusinessAvailabilityWidget` keeps rendering
because the backend mirrors open/close into `timeSlots`. Optionally switch it to
read `shopOpenTime`/`shopCloseTime` directly for cleaner labels. To show what's
really in effect now, prefer `controller.todayEffective` over the raw weekly row.

### 5c. "Change today's hours" (override)
On the dashboard, add a quick action (e.g. a "Today" chip / bottom-sheet):
- Two time pickers + an "Open / Closed today" toggle → `setTodayHours(...)`.
- When `todayEffective['source'] == 'override'`, show a banner
  *"Today's hours changed → 11:00–23:00 · Revert"* whose Revert button calls
  `revertTodayHours()` (`DELETE /today`).
- No client timer needed for reset — the override expires server-side at
  midnight (business timezone); on next `loadHours()` `source` is back to
  `weekly`.

### 5c. Go Live button
On the business dashboard/profile, show a button driven by `isLive`:

```dart
Obx(() => ElevatedButton(
  onPressed: controller.isLive.value
      ? controller.endLiveNow
      : controller.goLiveNow,
  child: Text(controller.isLive.value ? 'End Live' : 'Go Live'),
));
```

---

## 6. Reminder notification handling

When a business is overdue, backend sends this FCM payload:

```jsonc
{
  "operation": "business_go_live_reminder",
  "data": {
    "title": "You're not live yet",
    "body": "Your shop was scheduled to open at 09:00. Tap to go live so customers can find you.",
    "business_id": "<id>",
    "open_time": "09:00",
    "cta": "go_live"
  }
}
```

The notification also carries an action button id **`go_live`** ("Go Live")
already registered server-side (`_parseNotificationActions()`,
`app_notification.dart:1798-1816` — turns the payload `actions` into Android
action buttons; no change needed there).

### Deep-link target

The Go-Live button lives on the **business own profile** screen (§5c). Route it
there. Real, existing route constants (verified in
`lib/core/routes/route_constant.dart`):

| Constant | Value | Screen |
|----------|-------|--------|
| `RouteConstant.BusinessOwnProfileScreen` | `/BusinessOwnProfileScreen` | `BusinessOwnProfileScreen` (hosts Go-Live button) |
| `RouteConstant.setAvailabilityScreen` (`RouteHelper.getAvailabilityScreenRoute()`) | `/SetAvailabilityScreen` | `SetAvailabilityScreen` (edit hours) |

Both are registered in `route_helper.dart`'s `onGenerateRoute`
(`BusinessOwnProfileScreen` at line 861), so `Get.toNamed(...)` works from a
cold start. Use `BusinessOwnProfileScreen` as the deep-link target; pass an
argument to auto-open the live action.

There are **two tap surfaces** — handle both:

### 6a. Body tap → operation switch

In `app_notification.dart`, inside `_onTapNotificationFromStatusBar()` (the
`switch (operation)` around lines 2162–2384), add a case next to
`profile_completion_reminder`:

```dart
case 'business_go_live_reminder':
  // Deep-link to the business own profile (hosts the Go Live button).
  Get.toNamed(
    RouteConstant.BusinessOwnProfileScreen,
    arguments: {
      'business_id': data['business_id'],
      'open_go_live': true,   // screen reads this to auto-prompt go-live
    },
  );
  break;
```

### 6b. Action-button (`go_live`) tap

Action-button taps are routed by **`_handleActionButtonTap(actionId, data)`**
(`app_notification.dart:1230`). `onForegroundNotificationResponse`
(`app_notification.dart:68-145`) and the background handler both delegate any
non-call/non-fare `actionId` into it — so adding the case there covers
**foreground, background, and killed-state** taps in one place.

Add an early branch in `_handleActionButtonTap`, before the generic fall-through:

```dart
if (actionId == 'go_live') {
  Get.toNamed(
    RouteConstant.BusinessOwnProfileScreen,
    arguments: {
      'business_id': data['business_id'],
      'open_go_live': true,
    },
  );
  return;
}
```

### 6c. Consume the deep-link argument on the screen

In `BusinessOwnProfileScreen` (or its controller `initState`/`onInit`), read the
argument and auto-trigger the live flow:

```dart
final args = Get.arguments as Map?;
if (args?['open_go_live'] == true) {
  // optionally scroll to / highlight the Go Live button, or call directly:
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.goLiveNow(); // from §4
  });
}
```

### 6d. Cold-start (app killed) note

Killed-state taps replay through the **same** handlers: the initial
notification/message is fetched on launch (`getInitialMsg` /
`getInitialMessage`) and dispatched into `_onTapNotificationFromStatusBar`
(body) or `_handleActionButtonTap` (action). The 6a/6b additions therefore work
on cold start too — no extra wiring. Just ensure the target screen tolerates
being opened directly (auth/business context loaded before reading `Get.arguments`).

---

## 7. Test checklist

1. `PUT /hours` with a full 7-day array incl. one `isOpen:false` → 200, response
   `schedule` has `timeSlots` mirrored on open days.
2. Old business-profile screen still renders hours (backward compat).
3. `POST /go-live` → `isLive:true`, button flips to "End Live".
4. Set today's `shopOpenTime` to ~6 min in the past, don't go live → within a
   minute receive `business_go_live_reminder` push. Body tap → opens
   `BusinessOwnProfileScreen` with `open_go_live:true`; the `Go Live` action
   button works in foreground, background, and killed states.
5. Go live, then wait → **no** reminder (deduped via `reminderSentForDate`).
6. `isOpen:false` day → never reminded.
7. `PUT /today` `{isOpen:true, shopOpenTime, shopCloseTime}` → `GET /hours`
   `todayEffective.source == 'override'` with the new times; weekly row unchanged.
8. `PUT /today` `{isOpen:false}` on an otherwise-open day → no go-live reminder
   today.
9. Override today's open time to ~6 min ago, don't go live → reminder fires at
   the **overridden** time, not the weekly time.
10. `DELETE /today` → `todayEffective.source` back to `weekly` immediately.
11. Set an override, simulate next day → override no longer applies (auto-revert),
    no client action needed.

---

## 8. Endpoint summary

| Method | Path | Body | Purpose |
|--------|------|------|---------|
| PUT    | `/user-service/business/availability/hours` | schedule[] (+opts) | Set weekly hours / closed days |
| GET    | `/user-service/business/availability/hours` | — | Read schedule + `todayEffective` + liveState |
| PUT    | `/user-service/business/availability/today` | `{isOpen, shopOpenTime?, shopCloseTime?}` | Override today only (auto-reverts tomorrow) |
| DELETE | `/user-service/business/availability/today` | — | Clear today's override now (revert to weekly) |
| POST   | `/user-service/business/availability/go-live` | `{}` | Mark live for today |
| POST   | `/user-service/business/availability/end-live` | `{}` | Mark offline |

All require the bearer token (auto-injected). Reminder is push-only; no polling
needed on the client.

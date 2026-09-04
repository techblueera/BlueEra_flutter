# GA4 (Google Analytics for Firebase) — Flutter Integration Guide

How to wire **Google Analytics 4** into the BlueEra Flutter app so the events you
saw in the Firebase console (`analytics.google.com` → Events) actually start
receiving data.

> **Why the console was empty ("No stream data detected"):** GA4 shows Google's
> *recommended* events (`purchase`, `add_to_cart`, `first_open`…) by default, but
> no data flows until the app includes the **`firebase_analytics`** SDK and logs
> events. This guide adds exactly that.
>
> **This is NOT push notifications.** GA4 (Analytics) measures user behaviour.
> FCM (Messaging) sends notifications. They are separate Firebase products — see
> `be_notification_service/docs/FIREBASE_EVENTS_FRONTEND_REFERENCE.md` for the
> notification side. Nothing here touches notifications.

---

## 0. What's already done ✅ (no action needed)

Your project is already GA4-ready except for the SDK:

| Requirement | Status |    
|---|---|
| `firebase_core` in `pubspec.yaml` | ✅ `^4.1.0` |
| `google-services.json` (Android) | ✅ `android/app/google-services.json` |
| `GoogleService-Info.plist` (iOS) | ✅ `ios/Runner/GoogleService-Info.plist` |
| `com.google.gms.google-services` gradle plugin | ✅ applied in `android/app/build.gradle` + `settings.gradle` |
| `minSdkVersion` ≥ 21 | ✅ `26` |
| iOS deployment target ≥ 12 | ✅ `15.6` |
| `Firebase.initializeApp()` before `runApp` | ✅ in `lib/core/services/firebase_crshanalitics_service.dart` |
| GA4 property linked | ✅ `blueera-50c05` (that's the console you opened) |
| **`firebase_analytics` package** | ❌ **missing — this guide adds it** |

So it's ~30 minutes of Dart work. No native/gradle changes required.

---

## 1. Add the dependency

```bash
cd BlueEra_flutter
flutter pub add firebase_analytics
```

Let pub resolve the version — it must be the line compatible with
`firebase_core ^4.1.0` (that's `firebase_analytics ^12.x` at time of writing).
Do **not** pin an older major or it will conflict with your `firebase_core`.

```yaml
# pubspec.yaml (result)
dependencies:
  firebase_core: ^4.1.0
  firebase_analytics: ^12.0.0   # whatever `flutter pub add` resolved
```

Then:

```bash
flutter pub get
cd ios && pod install && cd ..   # iOS only
```

No changes to `google-services.json`, `build.gradle`, or `Info.plist` are needed.

---

## 2. Create a single AnalyticsService

Mirror the existing `firebase_crshanalitics_service.dart` pattern — one seam the
whole app calls, so you never scatter `FirebaseAnalytics.instance` everywhere.

Create **`lib/core/services/analytics_service.dart`**:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Single entry point for all GA4 analytics. Import this, not FirebaseAnalytics.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService I = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// Route observer — add to GetMaterialApp.navigatorObservers (see step 4).
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _fa);

  /// Call once after Firebase.initializeApp(). Enables collection.
  Future<void> init() async {
    // Turn OFF in debug if you don't want dev traffic in reports (optional).
    await _fa.setAnalyticsCollectionEnabled(true);
  }

  /// GA4 event names: <=40 chars, letters/digits/underscore, must start with a
  /// letter, no reserved prefixes (firebase_/google_/ga_). Params: <=25 per
  /// event, values must be String or num.
  Future<void> log(String name, [Map<String, Object>? params]) async {
    try {
      await _fa.logEvent(name: name, parameters: params);
    } catch (e) {
      if (kDebugMode) debugPrint('[GA4] logEvent "$name" failed: $e');
    }
  }

  /// Tie events to a user (call on login; clear on logout with setUserId(null)).
  Future<void> setUser(String? userId, {String? accountType, String? profileType}) async {
    try {
      await _fa.setUserId(id: userId);
      if (accountType != null) {
        await _fa.setUserProperty(name: 'account_type', value: accountType);
      }
      if (profileType != null) {
        await _fa.setUserProperty(name: 'profile_type', value: profileType);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[GA4] setUser failed: $e');
    }
  }

  /// Manual screen view — use for GetX tab switches / bottom-nav where the
  /// route observer doesn't fire (see step 4).
  Future<void> screen(String screenName) async {
    try {
      await _fa.logScreenView(screenName: screenName);
    } catch (e) {
      if (kDebugMode) debugPrint('[GA4] screen "$screenName" failed: $e');
    }
  }

  // ---- Recommended (standard GA4) events — better than custom names ----
  Future<void> logLogin(String method) => _safe(() => _fa.logLogin(loginMethod: method));
  Future<void> logSignUp(String method) => _safe(() => _fa.logSignUp(signUpMethod: method));

  Future<void> _safe(Future<void> Function() f) async {
    try { await f(); } catch (e) { if (kDebugMode) debugPrint('[GA4] $e'); }
  }
}
```

---

## 3. Initialize it (once, before `runApp`)

In `lib/main.dart`, right after Firebase is initialized (next to the Crashlytics
init), call `AnalyticsService.I.init()`:

```dart
import 'package:BlueEra/core/services/analytics_service.dart';

// ... inside main(), after firebaseInitializeApp() / firebaseCrashServiceInit():
await AnalyticsService.I.init();
```

`first_open`, `session_start`, `app_update`, `os_update`, `screen_view` and other
**auto-collected events fire automatically** once the SDK is present — you don't
log those yourself.

---

## 4. Automatic screen tracking (GetX)

Add the observer to your `GetMaterialApp` (in `lib/main.dart`, alongside the
existing `RouteHelper.routeObserver`):

```dart
GetMaterialApp(
  // ...
  navigatorObservers: [
    RouteHelper.routeObserver,
    AnalyticsService.I.observer,   // ← logs screen_view on named-route pushes
  ],
  // ...
)
```

⚠️ **GetX caveat:** the observer only fires for **named routes** (routes with a
`RouteSettings.name`). Your app uses `onGenerateRoute: RouteHelper.generateRoute`,
so most pushes are named and will be tracked. But **bottom-nav tab switches**
(Home ↔ Me ↔ Connect…) don't push a route, so log those manually:

```dart
// e.g. in BottomBarController.onChangeIndex(int i):
AnalyticsService.I.screen(['home', 'connect', 'post', 'jobs', 'me'][i]);
```

---

## 5. Identify the user (on login / logout)

Tie behaviour to accounts and segment by your `account_type` / `profileType`
(the same fields the go-live reminder uses). Call this where you set the auth
token after login:

```dart
// after successful login (auth_controller):
await AnalyticsService.I.setUser(
  user.id,
  accountType: user.accountType,   // INDIVIDUAL / BUSINESS / GUEST
  profileType: user.profileType,   // GIG_WORKER / SELF_EMPLOYED / ...
);
await AnalyticsService.I.logLogin('otp'); // or 'password' / 'google'

// on logout:
await AnalyticsService.I.setUser(null);
```

> Do **not** put personal data (email, phone, name) in userId or user properties
> — GA4 forbids PII. Use the opaque user id only.

---

## 6. Log events

### Prefer Google's *recommended* names where one fits
GA4 gives these special reports (funnels, monetization). Use them over custom names:

| User action | Call |
|---|---|
| Login | `AnalyticsService.I.logLogin('otp')` |
| Sign up | `AnalyticsService.I.logSignUp('otp')` |
| View a screen manually | `AnalyticsService.I.screen('post_detail')` |
| Search | `log('search', {'search_term': query})` |
| Select content | `log('select_content', {'content_type': 'reel', 'item_id': reelId})` |
| Share | `log('share', {'content_type': 'post', 'item_id': postId})` |
| Begin checkout / subscribe | `log('begin_checkout', {'value': 199, 'currency': 'INR'})` |
| Purchase / subscription paid | `log('purchase', {'value': 199, 'currency': 'INR', 'transaction_id': txnId})` |

### Custom events for BlueEra-specific actions
Use clear `snake_case` names:

```dart
AnalyticsService.I.log('go_live', {'profile_type': 'GIG_WORKER'});
AnalyticsService.I.log('go_offline');
AnalyticsService.I.log('ride_requested', {'order_id': orderId});
AnalyticsService.I.log('ride_accepted', {'order_id': orderId});
AnalyticsService.I.log('job_applied', {'job_id': jobId});
AnalyticsService.I.log('post_created', {'post_type': 'reel'});
AnalyticsService.I.log('profile_completed', {'percent': 100});
AnalyticsService.I.log('notification_opened', {'operation': op}); // ties FCM taps to GA4
```

**Naming rules (or the event is silently dropped):**
- name ≤ 40 chars, `snake_case`, starts with a letter, no `firebase_`/`google_`/`ga_` prefix;
- ≤ 25 parameters per event; parameter values must be **String or num** (no bool/Map/List — send `1`/`0` or `'true'`);
- ≤ 500 distinct event names per app.

---

## 7. Test it (DebugView — see events in real time)

Events normally take **up to 24h** to appear in *Events*, but **DebugView is instant.**

**Android** (device/emulator connected) — your `applicationId` is `ai.bluecs.app`:
```bash
adb shell setprop debug.firebase.analytics.app ai.bluecs.app
# stop debug later: adb shell setprop debug.firebase.analytics.app .none.
```

**iOS:** in Xcode → Product → Scheme → Edit Scheme → Run → Arguments, add:
```
-FIRDebugEnabled
```

Then run the app and open **Firebase Console → Analytics → DebugView**. Tap
around; you should see `first_open`, `screen_view`, `login`, and your custom
events stream in live.

---

## 8. Verify in the GA4 console

1. **DebugView** — immediate, during testing (step 7).
2. **Realtime** (Analytics → Realtime) — active users + events, ~30 min window.
3. **Events** (the screen you opened) — populates within **24 hours**; "No stream
   data detected" disappears once real traffic arrives.
4. **Mark key events** — on the Events screen, star the events that matter
   (`purchase`, `go_live`, `job_applied`…) to make them conversions.

---

## 9. Privacy / Play Store & App Store notes

- Declare analytics data collection in your **Play Data Safety** form and **App
  Store privacy** labels (analytics/identifiers).
- If you add a consent screen later, gate collection with
  `setAnalyticsCollectionEnabled(false)` until the user consents, and set
  consent via `setConsent(...)`.
- Never log PII (email, phone, name, exact address) as event params or user
  properties — it violates GA4 terms and can get data deleted.

---

## 10. Compatibility & gotchas

| Item | Note |
|---|---|
| `firebase_analytics` version | Use the one `flutter pub add` resolves for `firebase_core ^4.1.0` (~`^12.x`). Mismatched majors → build/runtime errors. |
| Manual `FirebaseOptions` init | Your app builds `FirebaseOptions` from `environment_config.dart`. That's fine — on device, GA4 auto-collection is driven by the native `google-services.json` / `GoogleService-Info.plist`, which are present. |
| iOS `pod install` | Required after adding the package. |
| Debug traffic | If you don't want dev devices in reports, call `setAnalyticsCollectionEnabled(!kDebugMode)` in `AnalyticsService.init()`. |
| bool params | GA4 rejects bool — send `1`/`0` or `'yes'`/`'no'`. |
| GetX tab switches | Not auto-tracked — call `AnalyticsService.I.screen(...)` manually (step 4). |
| Don't confuse with FCM | This is Analytics. Notifications are Firebase Messaging (separate). |

---

## Summary — the minimal checklist

- [ ] `flutter pub add firebase_analytics` (+ `pod install` on iOS)
- [ ] Add `lib/core/services/analytics_service.dart` (step 2)
- [ ] `await AnalyticsService.I.init()` after Firebase init in `main.dart`
- [ ] Add `AnalyticsService.I.observer` to `GetMaterialApp.navigatorObservers`
- [ ] `AnalyticsService.I.setUser(...)` on login, `setUser(null)` on logout
- [ ] Log a few custom events (`go_live`, `ride_requested`, `job_applied`…)
- [ ] Verify in **DebugView**, then confirm **Events** fills within 24h

No backend changes. No native config changes. Purely a Flutter/app addition.

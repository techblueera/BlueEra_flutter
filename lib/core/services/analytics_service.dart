import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Single entry point for GA4 (Google Analytics for Firebase).
///
/// Import THIS, never `FirebaseAnalytics.instance` directly — one seam keeps
/// the SDK swappable and means every call already carries the swallow-and-log
/// error handling below. Analytics must never surface an error to the user or
/// break a flow it is only observing, so every method is failure-tolerant.
///
/// Mirrors the `firebase_crshanalitics_service.dart` pattern: initialised once
/// from `main()` after `firebaseInitializeApp()`.
///
/// **Verifying events.** There is deliberately no per-event console logging —
/// it drowned the log in `[GA4]` lines during ordinary use. Use DebugView,
/// which shows the events as Google actually received them rather than as the
/// app believes it sent them:
///
/// ```
/// adb shell setprop debug.firebase.analytics.app ai.bluecs.app   # then RESTART the app
/// adb shell setprop debug.firebase.analytics.app .none.          # off
/// ```
///
/// GA4 drops a malformed event SILENTLY, so mind the naming rules on [log].
///
/// See docs/backend/GA4_ANALYTICS_INTEGRATION_GUIDE.md and
/// docs/backend/GA4_CUSTOM_DIMENSIONS.txt.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService I = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// Navigator observer wired into `GetMaterialApp.navigatorObservers` — logs
  /// `screen_view` on every NAMED route push/pop. Bottom-nav tab switches do
  /// not push a route, so those call [screen] manually (see BottomBarController).
  ///
  /// Built ONCE and cached: `navigatorObservers` is re-read on every rebuild
  /// of GetMaterialApp, and handing Navigator a fresh observer each time makes
  /// it detach/reattach the old one (dropping route state it tracks).
  late final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _fa);

  /// Call once after `Firebase.initializeApp()`. Fire-and-forget from main —
  /// auto-collected events (`first_open`, `session_start`, `screen_view`…)
  /// start flowing on their own once the SDK is present.
  Future<void> init() async {
    await _safe(() => _fa.setAnalyticsCollectionEnabled(true));
  }

  /// GA4 event-name rules (violations are silently DROPPED server-side):
  /// <=40 chars, snake_case, starts with a letter, no `firebase_`/`google_`/
  /// `ga_` prefix; <=25 params; param values must be String or num — never
  /// bool/Map/List. Use [params] to build a clean map.
  Future<void> log(String name, [Map<String, Object>? params]) async {
    await _safe(() => _fa.logEvent(name: name, parameters: params));
  }

  /// Ties events to an account. GA4 forbids PII, so this takes the opaque ids
  /// only — never name / phone / email. Pass a null [userId] on logout.
  Future<void> setUser(
    String? userId, {
    String? accountType,
    String? profileType,
  }) async {
    await _safe(() async {
      // Empty string is not a valid GA4 user id — treat it as "signed out".
      final id = (userId?.trim().isEmpty ?? true) ? null : userId!.trim();
      await _fa.setUserId(id: id);
      await _fa.setUserProperty(
          name: 'account_type', value: _emptyToNull(accountType));
      await _fa.setUserProperty(
          name: 'profile_type', value: _emptyToNull(profileType));
    });
  }

  /// Manual screen view — for GetX tab switches and any screen the route
  /// observer cannot see (no `RouteSettings.name`).
  Future<void> screen(String screenName) async {
    await _safe(() => _fa.logScreenView(screenName: screenName));
  }

  // ---- Recommended (standard GA4) events — these get first-class reports ----

  Future<void> logLogin(String method) =>
      _safe(() => _fa.logLogin(loginMethod: method));

  Future<void> logSignUp(String method) =>
      _safe(() => _fa.logSignUp(signUpMethod: method));

  Future<void> logSearch(String term) =>
      _safe(() => _fa.logSearch(searchTerm: term));

  /// Drops null/empty entries and coerces bool → 1/0, because GA4 rejects
  /// bool params and a null value throws on the platform channel.
  static Map<String, Object> params(Map<String, Object?> raw) {
    final out = <String, Object>{};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        out[key] = value ? 1 : 0;
      } else if (value is num) {
        out[key] = value;
      } else {
        final s = value.toString().trim();
        if (s.isNotEmpty) out[key] = s;
      }
    });
    return out;
  }

  static String? _emptyToNull(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Swallows everything — analytics is an observer and must never take a
  /// flow down with it.
  ///
  /// A FAILURE still prints, in debug builds only. This is the one line kept
  /// out of the per-event logging that used to live here: it never fires in
  /// normal operation, so it adds no noise, and without it a broken analytics
  /// subsystem would be completely invisible from the app side.
  Future<void> _safe(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (kDebugMode) debugPrint('[GA4] $e');
    }
  }
}

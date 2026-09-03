import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// One-time Mobile Ads SDK start-up, deliberately kept OFF the critical path.
///
/// ## Why this exists
///
/// Nothing used to bring the SDK up at launch — `MobileAds.instance.initialize()`
/// lived only inside [AdMobInterstitialManager.initialize], which runs when a
/// call ends. So on a normal session the FIRST native ad slot to be built paid
/// for the whole ad stack coming up: Play Services resolving and loading the
/// `com.google.android.gms.ads.dynamite` module, then binding its service. That
/// work lands on the platform's main thread, and the first native slot is built
/// while a screen is pushing — which is exactly when the main thread is busiest.
/// The visible result was a push that stalled for about a second, with
/// `Choreographer: Skipped N frames` right after the ad request in logcat.
///
/// Warming up once, after the first frame, moves that cost to a moment when the
/// user is already looking at a painted screen and nothing is animating.
///
/// Idempotent and safe to call from anywhere: the first caller starts the work,
/// everyone else awaits the same future.
class AdsBootstrap {
  AdsBootstrap._();

  static Future<void>? _pending;

  /// Brings the SDK up, or returns the in-flight / completed start-up.
  ///
  /// Never throws — an ad stack that fails to start must not take a screen down
  /// with it. On failure the future is cleared so a later slot can retry rather
  /// than being stuck behind one bad attempt.
  static Future<void> ensureInitialized() {
    if (!AdConfig.adsEnabled) return Future<void>.value();
    return _pending ??= MobileAds.instance.initialize().then<void>((_) {}).catchError(
      (Object e) {
        _pending = null;
        logs('[ADMOB] SDK init failed: $e');
      },
    );
  }
}

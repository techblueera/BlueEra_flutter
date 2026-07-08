import 'package:BlueEra/core/services/ads/admob_interstitial_manager.dart';

/// Interstitial ads are served by **Google AdMob** (primary), with Meta
/// Audience Network mediated behind it in the AdMob dashboard.
///
/// This class is kept as a thin forwarder to [AdMobInterstitialManager] so the
/// existing call sites (`call_controller`, `app_lifecycle_handler`, `main`)
/// that use `InterstitialAdManager.instance` need no changes.
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  /// Initialise the Mobile Ads SDK and preload the first interstitial.
  /// Idempotent.
  Future<void> initialize() => AdMobInterstitialManager.instance.initialize();

  /// Show the interstitial if one is ready (loading + waiting up to [maxWait]
  /// otherwise). Never throws.
  Future<void> showInterstitial(
          {Duration maxWait = const Duration(seconds: 5)}) =>
      AdMobInterstitialManager.instance.showInterstitial(maxWait: maxWait);
}

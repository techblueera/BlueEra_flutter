import 'package:BlueEra/core/services/ads/meta_interstitial_manager.dart';

/// Interstitial ads are served by **Meta (Facebook Audience Network)**.
///
/// This class is kept as a thin forwarder to [MetaInterstitialManager] so the
/// existing call sites (`call_controller`, `app_lifecycle_handler`, `main`)
/// that use `InterstitialAdManager.instance` need no changes.
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  /// Initialise the Meta SDK and preload the first interstitial. Idempotent.
  Future<void> initialize() => MetaInterstitialManager.instance.initialize();

  /// Show the interstitial if one is ready (loading + waiting up to [maxWait]
  /// otherwise). Never throws.
  Future<void> showInterstitial(
          {Duration maxWait = const Duration(seconds: 5)}) =>
      MetaInterstitialManager.instance.showInterstitial(maxWait: maxWait);
}

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
  /// otherwise). Never throws. Returns whether an ad actually showed.
  Future<bool> showInterstitial(
          {Duration maxWait = const Duration(seconds: 5)}) =>
      AdMobInterstitialManager.instance.showInterstitial(maxWait: maxWait);

  /// [showInterstitial], capped at once per app session for [key]. Used by the
  /// order/booking placements, which share one budget between them — see
  /// [AdMobInterstitialManager.showInterstitialOncePerSession].
  Future<bool> showInterstitialOncePerSession(
    String key, {
    Duration maxWait = const Duration(seconds: 5),
  }) =>
      AdMobInterstitialManager.instance
          .showInterstitialOncePerSession(key, maxWait: maxWait);

  /// Whether [key]'s one-per-session ad has already been shown — see
  /// [AdMobInterstitialManager.hasSpentSessionKey].
  bool hasSpentSessionKey(String key) =>
      AdMobInterstitialManager.instance.hasSpentSessionKey(key);
}

/// The symbol rail's "Sponsored" tile, capped at one ad per app session.
///
/// Its own budget, NOT shared with [kOrderBookingInterstitialKey]: that key
/// rations ads the app shows on its own initiative after an order or booking,
/// and spending it here would mean a viewer who tapped this tile silently gets
/// no ad after their next order — two unrelated placements cancelling each
/// other out. This one is user-initiated and is rationed for a different
/// reason: the tile is the only control in the app that summons an
/// interstitial, so without a cap it can be tapped all day.
const String kSymbolRailInterstitialKey = 'symbol_rail_tile';

/// The one session budget every order/booking completion shares. A customer who
/// finishes a ride AND places an order in the same session sees ONE ad, not two.
const String kOrderBookingInterstitialKey = 'order_or_booking_complete';

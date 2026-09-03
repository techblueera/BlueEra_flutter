import 'dart:async';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/core/services/ads/ads_bootstrap.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google AdMob interstitial manager (call-end interstitial).
///
/// AdMob handles its own reload cadence and backfill, so there's no hand-rolled
/// cooldown / session cap / rate-limit handling here.
///
/// The [InterstitialAdManager] forwarder delegates here with no call-site
/// changes.
class AdMobInterstitialManager {
  AdMobInterstitialManager._();

  static final AdMobInterstitialManager instance = AdMobInterstitialManager._();

  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _initialized = false;
  Completer<void>? _loadCompleter;

  bool get _isLoaded => _ad != null;

  /// Initialise the Mobile Ads SDK once and preload the first interstitial.
  /// Idempotent — safe to call from multiple entry points.
  Future<void> initialize() async {
    if (!AdConfig.adsEnabled) return;
    if (!_initialized) {
      _initialized = true;
      // Shared with the native slots and the launch warm-up — whoever gets
      // here first starts the SDK, the rest await the same future instead of
      // paying for a second start-up. See [AdsBootstrap].
      await AdsBootstrap.ensureInitialized();
    }
    _load();
  }

  void _load() {
    if (!AdConfig.adsEnabled || _isLoading || _isLoaded) return;
    _isLoading = true;
    _loadCompleter ??= Completer<void>();
    InterstitialAd.load(
      adUnitId: AdConfig.admobInterstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              _load(); // preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              logs('[ADMOB_INTERSTITIAL] failed to show: $err');
              ad.dispose();
              _ad = null;
              _load();
            },
          );
          _completeLoad();
        },
        onAdFailedToLoad: (err) {
          // AdMob backfills demand internally — a failure here is just "no ad
          // right now"; retry lazily on the next show, no cooldown needed.
          logs('[ADMOB_INTERSTITIAL] failed to load: ${err.code} ${err.message}');
          _isLoading = false;
          _completeLoad();
        },
      ),
    );
  }

  void _completeLoad() {
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
      _loadCompleter!.complete();
    }
    _loadCompleter = null;
  }

  /// Session-once keys that have already been spent — see
  /// [showInterstitialOncePerSession].
  final Set<String> _sessionShown = <String>{};

  /// [showInterstitial], but at most ONCE per app session for [key].
  ///
  /// The call-end interstitial is deliberately not gated this way: a call is a
  /// deliberate, bounded task and one ad per call is the accepted shape. Every
  /// OTHER trigger shares a single budget, because an interstitial that appears
  /// after each of a browsing session's several orders is the pattern AdMob
  /// treats as excessive — and the one users uninstall over.
  ///
  /// The key is spent only when an ad ACTUALLY showed. A no-fill must not burn
  /// the session's one slot, or the placement quietly stops earning on exactly
  /// the days inventory is thin.
  Future<bool> showInterstitialOncePerSession(
    String key, {
    Duration maxWait = const Duration(seconds: 5),
  }) async {
    if (_sessionShown.contains(key)) return false;
    final shown = await showInterstitial(maxWait: maxWait);
    if (shown) _sessionShown.add(key);
    return shown;
  }

  /// Show the interstitial if ready. If one isn't loaded yet, kick off a load
  /// and wait up to [maxWait] for it before giving up. Never throws.
  ///
  /// Returns whether an ad was actually put on screen, so a caller rationing
  /// its placement doesn't spend its budget on a no-fill.
  Future<bool> showInterstitial(
      {Duration maxWait = const Duration(seconds: 5)}) async {
    if (!AdConfig.adsEnabled) return false;
    if (!_isLoaded) {
      _load();
      final completer = _loadCompleter;
      if (completer != null) {
        try {
          await completer.future.timeout(maxWait);
        } catch (_) {
          // timed out — nothing ready to show
        }
      }
    }
    final ad = _ad;
    if (ad == null) {
      // No fill right now — start the next load so a later trigger has one.
      _load();
      return false;
    }
    // Clear our ref now; the dismiss callback disposes + preloads the next.
    _ad = null;
    try {
      await ad.show();
      return true;
    } catch (e) {
      logs('[ADMOB_INTERSTITIAL] show threw: $e');
      ad.dispose();
      _load();
      return false;
    }
  }
}

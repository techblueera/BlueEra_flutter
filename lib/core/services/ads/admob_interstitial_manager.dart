import 'dart:async';

import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/core/services/ads/ad_debug.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google AdMob interstitial manager (call-end interstitial).
///
/// AdMob is the primary ad server; Meta Audience Network is mediated behind it
/// in the AdMob dashboard, so this code only ever talks to AdMob. AdMob handles
/// its own reload cadence and backfill, so — unlike the direct-Meta manager —
/// there's no hand-rolled cooldown / session cap / 1002 handling here.
///
/// Public shape matches [MetaInterstitialManager] so the [InterstitialAdManager]
/// forwarder can delegate here with no call-site changes.
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
      try {
        await MobileAds.instance.initialize();
        // Register any test devices so Ad Inspector can launch on them.
        AdDebug.applyTestDevices();
      } catch (e) {
        print('[ADMOB_INTERSTITIAL] init failed: $e');
      }
    }
    _load();
  }

  void _load() {
    if (!AdConfig.adsEnabled || _isLoading || _isLoaded) return;
    _isLoading = true;
    _loadCompleter ??= Completer<void>();
    final unit = AdConfig.admobInterstitialUnit;
    print('[ADMOB_INTERSTITIAL] loading unit=$unit');
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('[ADMOB_INTERSTITIAL] loaded');
          _ad = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              _load(); // preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              print('[ADMOB_INTERSTITIAL] failed to show: $err');
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
          print('[ADMOB_INTERSTITIAL] failed to load: ${err.code} ${err.message}');
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

  /// Show the interstitial if ready. If one isn't loaded yet, kick off a load
  /// and wait up to [maxWait] for it before giving up. Never throws.
  Future<void> showInterstitial(
      {Duration maxWait = const Duration(seconds: 5)}) async {
    if (!AdConfig.adsEnabled) return;
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
      print('[ADMOB_INTERSTITIAL] nothing to show (preloading next)');
      _load();
      return;
    }
    // Clear our ref now; the dismiss callback disposes + preloads the next.
    _ad = null;
    try {
      await ad.show();
    } catch (e) {
      print('[ADMOB_INTERSTITIAL] show threw: $e');
      ad.dispose();
      _load();
    }
  }
}

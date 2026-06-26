import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _sdkInitialized = false;

  /// Completes when the in-flight [_load] finishes (loaded OR failed), so
  /// [showInterstitial] can wait for a just-started load instead of giving up.
  Completer<void>? _loadCompleter;

  /// Live ad units (from the obfuscated `.env`) in RELEASE builds; the test
  /// units (also from `.env`) in DEBUG/profile builds. `kReleaseMode` is true
  /// ONLY for `flutter run --release` / store builds, so debug and profile both
  /// stay on the test units — keeping the AdMob account safe from
  /// invalid-traffic / policy strikes during development.
  ///
  /// Set [AdConfig.useLiveAdsInRelease] to `false` to force the TEST units even
  /// in a release build (e.g. to verify ad delivery on a signed build).
  String get _adUnitId {
    if (AdConfig.useLiveUnits) {
      return Platform.isIOS
          ? Env.admobInterstitialAdUnitIos
          : Env.admobInterstitialAdUnitAndroid;
    }
    return Platform.isIOS
        ? Env.admobTestInterstitialAdUnitIos
        : Env.admobTestInterstitialAdUnitAndroid;
  }

  /// Initialise the Mobile Ads SDK and preload the first interstitial.
  /// Idempotent — safe to call more than once.
  Future<void> initialize() async {
    if (_sdkInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      _load();
    } catch (e) {
      debugPrint('[Ads] MobileAds init failed: $e');
    }
  }

  void _load() {
    if (!_sdkInitialized || _isLoading || _ad != null) return;
    _isLoading = true;
    _loadCompleter ??= Completer<void>();
    final unitId = _adUnitId;
    print('[INTERSTITIAL_AD] loading — ${AdConfig.useLiveUnits ? "LIVE" : "TEST"} '
        'unit=$unitId (platform=${Platform.isIOS ? "iOS" : "Android"}, '
        'release=$kReleaseMode)');
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          _completeLoad();
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
          print('[INTERSTITIAL_AD] failed to load: $error');
          _completeLoad();
        },
      ),
    );
  }

  void _completeLoad() {
    final c = _loadCompleter;
    _loadCompleter = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Show the preloaded interstitial if one is ready. When nothing is loaded
  /// (or one is already on screen) this is a no-op but kicks off a preload so
  /// the next call has an ad ready. Never throws.
  /// Show the interstitial. If one isn't preloaded yet, kick off a load and
  /// wait up to [maxWait] for it before giving up — so a freshly-triggered ad
  /// (e.g. the first call end after launch) still displays instead of silently
  /// no-op'ing. Never throws.
  Future<void> showInterstitial(
      {Duration maxWait = const Duration(seconds: 5)}) async {
    // NOTE: unconditional prints (not debugPrint) so they surface in logcat for
    // RELEASE-build testing. Filter with the tag `[INTERSTITIAL_AD]`. Remove
    // once ad delivery is verified.
    print('[INTERSTITIAL_AD] showInterstitial() called — '
        'sdkInit=$_sdkInitialized isShowing=$_isShowing adLoaded=${_ad != null}');
    // Master kill-switch: when ads are disabled for this build (e.g. a clean
    // debug run with AdConfig.showAdsInDebug == false), never show anything.
    if (!AdConfig.adsEnabled) {
      print('[INTERSTITIAL_AD] ads disabled for this build — skipped');
      return;
    }
    if (!_sdkInitialized) {
      // Not initialised yet — initialise (also kicks the first load) and wait
      // for it so we can show this round rather than skipping.
      print('[INTERSTITIAL_AD] SDK not initialised — initialising then waiting');
      await initialize();
    }
    if (!_sdkInitialized) {
      print('[INTERSTITIAL_AD] SDK init failed — nothing to show');
      return;
    }
    if (_isShowing) {
      print('[INTERSTITIAL_AD] already showing — skipped');
      return;
    }

    // No ad ready yet → start a load and wait briefly for it.
    if (_ad == null) {
      print('[INTERSTITIAL_AD] no ad ready — loading and waiting up to '
          '${maxWait.inMilliseconds}ms');
      _load();
      final completer = _loadCompleter;
      if (completer != null) {
        try {
          await completer.future.timeout(maxWait);
        } catch (_) {
          // timed out — fall through; _ad may still be null
        }
      }
    }

    final ad = _ad;
    if (ad == null) {
      print('[INTERSTITIAL_AD] no fill within wait — nothing to show (preloading next)');
      _load();
      return;
    }

    print('[INTERSTITIAL_AD] showing interstitial now');
    _isShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
        _ad = null;
        _load(); // preload the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('[INTERSTITIAL_AD] failed to show: $error');
        _isShowing = false;
        ad.dispose();
        _ad = null;
        _load();
      },
    );
    // Ownership of the ad is handed to the show call; clear our reference so a
    // concurrent trigger can't show the same instance twice.
    _ad = null;
    try {
      await ad.show();
    } catch (e) {
      print('[INTERSTITIAL_AD] show threw: $e');
      _isShowing = false;
      _load();
    }
  }
}

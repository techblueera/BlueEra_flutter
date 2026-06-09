import 'dart:async';
import 'dart:io';

import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows full-screen AdMob interstitials.
///
/// A single interstitial is preloaded and kept ready; calling
/// [showInterstitial] displays it (when one is loaded) and then preloads the
/// next. Everything is best-effort and fire-and-forget — load/show failures
/// are swallowed so an ad can never block an app flow (notably the
/// end-of-call teardown that triggers it).
///
/// Platform-specific ad-unit ids come from [Env] (obfuscated `.env`). The
/// AdMob *App ID* is configured natively (AndroidManifest.xml +
/// ios/Runner/Info.plist), not here.
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

  /// Real ad units (from the obfuscated `.env`) only in release builds; the
  /// test units (also from `.env`) everywhere else. `kReleaseMode` is true ONLY
  /// for `flutter run --release` / store builds, so debug and profile both stay
  /// on the test units — keeping the AdMob account safe from invalid-traffic /
  /// policy strikes during development.
  /// TODO(testing): TEMPORARY — force Google's always-fill TEST interstitial
  /// unit in EVERY build (including release) so a shared release APK shows ads
  /// on any device without test-device registration or live-unit fill. Google's
  /// test units serve test ads everywhere with no policy risk.
  /// REVERT to `false` for production (debug→test, release→live).
  static const bool _forceTestAds = true;

  String get _adUnitId {
    if (_forceTestAds) {
      return Platform.isIOS
          ? Env.admobTestInterstitialAdUnitIos
          : Env.admobTestInterstitialAdUnitAndroid;
    }
    if (kReleaseMode) {
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
    InterstitialAd.load(
      adUnitId: _adUnitId,
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

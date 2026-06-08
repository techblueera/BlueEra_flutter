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

  /// Real ad units (from the obfuscated `.env`) only in release builds; the
  /// test units (also from `.env`) everywhere else. `kReleaseMode` is true ONLY
  /// for `flutter run --release` / store builds, so debug and profile both stay
  /// on the test units — keeping the AdMob account safe from invalid-traffic /
  /// policy strikes during development.
  String get _adUnitId {
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
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
          debugPrint('[Ads] interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Show the preloaded interstitial if one is ready. When nothing is loaded
  /// (or one is already on screen) this is a no-op but kicks off a preload so
  /// the next call has an ad ready. Never throws.
  Future<void> showInterstitial() async {
    if (!_sdkInitialized) {
      // Not initialised yet (e.g. very early in app lifecycle) — start init so
      // a future trigger can show one. Nothing to display this round.
      await initialize();
      return;
    }
    if (_isShowing) return;

    final ad = _ad;
    if (ad == null) {
      _load();
      return;
    }

    _isShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
        _ad = null;
        _load(); // preload the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[Ads] interstitial failed to show: $error');
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
      debugPrint('[Ads] interstitial show threw: $e');
      _isShowing = false;
      _load();
    }
  }
}

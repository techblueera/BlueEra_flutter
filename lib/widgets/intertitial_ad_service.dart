import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  bool get isAdLoaded => _isAdLoaded;

  static int _screenOpenCount = 0; // resets when app restarts

  /// Call this when screen is opened
  bool shouldShowAdOnThisVisit() {
    _screenOpenCount++;
    // ✅ Skip first time, show from second time onwards
    return _screenOpenCount > 1;
  }

  /// Load Interstitial Ad
  void loadInterstitialAd({
    required String adUnitId,
    bool showWhenLoaded = false,
    VoidCallback? onAdShow,
    VoidCallback? onAdClosed,
  }) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          debugPrint("Interstitial Ad Loaded");

          if (showWhenLoaded) {
            showInterstitialAd(onAdShow: onAdShow, onAdClosed: onAdClosed);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint("Interstitial Ad Failed to Load: $error");
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// Show Interstitial Ad if loaded
  void showInterstitialAd({VoidCallback? onAdShow, VoidCallback? onAdClosed}) {
    if (!_isAdLoaded || _interstitialAd == null) {
      debugPrint("Interstitial Ad not loaded yet");
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("Interstitial Ad Showed");
        if (onAdShow != null) onAdShow();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("Interstitial Ad Dismissed");
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        if (onAdClosed != null) onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("Interstitial Ad Failed to Show: $error");
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
      },
    );

    _interstitialAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}

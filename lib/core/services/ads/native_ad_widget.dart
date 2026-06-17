import 'dart:io';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A self-contained native ad slot that loads, renders (via the platform-side
/// `groceryAdFactory` custom native layout) and disposes its own [NativeAd].
///
/// Drop it into a list between content cards. While the ad is loading it shows
/// nothing; if it fails to load the slot collapses to zero height so the list
/// looks unaffected.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    this.height = 140,
  });

  /// Must match the id the native [NativeAdFactory] is registered under in
  /// `MainActivity.kt` (Android) and `AppDelegate.swift` (iOS).
  static const String factoryId = 'groceryAdFactory';

  /// Reserved height for the ad slot. The custom native layout fills this
  /// height, so pass the store-card height to make the ad match a card exactly.
  final double height;

  /// Live native unit (from the obfuscated `.env`) in RELEASE builds, the Google
  /// TEST unit in DEBUG/profile builds. `kReleaseMode` is true ONLY for
  /// release/store builds, so development never touches the live unit — keeping
  /// the AdMob account safe from invalid-traffic / policy strikes.
  ///
  /// Set [AdConfig.useLiveAdsInRelease] to `false` to force the TEST unit even
  /// in a release build (e.g. to verify ad delivery on a signed build).
  static String get adUnitId {
    if (kReleaseMode && AdConfig.useLiveAdsInRelease) {
      return Platform.isIOS
          ? Env.admobNativeAdUnitIos
          : Env.admobNativeAdUnitAndroid;
    }
    return Platform.isIOS
        ? Env.admobTestNativeAdUnitIos
        : Env.admobTestNativeAdUnitAndroid;
  }

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _failed = false;

  // Keep the loaded ad alive across scroll recycling so we don't burn
  // impressions reloading every time the slot scrolls back into view.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    // Ensure the Mobile Ads SDK is initialised BEFORE loading. Native ad slots
    // can build before main()'s `MobileAds.instance.initialize()` completes
    // (e.g. the feed is shown right at app launch) — loading before init fails
    // silently and collapses the slot to zero height. initialize() is
    // idempotent and completes immediately once already initialised.
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('[NATIVE_AD] MobileAds init failed: $e');
    }
    if (!mounted) return;

    print('[NATIVE_AD] loading unit=${NativeAdWidget.adUnitId} '
        'factory=${NativeAdWidget.factoryId}');
    final ad = NativeAd(
      adUnitId: NativeAdWidget.adUnitId,
      factoryId: NativeAdWidget.factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('[NATIVE_AD] loaded unit=${NativeAdWidget.adUnitId} '
              'factory=${NativeAdWidget.factoryId}');
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('[NATIVE_AD] FAILED unit=${NativeAdWidget.adUnitId} '
              'factory=${NativeAdWidget.factoryId} error=$error');
          ad.dispose();
          if (!mounted) return;
          setState(() => _failed = true);
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    if (_failed) return const SizedBox.shrink();

    // Match the store cards: rounded 12 corners, the same horizontal inset the
    // list already applies to cards, and an equal `size10` gap below (the card
    // above contributes the gap on top, so spacing stays uniform). The platform
    // view fills all available space, so the SizedBox MUST bound its height —
    // inside a ListView the incoming height is otherwise unbounded.
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: (!_isLoaded || _ad == null)
              ? null // reserve space while loading so the list doesn't jump
              : AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

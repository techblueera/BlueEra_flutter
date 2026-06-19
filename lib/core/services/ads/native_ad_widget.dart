import 'dart:io';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/env.dart';
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
    this.factoryId = defaultFactoryId,
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  /// Default native factory — the grocery store-card layout. Must match the id
  /// a native [NativeAdFactory] is registered under in `MainActivity.kt`
  /// (Android) and `AppDelegate.swift` (iOS).
  static const String defaultFactoryId = 'groceryAdFactory';

  /// Which platform-side native layout renders this ad. Pass `'feedAdFactory'`
  /// to get the feed-post-styled layout instead of the grocery card.
  final String factoryId;

  /// Reserved height for the ad slot. The custom native layout fills this
  /// height, so pass the store-card height to make the ad match a card exactly.
  final double height;

  /// Outer corner radius of the slot. Pass `0` for a flush, full-width card
  /// (the feed cards are flush, not rounded).
  final double borderRadius;

  /// Gap below the slot. Defaults to `size10`; pass `0` when the native layout
  /// supplies its own bottom divider/spacing (e.g. the feed card).
  final double? bottomGap;

  /// Outer spacing around the slot. When set it overrides [bottomGap] (which is
  /// only the bottom). The feed card uses `EdgeInsets.all(5)` to match a post
  /// card's spacing exactly.
  final EdgeInsetsGeometry? margin;

  /// Optional card border (e.g. the feed post card's `1px greyE5` hairline).
  final BoxBorder? border;

  /// Optional card shadow (e.g. the feed post card's soft drop shadow).
  final List<BoxShadow>? boxShadow;

  /// Optional fill behind the ad. Set to white for a bordered card so the
  /// corners read crisp on any background; left null (transparent) by default.
  final Color? backgroundColor;

  /// Live native unit (from the obfuscated `.env`) in RELEASE builds, the Google
  /// TEST unit in DEBUG/profile builds. `kReleaseMode` is true ONLY for
  /// release/store builds, so development never touches the live unit — keeping
  /// the AdMob account safe from invalid-traffic / policy strikes.
  ///
  /// Set [AdConfig.useLiveAdsInRelease] to `false` to force the TEST unit even
  /// in a release build (e.g. to verify ad delivery on a signed build).
  static String get adUnitId {
    if (AdConfig.useLiveUnits) {
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
    // Master kill-switch: when ads are disabled for this build (e.g. a clean
    // debug run with AdConfig.showAdsInDebug == false), don't load anything and
    // collapse the slot to zero height so the list looks ad-free.
    if (!AdConfig.adsEnabled) {
      if (mounted) setState(() => _failed = true);
      return;
    }

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
        'factory=${widget.factoryId}');
    final ad = NativeAd(
      adUnitId: NativeAdWidget.adUnitId,
      factoryId: widget.factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('[NATIVE_AD] loaded unit=${NativeAdWidget.adUnitId} '
              'factory=${widget.factoryId}');
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
              'factory=${widget.factoryId} error=$error');
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
      padding: widget.margin ??
          EdgeInsets.only(bottom: widget.bottomGap ?? SizeConfig.size10),
      child: Container(
        // antiAlias clips the platform AdWidget to the rounded corners; the
        // optional border/shadow/fill reproduce a feed post card's chrome.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
          boxShadow: widget.boxShadow,
        ),
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

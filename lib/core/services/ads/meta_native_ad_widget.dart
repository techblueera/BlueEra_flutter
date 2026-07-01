import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/material.dart';

/// Renders a Meta (Facebook Audience Network) native ad.
///
/// Same public shape (height + card chrome) as `NativeAdWidget`, which delegates
/// to it — so every native slot in the app (feed + grocery) renders a Meta
/// native ad with no changes at the call sites.
///
/// Shows nothing while loading, and collapses to zero
/// height if the ad fails so the surrounding list looks unaffected.
class MetaNativeAdWidget extends StatefulWidget {
  const MetaNativeAdWidget({
    super.key,
    this.height = 140,
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  final double height;
  final double borderRadius;
  final double? bottomGap;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;

  @override
  State<MetaNativeAdWidget> createState() => _MetaNativeAdWidgetState();
}

class _MetaNativeAdWidgetState extends State<MetaNativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  bool _failed = false;

  /// True once the Meta SDK init has resolved — we only build the
  /// [FacebookNativeAd] after this, otherwise the plugin loads before init and
  /// the ad silently never calls back.
  bool _sdkReady = false;

  /// True once ANY listener callback (LOADED/ERROR/…) has fired. Used by the
  /// watchdog to detect the "native SDK never responded" case.
  bool _gotCallback = false;
  Timer? _watchdog;

  // Keep the loaded ad alive across scroll recycling (mirrors the Google slot)
  // so we don't reload and burn impressions each time it scrolls back in.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Master kill-switch — collapse if ads are disabled for this build.
    if (!AdConfig.adsEnabled) {
      print('[META_NATIVE_AD] ads disabled for this build — collapsing slot');
      _failed = true;
      return;
    }
    print('[META_NATIVE_AD] initState — awaiting SDK init, '
        'unit=${AdConfig.metaNativeUnit}');
    MetaAds.ensureInitialized().then((ok) {
      print('[META_NATIVE_AD] SDK ready=$ok — building native ad '
          'unit=${AdConfig.metaNativeUnit}');
      if (!mounted) return;
      setState(() {
        _sdkReady = true;
        if (!ok) _failed = true; // init failed → nothing to show
      });
      // Watchdog: if the FacebookNativeAd never fires a listener callback, the
      // native side never responded — log it so silence is explicit.
      _watchdog = Timer(const Duration(seconds: 12), () {
        if (!_gotCallback) {
          print('[META_NATIVE_AD] ⚠️ NO callback within 12s for '
              'unit=${AdConfig.metaNativeUnit} — native SDK never responded '
              '(check Meta app/placement approval or plugin channel).');
        }
      });
    });
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    if (_failed) return const SizedBox.shrink();

    return Padding(
      padding: widget.margin ??
          EdgeInsets.only(bottom: widget.bottomGap ?? SizeConfig.size10),
      child: Container(
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
          // Only mount the ad once the SDK is initialised.
          child: !_sdkReady
              ? null
              : FacebookNativeAd(
                  placementId: AdConfig.metaNativeUnit,
                  adType: NativeAdType.NATIVE_AD,
                  width: double.infinity,
                  height: widget.height,
                  backgroundColor: widget.backgroundColor ?? AppColors.white,
                  titleColor: AppColors.mainTextColor,
                  descriptionColor: AppColors.secondaryTextColor,
                  buttonColor: AppColors.primaryColor,
                  buttonTitleColor: AppColors.white,
                  buttonBorderColor: AppColors.primaryColor,
                  // Keep the reserved box while loading so the list doesn't
                  // jump; the listener collapses it only on a hard error.
                  // keepAlive keeps the loaded ad across scroll recycling.
                  keepExpandedWhileLoading: true,
                  keepAlive: true,
                  listener: (result, value) {
                    _gotCallback = true;
                    print('[META_NATIVE_AD] $result '
                        'unit=${AdConfig.metaNativeUnit} value=$value');
                    if (result == NativeAdResult.ERROR && mounted) {
                      setState(() => _failed = true);
                    }
                  },
                ),
        ),
      ),
    );
  }
}

/// One-time initialiser for the Meta Audience Network SDK. Idempotent — the
/// first native/interstitial slot awaits it; the init runs exactly once and
/// every caller shares the same Future.
///
/// IMPORTANT: ad loads MUST await this. Calling `loadInterstitialAd` /
/// building `FacebookNativeAd` before `init()` resolves means the plugin's
/// method channel never calls back (you see "loading" but no LOADED/ERROR).
class MetaAds {
  MetaAds._();

  static Future<bool>? _initFuture;

  static Future<bool> ensureInitialized() =>
      _initFuture ??= _init();

  static Future<bool> _init() async {
    print('[META_ADS] init start (testMode=${AdConfig.metaTestMode})');
    try {
      // No testingId: test ads come from the reserved magic placement tokens
      // (see AdConfig.metaNativeUnit), which work on any device without
      // registering a device hash. Passing a bogus hash here does nothing.
      final res = await FacebookAudienceNetwork.init(
        iOSAdvertiserTrackingEnabled: true,
      );
      print('[META_ADS] init result=$res');
      return res ?? false;
    } catch (e, st) {
      print('[META_ADS] init FAILED: $e\n$st');
      return false;
    }
  }
}

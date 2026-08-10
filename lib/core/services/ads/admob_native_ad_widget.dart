import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/core/services/ads/ads_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Renders a Google AdMob native ad using the plugin's built-in **platform
/// native template** (`NativeTemplateStyle`) — no platform-side `NativeAdFactory`
/// / XML is needed.
///
/// The [NativeAdWidget] forwarder delegates to this widget (height + card
/// chrome, collapse on failure, keepAlive across scroll recycling) with no
/// call-site changes. AdMob manages its own load cadence, so there's no
/// hand-rolled load-gate / circuit-breaker here.
class AdMobNativeAdWidget extends StatefulWidget {
  const AdMobNativeAdWidget({
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
  State<AdMobNativeAdWidget> createState() => _AdMobNativeAdWidgetState();
}

class _AdMobNativeAdWidgetState extends State<AdMobNativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  /// The push/pop animation of the route this slot sits on, while we're waiting
  /// for it to finish. Null once we've stopped listening.
  Animation<double>? _routeAnimation;

  /// Set the moment a request is started, so neither a second
  /// [didChangeDependencies] nor a late animation callback can fire a duplicate
  /// load (which would burn an impression).
  bool _requested = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!AdConfig.adsEnabled) {
      _failed = true;
      return;
    }
  }

  /// Requests the ad only once the route carrying this slot has finished
  /// animating in.
  ///
  /// Loading straight from [initState] put the request inside the push
  /// transition. An ad request is not free on the platform side — it binds the
  /// Play Services ads service, and the AdWidget it produces is a platform
  /// view — so it competed with the animation for the main thread and the
  /// screen visibly stalled on open (`Choreographer: Skipped N frames` landing
  /// right after the request in logcat).
  ///
  /// Waiting costs the ad the length of one transition and buys a clean push.
  /// Slots that are not on a route, or are already settled on one (built during
  /// a scroll rather than a navigation), load immediately as before.
  ///
  /// [didChangeDependencies] rather than [initState]: `ModalRoute.of` registers
  /// an inherited-widget dependency, which is not allowed during initState.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_failed || _requested) return;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _load();
      return;
    }
    if (identical(animation, _routeAnimation)) return;
    _detachRouteAnimation();
    _routeAnimation = animation..addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _detachRouteAnimation();
    if (mounted && !_requested) _load();
  }

  void _detachRouteAnimation() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _routeAnimation = null;
  }

  Future<void> _load() async {
    _requested = true;
    // Normally already finished (warmed at launch — see [AdsBootstrap]), in
    // which case this is a single microtask. It only actually waits when this
    // slot is the first ad of the session, and then it waits INSTEAD of doing
    // the SDK start-up inline.
    await AdsBootstrap.ensureInitialized();
    if (!mounted) return;

    final unit = AdConfig.admobNativeUnit;
    print('[ADMOB_NATIVE] loading unit=$unit');
    _ad = NativeAd(
      adUnitId: unit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: widget.backgroundColor ?? AppColors.white,
        cornerRadius: widget.borderRadius,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.white,
          backgroundColor: AppColors.primaryColor,
        ),
        primaryTextStyle:
            NativeTemplateTextStyle(textColor: AppColors.mainTextColor),
        secondaryTextStyle:
            NativeTemplateTextStyle(textColor: AppColors.secondaryTextColor),
        tertiaryTextStyle:
            NativeTemplateTextStyle(textColor: AppColors.secondaryTextColor),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          print('[ADMOB_NATIVE] failed to load: ${err.code} ${err.message}');
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _detachRouteAnimation();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin

    // Collapse to nothing on failure so the surrounding list looks unaffected.
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
          // Nothing until loaded (reserves the slot height so the list doesn't
          // jump); the AdWidget renders the platform native template once ready.
          child: (!_loaded || _ad == null) ? null : AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

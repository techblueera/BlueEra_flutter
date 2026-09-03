import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
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
    this.height,
    this.templateType = TemplateType.small,
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  /// Fixed slot height. Leave this null (the default) and the slot measures
  /// itself from the template's own layout — see [_templateHeight], which is
  /// the only way to be sure the ad isn't clipped on an arbitrary screen width.
  final double? height;

  /// Which AdMob native template renders the ad. [TemplateType.small] is a
  /// single list-row strip (icon + headline + CTA, no media view);
  /// [TemplateType.medium] adds a 190dp media view and is a FIXED 350dp tall on
  /// Android, so it only fits a slot given at least that much room.
  final TemplateType templateType;

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

    _ad = NativeAd(
      adUnitId: AdConfig.admobNativeUnit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: widget.backgroundColor ?? AppColors.white,
        // iOS only — `ad_instance_manager.dart` drops `cornerRadius` for
        // Android, where the template paints the flat `gnt_outline_shape`
        // (white fill, 2dp grey stroke, square corners) instead. The rounding
        // Android does get comes from the clipping [Container] in [build].
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
          logs('[ADMOB_NATIVE] failed to load: ${err.code} ${err.message}');
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

    // ## The slot takes up nothing until it has an ad, and never gives it back
    //
    // This used to reserve [widget.height] from the moment it was built and
    // collapse to zero when the request failed. Fill is close to zero right now
    // (the ad account is gated), so in practice EVERY slot reserved 300px and
    // then dropped it a second later — and a slot that shrinks while it sits
    // ABOVE the viewport takes that height out from under the reader: content
    // slides up and `maxScrollExtent` shrinks, so the scroll position is
    // corrected backwards. In a paginated list with a slot every 10 cards that
    // reads as "scrolling starts over", and it fires exactly when a page lands,
    // because that is when the next slot is built.
    //
    // Flutter viewports have no scroll anchoring, so the only reliable rule is:
    // never change an extent that may already be above the reader. Zero while
    // loading, zero on failure, [widget.height] once an ad is live — and never
    // back down, since nothing sets `_loaded` false again. Growth still happens,
    // but only when an ad genuinely arrives, and slots are built lazily just
    // ahead of the viewport, so it lands off-screen BELOW the reader, which
    // pushes content down rather than pulling it out.
    if (_failed || !_loaded || _ad == null) return const SizedBox.shrink();

    return Padding(
      padding: widget.margin ??
          EdgeInsets.only(bottom: widget.bottomGap ?? SizeConfig.size10),
      // The slot's height follows from the width it actually gets, so the same
      // widget fits a padded list row, a full-bleed sliver and a tablet without
      // anyone hand-tuning a number per screen. See [_templateHeight].
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.border,
              boxShadow: widget.boxShadow,
            ),
            child: SizedBox(
              height: widget.height ??
                  _templateHeight(widget.templateType, width),
              width: double.infinity,
              // Only reached with a loaded ad — see the guard above.
              child: AdWidget(ad: _ad!),
            ),
          );
        },
      ),
    );
  }

  /// The height [type] needs when it is [width] wide, in logical pixels.
  ///
  /// Neither template sizes itself to the box it is handed. An [AdWidget] is a
  /// platform view: it renders the native layout at whatever size we give it
  /// and the surrounding clip eats the overflow. Both templates anchor the
  /// call-to-action button to the BOTTOM, so a short slot slices off exactly
  /// that — the button survives as a coloured bar with its label cut away,
  /// which is what a 300dp slot did to the 350dp medium template.
  ///
  ///  * [TemplateType.medium] — `gnt_medium_template_view.xml` pins its root
  ///    `NativeAdView` to a literal `350dp` (190dp media + 60dp headline row +
  ///    body + a >=35dp CTA), independent of width.
  ///  * [TemplateType.small] — `gnt_small_template_view.xml` is `wrap_content`
  ///    around a `4:1` block inset by `gnt_default_margin` (10dp) on all four
  ///    sides, so its natural height is `(width - 20) / 4 + 20`. Across phone
  ///    widths that lands at 99-117dp, which brackets the iOS small template's
  ///    own 101pt design height, so one formula serves both platforms. The
  ///    floor covers unusually narrow layouts and keeps us clear of Google's
  ///    documented 90dp minimum.
  static double _templateHeight(TemplateType type, double width) {
    if (type == TemplateType.medium) return 350;
    final natural = (width - 20) / 4 + 20;
    return natural < 96 ? 96 : natural;
  }
}

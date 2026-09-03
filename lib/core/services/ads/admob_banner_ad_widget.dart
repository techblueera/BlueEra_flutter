import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/core/services/ads/ads_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A Google AdMob **banner** slot — the anchored strip that sits under a "Me"
/// tab's content, in the place the server-served Qureka promo strip used to
/// hold.
///
/// ## Why the size comes from layout rather than a constant
///
/// A [BannerAd] must be constructed with its [AdSize] BEFORE it is loaded, and
/// the size that earns most is the one matched to the width the slot actually
/// gets — Google's *anchored adaptive* size, which picks a height for a given
/// width (never below 50dp, never above 15% of the screen). So the widget waits
/// for layout, asks the SDK for the adaptive size at that width, and only then
/// builds and loads the ad. [AdSize.banner] (320x50) is the fallback for the
/// rare null the platform can return.
///
/// ## Zero height until there is an ad, and never back down
///
/// Same rule as [AdMobNativeAdWidget], for the same reason: a slot that
/// reserves height and then gives it back moves content that may already be
/// above the reader, and Flutter viewports have no scroll anchoring. Nothing
/// while loading, nothing on failure, the ad's own height once it is live. It
/// also matches the strip this replaces, which rendered nothing when the promo
/// bundle had no creative.
class AdMobBannerAdWidget extends StatefulWidget {
  const AdMobBannerAdWidget({
    super.key,
    this.margin,
    this.borderRadius = 12,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  /// Spacing around the strip. The caller has to say — nothing here can measure
  /// the insets its siblings apply. See [bannerAdMarginFor].
  final EdgeInsetsGeometry? margin;

  /// Corner radius of the slot.
  ///
  /// The AdMob SDK has no corner-radius option for banners — [AdSize] carries
  /// width and height and nothing else, and the `cornerRadius` on
  /// `NativeTemplateStyle` belongs to the NATIVE templates (and is dropped on
  /// Android by the plugin regardless). So the rounding is done here, by
  /// clipping the platform view.
  ///
  /// That clip actually takes effect because the plugin builds the banner with
  /// `initSurfaceAndroidView` (texture-layer hybrid composition) on Android and
  /// a `UiKitView` on iOS: both composite through Flutter, so an antialiased
  /// rounded clip applies the same way it would to any widget.
  ///
  /// Note what a clip does to the creative: it CROPS the ad's four corners.
  /// A modest radius takes a few pixels of background off a banner that is
  /// nearly always a solid ground, which is why this is safe at 12 and why it
  /// should not be pushed to a large value — a radius big enough to bite into
  /// the advertiser's text or logo is altering ad content. Pass a
  /// [backgroundColor] and a small [margin] instead if you ever want a heavier
  /// rounded card around an uncropped ad.
  ///
  /// Set to 0 for square corners.
  final double borderRadius;

  /// Optional fill behind the ad. Only visible where the creative doesn't
  /// reach — the clipped corners.
  final Color? backgroundColor;

  /// Optional card border, for a slot that has to match bordered cards above it.
  final BoxBorder? border;

  /// Optional card shadow.
  final List<BoxShadow>? boxShadow;

  @override
  State<AdMobBannerAdWidget> createState() => _AdMobBannerAdWidgetState();
}

class _AdMobBannerAdWidgetState extends State<AdMobBannerAdWidget>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _failed = false;

  /// Set the moment a request starts, so a relayout at a slightly different
  /// width can't fire a second load and burn an impression.
  bool _requested = false;

  /// The push/pop animation of the route this slot sits on, while we're waiting
  /// for it to finish. Null once we've stopped listening.
  Animation<double>? _routeAnimation;

  /// The width the pending load was scheduled for.
  double _pendingWidth = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!AdConfig.adsEnabled) _failed = true;
  }

  @override
  void dispose() {
    _detachRouteAnimation();
    _ad?.dispose();
    super.dispose();
  }

  /// Requests the ad once the route carrying this slot has settled.
  ///
  /// An ad request binds the Play Services ads service and produces a platform
  /// view; doing that inside a push transition made the screen visibly stall on
  /// open (`Choreographer: Skipped N frames`). Waiting costs the ad one
  /// transition and buys a clean push. Slots built during a scroll rather than
  /// a navigation see a settled animation and load immediately.
  void _requestWhenSettled(double width) {
    if (_failed || _requested) return;
    _pendingWidth = width;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _load(width);
      return;
    }
    if (identical(animation, _routeAnimation)) return;
    _detachRouteAnimation();
    _routeAnimation = animation..addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _detachRouteAnimation();
    if (mounted && !_requested) _load(_pendingWidth);
  }

  void _detachRouteAnimation() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _routeAnimation = null;
  }

  Future<void> _load(double width) async {
    if (width <= 0) return;
    _requested = true;
    // Normally already finished (warmed at launch — see [AdsBootstrap]), in
    // which case this is a single microtask.
    await AdsBootstrap.ensureInitialized();
    if (!mounted) return;

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              width.truncate(),
            ) ??
            AdSize.banner;
    if (!mounted) return;

    _ad = BannerAd(
      size: size,
      adUnitId: AdConfig.admobBannerUnit,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _size = size;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          logs('[ADMOB_BANNER] failed to load: ${err.code} ${err.message}');
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin

    if (_failed) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // Kick the request off from layout, not from the build itself — the
        // adaptive size needs a width, and starting work inside build is only
        // safe once the frame is done.
        if (!_requested && width > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _requestWhenSettled(width);
          });
        }

        final ad = _ad;
        final size = _size;
        if (!_loaded || ad == null || size == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: widget.margin ?? EdgeInsets.zero,
          child: Align(
            // The adaptive size is computed for the slot's width, so this is
            // normally a no-op; it only matters when the ad comes back at the
            // fixed 320x50 fallback in a wider slot, where a left-aligned strip
            // would look misplaced.
            alignment: Alignment.center,
            // Same chrome shape as [AdMobNativeAdWidget], so the two ad formats
            // round and sit on the page identically. See [widget.borderRadius]
            // for why the radius lives here rather than in the ad request.
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.border,
                boxShadow: widget.boxShadow,
              ),
              child: SizedBox(
                width: size.width.toDouble(),
                height: size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Layout helpers — the "Me" tab strip
// ─────────────────────────────────────────────────────────────────────────────

/// Default margin for the strip: the tab scrolls that pad their content
/// `left: 20` and nothing on the right supply the left inset themselves, so the
/// strip contributes the matching right one.
///
/// Screens laid out any other way must pass their own — see
/// [withBannerAdBelow].
const EdgeInsets kBannerAdMargin = EdgeInsets.fromLTRB(0, 16, 20, 4);

/// The strip's margin for a tab whose scroll has NO horizontal padding and
/// whose content insets itself by [contentInset] — the strip then takes the
/// same inset on both sides and lines up with the cards above it.
EdgeInsets bannerAdMarginFor(double contentInset) =>
    EdgeInsets.fromLTRB(contentInset, 16, contentInset, 4);

/// [content] with a banner ad appended under it, for use **inside** a scroll
/// view.
///
/// This is how the "Me" screens carry their ad: each wraps its first tab in a
/// `_tabScroll(...)` helper (a `SingleChildScrollView`), and passing the tab
/// through here puts the banner in that scroll's CONTENT. It scrolls with the
/// tab and comes to rest after the last row, rather than being pinned as a
/// separate band.
///
/// [margin] is how the strip lines up with the cards above it, and the caller
/// has to say — nothing here can measure the insets its sibling applies. A
/// screen whose scroll has no horizontal padding passes
/// `bannerAdMarginFor(<its own content inset>)`; one that already pads both
/// edges passes `bannerAdMarginFor(0)`.
Widget withBannerAdBelow(
  Widget content, {
  EdgeInsets? margin,
  double borderRadius = 12,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      content,
      AdMobBannerAdWidget(
        margin: margin ?? kBannerAdMargin,
        borderRadius: borderRadius,
      ),
    ],
  );
}

/// [withBannerAdBelow] for the "Me" screens whose `_tabScroll` takes a
/// `List<Widget>` (content creator, professionals, rider orders) rather than a
/// single child.
List<Widget> withBannerAdBelowAll(
  List<Widget> content, {
  EdgeInsets? margin,
  double borderRadius = 12,
}) {
  return [
    ...content,
    AdMobBannerAdWidget(
      margin: margin ?? kBannerAdMargin,
      borderRadius: borderRadius,
    ),
  ];
}

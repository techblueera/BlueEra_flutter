import 'dart:math';

import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/promo/model/promo_ad_models.dart';
import 'package:BlueEra/features/common/promo/promo_ads_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import 'package:url_launcher/url_launcher.dart';

/// Where a promo banner points when the creative itself carries no
/// `targetUrl`.
///
/// The API marks most creatives decorative (`targetUrl: null`) and tells
/// clients not to invent a destination. This is not an invented one: it is the
/// app's configured promo destination, the same single constant every placement
/// read while the artwork was bundled. A creative that DOES carry a
/// `targetUrl` always wins over it.
///
/// Empty disables the tap everywhere — the banners then render as pure artwork
/// with no tap target, which is exactly the API's decorative rule.
const String kQurekaPromoUrl = 'https://qureka.com/';

/// While true, the surfaces that opted in by using [PromoAdSlot] fill their ad
/// rows with promo cards instead of Google AdMob native ads.
///
/// **Now false.** Qureka is down to ONE placement in the app — the two strips
/// between Discover's catalogue sections — and every other slot serves Google
/// AdMob: native in the content lists, a banner under each "Me" tab
/// ([withBannerAdBelow]), an interstitial after a connected call. Flipping this
/// back to true would put promo cards into the feed and the food listing again;
/// the call sites need no other edit either way, because [PromoAdSlot] takes
/// the same arguments [NativeAdSlot] does and simply forwards them.
const bool kQurekaReplacesNativeAds = false;

/// An ad row that renders EITHER a promo card or a real native ad, decided by
/// [kQurekaReplacesNativeAds].
///
/// A drop-in for [NativeAdSlot]: same constructor arguments, so switching a
/// screen over is a one-word change at the call site and switching back is one
/// bool. The native-ad-only arguments ([factoryId], [height], [adOrdinal] …)
/// are still accepted while the promo is showing — the promo ignores them, but
/// keeping them means nothing has to be re-derived when ads come back.
///
/// [adOrdinal] doubles as the promo's creative index, so a list with several ad
/// rows shows a DIFFERENT creative in each rather than the same one repeated
/// down the page.
class PromoAdSlot extends StatelessWidget {
  const PromoAdSlot({
    super.key,
    required this.adOrdinal,
    this.keyPrefix = 'native_ad',
    this.height,
    this.templateType = TemplateType.small,
    this.factoryId = 'groceryAdFactory',
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  final int adOrdinal;
  final String keyPrefix;
  final double? height;
  final TemplateType templateType;
  final String factoryId;
  final double borderRadius;
  final double? bottomGap;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!kQurekaReplacesNativeAds) {
      return NativeAdSlot(
        adOrdinal: adOrdinal,
        keyPrefix: keyPrefix,
        height: height,
        templateType: templateType,
        factoryId: factoryId,
        borderRadius: borderRadius,
        bottomGap: bottomGap,
        margin: margin,
        border: border,
        boxShadow: boxShadow,
        backgroundColor: backgroundColor,
      );
    }
    return QurekaPromoBanner(
      // Cycle by ordinal rather than at random: within one list the cards then
      // differ from each other, and they stay put across rebuilds instead of
      // reshuffling every time the list repaints.
      creativeIndex: adOrdinal,
      margin: margin ?? EdgeInsets.fromLTRB(0, 0, 0, bottomGap ?? 12),
      borderRadius: borderRadius,
    );
  }
}

// The "Me" tab strip helpers used to live here — `kQurekaStrip`,
// `kQurekaStripMargin`, `qurekaStripMarginFor`, `withQurekaPromoBelow` and
// `withQurekaPromoBelowAll`. Every one of those 18 tabs now carries a Google
// AdMob banner instead, so they moved to
// `core/services/ads/admob_banner_ad_widget.dart` as `kBannerAdMargin`,
// `bannerAdMarginFor`, `withBannerAdBelow` and `withBannerAdBelowAll` — same
// shapes, same alignment rules, same "collapses when there is nothing to show"
// behaviour. They are NOT kept here as a dormant alternative on purpose: a
// second set of strip helpers is how a Qureka strip finds its way back onto a
// tab by habit. Qureka's only placement is Discover's two section strips.

/// A tappable promo banner drawn from the SERVER-served creative bundle
/// ([PromoAdsService]) — no bundled artwork, so a campaign can be swapped,
/// paused or reordered without an app release.
///
/// The slot decides the size, not the image: [strip] picks the 320x50
/// `banner_strip` placement, otherwise the 900x506 `home_hero` card. The box is
/// reserved from the placement's own aspect ratio BEFORE the image loads, so a
/// feed never jumps as creatives arrive.
///
/// **Renders nothing when the bundle has no creative for its placement** — a
/// cold first launch with no cache and no network, a paused campaign, a slot
/// the backend stopped serving. A promo that isn't there collapses to zero
/// height rather than leaving a grey box.
///
/// Taps open [kQurekaPromoUrl] (or the creative's own `targetUrl`) in the
/// **device browser** — `LaunchMode.externalApplication`, not the in-app
/// webview. The destination is a third-party site that runs its own quizzes and
/// sign-in, and an embedded webview gives it none of the browser session, saved
/// logins or cookies it expects, so the promo is worth less to the user AND to
/// the partner. The app is left in the background and comes back untouched on
/// the system back gesture.
class QurekaPromoBanner extends StatefulWidget {
  const QurekaPromoBanner({
    super.key,
    this.creativeIndex,
    this.strip = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius = 16,
  });

  /// Which creative in the placement to show. Null picks one per MOUNT (not per
  /// build, so it does not reshuffle on repaint) — placements that appear on
  /// several screens then don't all show the identical banner, without any of
  /// them having to coordinate.
  final int? creativeIndex;

  /// Draw the slim 320x50 banner strip instead of the wide card.
  ///
  /// Not a styling flag — it selects a different PLACEMENT, whose artwork is
  /// drawn for that shape. A card cropped to strip height would lose most of
  /// its message.
  final bool strip;

  final EdgeInsetsGeometry margin;
  final double borderRadius;

  @override
  State<QurekaPromoBanner> createState() => _QurekaPromoBannerState();
}

class _QurekaPromoBannerState extends State<QurekaPromoBanner> {
  /// Frozen at mount so the random pick survives rebuilds. Only used when the
  /// caller passes no [QurekaPromoBanner.creativeIndex].
  late final int _seed = Random().nextInt(1 << 31);

  String get _placementKey =>
      widget.strip ? AdPlacements.bannerStrip : AdPlacements.homeHero;

  Future<void> _open(AdCreative creative) async {
    final raw = (creative.targetUrl ?? kQurekaPromoUrl).trim();
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri == null) return;
    try {
      // The device BROWSER, not an in-app webview: the promo is a third-party
      // destination that runs its own quizzes and sign-in, and a webview hands
      // it none of the browser session it expects. Android resolves this
      // through the manifest's `https` VIEW query, which is already declared.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A device with no browser at all — nothing useful to say, and a promo is
      // not worth a snackbar over.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when a fetch lands, so a banner built before the bundle arrived
    // fills itself in rather than staying collapsed for the session.
    return ValueListenableBuilder<int>(
      valueListenable: PromoAdsService.revision,
      builder: (context, _, __) {
        final placement = PromoAdsService.of(_placementKey);
        final creative = PromoAdsService.pick(
          _placementKey,
          index: widget.creativeIndex ?? _seed,
        );
        // Nothing to show → no gap. See the class doc.
        if (placement == null || creative == null) {
          return const SizedBox.shrink();
        }

        final tappable =
            (creative.targetUrl ?? kQurekaPromoUrl).trim().isNotEmpty;

        return Padding(
          padding: widget.margin,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tappable ? () => _open(creative) : null,
            child: ClipRRect(
              // A 50pt-tall strip with a 16pt radius reads as a pill; it takes
              // its own, smaller corner.
              borderRadius:
                  BorderRadius.circular(widget.strip ? 8 : widget.borderRadius),
              child: AspectRatio(
                // The slot's own ratio, from the API — the box is the right
                // size before a byte of the image has loaded.
                aspectRatio: placement.aspectRatio,
                child: CachedNetworkImage(
                  imageUrl: creative.url,
                  fit: BoxFit.cover,
                  // A flat tint, not a spinner: the box is already the final
                  // size, so this just holds its place for the moment it takes
                  // the (cached, after first run) image to decode.
                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                  // A dead URL collapses the slot instead of parking a broken
                  // image in the layout.
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

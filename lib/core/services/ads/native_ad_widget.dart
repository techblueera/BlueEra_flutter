import 'package:BlueEra/core/services/ads/admob_native_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;

/// A self-contained native ad slot.
///
/// Ads are served by **Google AdMob**. This widget is a thin wrapper that
/// forwards its card chrome (height / radius / margin / border / shadow / fill)
/// to [AdMobNativeAdWidget]. It keeps the original public API — including
/// [factoryId] — so existing call sites and [NativeAdSlot] need no changes.
/// [factoryId] is retained for source-compatibility only and is IGNORED (the
/// AdMob native template renders itself; no platform-side ad factories).
class NativeAdWidget extends StatelessWidget {
  const NativeAdWidget({
    super.key,
    this.height,
    this.templateType = TemplateType.small,
    this.factoryId = defaultFactoryId,
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  /// Retained for API compatibility only — ignored under AdMob ads.
  static const String defaultFactoryId = 'groceryAdFactory';

  /// Ignored (AdMob renders its own layout); kept so call sites still compile.
  final String factoryId;

  /// Fixed height for the ad slot. Null (the default) lets the slot size itself
  /// from [templateType] and the width it is given, which is what keeps the
  /// bottom-anchored call-to-action from being clipped.
  final double? height;

  /// Which AdMob native template renders the ad — small (a list-row strip) by
  /// default, medium for the taller layout with a media view.
  final TemplateType templateType;

  /// Outer corner radius of the slot.
  final double borderRadius;

  /// Gap below the slot. Defaults to `size10` inside [AdMobNativeAdWidget].
  final double? bottomGap;

  /// Outer spacing around the slot (overrides [bottomGap] when set).
  final EdgeInsetsGeometry? margin;

  /// Optional card border.
  final BoxBorder? border;

  /// Optional card shadow.
  final List<BoxShadow>? boxShadow;

  /// Optional fill behind the ad.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AdMobNativeAdWidget(
      height: height,
      templateType: templateType,
      borderRadius: borderRadius,
      bottomGap: bottomGap,
      margin: margin,
      border: border,
      boxShadow: boxShadow,
      backgroundColor: backgroundColor,
    );
  }
}

import 'package:BlueEra/core/services/ads/admob_native_ad_widget.dart';
import 'package:flutter/material.dart';

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
    this.height = 140,
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

  /// Reserved height for the ad slot.
  final double height;

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
      borderRadius: borderRadius,
      bottomGap: bottomGap,
      margin: margin,
      border: border,
      boxShadow: boxShadow,
      backgroundColor: backgroundColor,
    );
  }
}

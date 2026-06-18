import 'package:flutter/foundation.dart';

/// Two simple ad knobs — one per build type:
///
///  • DEBUG / profile builds → [showAdsInDebug]
///        true  = show Google TEST ads
///        false = show NO ads (slots collapse, interstitials no-op)
///
///  • RELEASE / store builds → [useLiveAdsInRelease]
///        true  = show LIVE ad units (real money)
///        false = show Google TEST ads (verify delivery on a signed build)
///
/// Release builds ALWAYS show an ad (live or test); they never go ad-free.
/// `kReleaseMode` is true only for release/store builds, so debug & profile
/// always fall under the debug knob.
class AdConfig {
  AdConfig._();

  /// RELEASE knob: live ad units when `true`, Google TEST units when `false`.
  static const bool useLiveAdsInRelease = true;

  /// DEBUG knob: Google TEST ads when `true`, no ads at all when `false`.
  static const bool showAdsInDebug = false;

  /// Whether ads should load/show at all for the current build.
  /// RELEASE always runs ads; DEBUG/profile only when [showAdsInDebug] is true.
  static bool get adsEnabled => kReleaseMode || showAdsInDebug;

  /// Whether to use the LIVE ad units (only ever true in a release build with
  /// [useLiveAdsInRelease]); otherwise the Google TEST units are used.
  static bool get useLiveUnits => kReleaseMode && useLiveAdsInRelease;
}

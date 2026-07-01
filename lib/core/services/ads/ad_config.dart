import 'dart:io';

import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';

/// Central config for the app's ads — now served entirely by **Meta (Facebook
/// Audience Network)**. Google AdMob has been removed.
///
///  • DEBUG / profile builds → [showAdsInDebug]
///        true  = show Meta TEST ads
///        false = show NO ads (slots collapse, interstitials no-op)
///  • RELEASE / store builds → [useLiveAdsInRelease]
///        true  = show LIVE Meta ads (real money)
///        false = show Meta TEST ads (verify delivery on a signed build)
///
/// `kReleaseMode` is true only for release/store builds, so debug & profile fall
/// under the debug knob. DEBUG always uses TEST ads; only RELEASE can serve LIVE
/// ads, and only when [useLiveAdsInRelease] is true.
class AdConfig {
  AdConfig._();

  /// RELEASE knob: LIVE Meta ads when `true`, Meta TEST ads when `false`.
  /// Set `false` to verify ad delivery on a signed release build without
  /// serving real ads (keeps the Meta account safe from invalid-traffic /
  /// policy strikes during release testing).
  static const bool useLiveAdsInRelease = true;

  /// DEBUG knob: show Meta TEST ads when `true`, no ads at all when `false`.
  /// On so Meta test ads render while debugging on-device.
  static const bool showAdsInDebug = true;

  /// Whether ads should load/show at all for the current build.
  /// RELEASE always runs ads; DEBUG/profile only when [showAdsInDebug] is true.
  static bool get adsEnabled => kReleaseMode || showAdsInDebug;

  // ── Meta (Facebook Audience Network) placement IDs ──────────────────────
  // Real placement ids come from the obfuscated `.env` (via [Env]), split per
  // platform — same pattern the old AdMob units used. Format:
  // "<app_id>_<placement_id>". They serve live ads once the Meta app has passed
  // review.
  //
  // While [metaTestMode] is true we DON'T hit the live ids directly — instead we
  // use a Meta reserved test-placement token (e.g.
  // "IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID", kept LITERAL), which forces a
  // canned Meta TEST ad on ANY device (no test-device registration needed).
  //
  // TEST ads whenever this is NOT a release build, OR when it IS release but
  // [useLiveAdsInRelease] is off. So: debug → always test; release → live only
  // when [useLiveAdsInRelease] is true.
  static const bool metaTestMode = !kReleaseMode || !useLiveAdsInRelease;

  /// Real native placement id for the current platform (from `.env`).
  static String get _metaNativeReal => Platform.isIOS
      ? Env.metaNativePlacementIos
      : Env.metaNativePlacementAndroid;

  /// Real interstitial placement id for the current platform (from `.env`).
  static String get _metaInterstitialReal => Platform.isIOS
      ? Env.metaInterstitialPlacementIos
      : Env.metaInterstitialPlacementAndroid;

  // Meta's reserved TEST placement strings. These are LITERAL magic tokens —
  // the trailing "YOUR_PLACEMENT_ID" text is kept verbatim (NOT replaced with a
  // real id). Meta always returns a canned test ad for them on ANY device.
  static const String _metaTestNativeUnit =
      'IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID';
  static const String _metaTestInterstitialUnit =
      'VID_HD_9_16_39S_APP_INSTALL#YOUR_PLACEMENT_ID';

  /// The native placement id to request — a Meta test token in [metaTestMode],
  /// otherwise the real per-platform placement.
  static String get metaNativeUnit =>
      metaTestMode ? _metaTestNativeUnit : _metaNativeReal;

  /// The interstitial placement id to request — a Meta test token in
  /// [metaTestMode], otherwise the real per-platform placement.
  static String get metaInterstitialUnit =>
      metaTestMode ? _metaTestInterstitialUnit : _metaInterstitialReal;
}

import 'dart:io';

import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';

/// Central config for the app's ads — served entirely by **Meta (Facebook
/// Audience Network)**. Google AdMob is not used.
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

  // ══════════════════════════════════════════════════════════════════════
  //  GOOGLE ADMOB  (primary ad server; Meta Audience Network is mediated
  //  behind it in the AdMob dashboard — see docs/ads/ADMOB_MEDIATION_SETUP.md)
  // ══════════════════════════════════════════════════════════════════════
  // AdMob ids (app id + live units) come from the obfuscated `.env` (via [Env]),
  // split per platform — same pattern as the Meta placements. Google's official
  // TEST unit ids stay as literal constants below (they're public and identical
  // for everyone). Publisher: ca-app-pub-8886065788013100.

  /// Override: request LIVE AdMob units on EVERY build (even debug). Flip to
  /// `true` to see real ads without making a release build.
  ///
  /// ⚠️ Policy note: don't tap your own live ads (invalid-traffic strikes). If
  /// you just want to confirm delivery, register your device as an AdMob test
  /// device instead. Also: brand-new units often return Google "No fill (3)"
  /// for the first hours/days until the app is fully active — a blank slot then
  /// is expected, not a bug.
  static const bool forceLiveAds = false;

  /// TEST-ad mode for AdMob — TEST ads whenever NOT a release build, OR release
  /// with [useLiveAdsInRelease] off. [forceLiveAds] overrides both to live.
  static const bool admobTestMode =
      forceLiveAds ? false : (!kReleaseMode || !useLiveAdsInRelease);

  /// AdMob App ID (also hardcoded in AndroidManifest / Info.plist, per
  /// platform — the native SDK reads it from there, this is for Dart use).
  static String get admobAppId =>
      Platform.isIOS ? Env.admobAppIdIos : Env.admobAppIdAndroid;

  // Google's official TEST unit ids (always fill; safe on any device).
  static const String _admobTestNativeAndroid =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _admobTestInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _admobTestNativeIos =
      'ca-app-pub-3940256099942544/3986624511';
  static const String _admobTestInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  // Live unit ids come from `.env` (via [Env]), per platform.
  static String get _admobNativeAndroid => Env.admobNativeAndroid;
  static String get _admobInterstitialAndroid => Env.admobInterstitialAndroid;
  static String get _admobNativeIos => Env.admobNativeIos;
  static String get _admobInterstitialIos => Env.admobInterstitialIos;

  /// Native ad unit to request — Google test id in [admobTestMode], else live.
  static String get admobNativeUnit {
    if (Platform.isIOS) {
      return admobTestMode ? _admobTestNativeIos : _admobNativeIos;
    }
    return admobTestMode ? _admobTestNativeAndroid : _admobNativeAndroid;
  }

  /// Interstitial ad unit to request — Google test id in [admobTestMode], else
  /// live.
  static String get admobInterstitialUnit {
    if (Platform.isIOS) {
      return admobTestMode ? _admobTestInterstitialIos : _admobInterstitialIos;
    }
    return admobTestMode
        ? _admobTestInterstitialAndroid
        : _admobInterstitialAndroid;
  }
}

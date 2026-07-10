import 'dart:io';

import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';

/// Central config for the app's ads — served by **Google AdMob**.
///
///  • DEBUG / profile builds → [showAdsInDebug]
///        true  = show AdMob TEST ads
///        false = show NO ads (slots collapse, interstitials no-op)
///  • RELEASE / store builds → [useLiveAdsInRelease]
///        true  = show LIVE AdMob ads (real money)
///        false = show AdMob TEST ads (verify delivery on a signed build)
///
/// `kReleaseMode` is true only for release/store builds, so debug & profile fall
/// under the debug knob. DEBUG always uses TEST ads; only RELEASE can serve LIVE
/// ads, and only when [useLiveAdsInRelease] is true.
class AdConfig {
  AdConfig._();

  /// RELEASE knob: LIVE AdMob ads when `true`, AdMob TEST ads when `false`.
  /// Set `false` to verify ad delivery on a signed release build without
  /// serving real ads (keeps the AdMob account safe from invalid-traffic /
  /// policy strikes during release testing).
  static const bool useLiveAdsInRelease = true;

  /// DEBUG knob: show AdMob TEST ads when `true`, no ads at all when `false`.
  /// On so AdMob test ads render while debugging on-device.
  static const bool showAdsInDebug = true;

  /// Whether ads should load/show at all for the current build.
  /// RELEASE always runs ads; DEBUG/profile only when [showAdsInDebug] is true.
  static bool get adsEnabled => kReleaseMode || showAdsInDebug;

  // ══════════════════════════════════════════════════════════════════════
  //  GOOGLE ADMOB
  // ══════════════════════════════════════════════════════════════════════
  // AdMob ids (app id + live units) come from the obfuscated `.env` (via [Env]),
  // split per platform. Google's official TEST unit ids stay as literal
  // constants below (they're public and identical for everyone).
  // Publisher: ca-app-pub-8886065788013100.

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

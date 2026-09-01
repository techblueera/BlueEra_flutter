import 'dart:io';

import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';

/// Central config for the app's ads — served by **Google AdMob**.
///
///  • RELEASE / store builds → always show LIVE AdMob ads (real money).
///  • DEBUG / profile builds → [showAdsInDebug]
///        true  = show AdMob TEST ads
///        false = show NO ads (slots collapse, interstitials no-op)
///
/// `kReleaseMode` is true only for release/store builds, so debug & profile fall
/// under the debug knob.
class AdConfig {
  AdConfig._();

  /// DEBUG knob: show AdMob TEST ads when `true`, no ads at all when `false`.
  /// On so AdMob test ads render while debugging on-device.
  /// (Release always serves LIVE ads regardless of this flag.)
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

  /// TEST-ad mode for AdMob — TEST ads on any non-release build, LIVE ads on
  /// release. (Release always serves live units.)
  static const bool admobTestMode = !kReleaseMode;

  // NOTE: there is no `admobAppId` here any more. It read
  // `Env.admobAppIdAndroid` / `...Ios`, which `.env` has never defined — and
  // nothing in the app called it. The native SDK reads the app id from
  // AndroidManifest.xml / Info.plist, so Dart never needed one.

  // TEST unit ids, from `.env` (via [Env]), per platform. These are Google's
  // public test units — the same ids for every publisher — but they live in
  // `.env` alongside the live ones so both sets are managed in one place.
  static String get _admobTestNativeAndroid => Env.admobTestNativeAdUnitAndroid;
  static String get _admobTestInterstitialAndroid =>
      Env.admobTestInterstitialAdUnitAndroid;
  static String get _admobTestNativeIos => Env.admobTestNativeAdUnitIos;
  static String get _admobTestInterstitialIos =>
      Env.admobTestInterstitialAdUnitIos;

  // Live unit ids come from `.env` (via [Env]), per platform.
  static String get _admobNativeAndroid => Env.admobNativeAdUnitAndroid;
  static String get _admobInterstitialAndroid =>
      Env.admobInterstitialAdUnitAndroid;
  static String get _admobNativeIos => Env.admobNativeAdUnitIos;
  static String get _admobInterstitialIos => Env.admobInterstitialAdUnitIos;

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

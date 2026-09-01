import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true) // 🟢 obfuscate: true makes keys harder to hack
abstract class Env {
  @EnviedField(varName: 'GOOGLE_MAP_KEY')
  static String googleMapKey = _Env.googleMapKey;

  @EnviedField(varName: 'GEMINI_API_KEY')
  static String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(varName: 'PROJECT_FIREBASE_BASE_ID')
  static String projectFireBaseId = _Env.projectFireBaseId;

  @EnviedField(varName: 'ANDROID_FIREBASE_APP_ID')
  static String androidFirebaseAppId = _Env.androidFirebaseAppId;

  @EnviedField(varName: 'IOS_FIREBASE_APP_ID')
  static String iosFirebaseAppId = _Env.iosFirebaseAppId;

  @EnviedField(varName: 'ANDROID_FIREBASE_API_KEY')
  static String androidFirebaseAPIKey = _Env.androidFirebaseAPIKey;

  @EnviedField(varName: 'IOS_FIREBASE_API_KEY')
  static String iosFirebaseAPIKey = _Env.iosFirebaseAPIKey;

  @EnviedField(varName: 'MESSAGING_SENDER_ID')
  static String messagingSenderId = _Env.messagingSenderId;

  @EnviedField(varName: 'CHAT_SOCKET_URL')
  static String chatSocketUrl = _Env.chatSocketUrl;

  @EnviedField(varName: 'LIVE_TRACK_SOCKET')
  static String liveTrackSocket = _Env.liveTrackSocket;

  @EnviedField(varName: 'DEV_BASE_URL')
  static String devBaseUrl = _Env.devBaseUrl;

  @EnviedField(varName: 'PROD_BASE_URL')
  static String prodBaseUrl = _Env.prodBaseUrl;

  @EnviedField(varName: 'DEV_RAZORPAY_KEY')
  static String devRazorPayKey = _Env.devRazorPayKey;

  @EnviedField(varName: 'PROD_RAZORPAY_KEY')
  static String prodRazorPayKey = _Env.prodRazorPayKey;

  // ── Google AdMob ad-unit IDs — per platform, live + test ──
  //
  // The names here must match `.env` EXACTLY: envied resolves each field by its
  // `varName` at build time, and a name with no matching line in `.env` is a
  // hard build failure, not a null. These six used to read ADMOB_APP_ID_*,
  // ADMOB_NATIVE_* and ADMOB_INTERSTITIAL_*, none of which `.env` defines — so
  // `env.g.dart` (generated from the real key names) had no such members and
  // the whole tree stopped compiling on `_Env.admobAppIdAndroid`.
  //
  // There is deliberately NO app-id field. The AdMob app id is read by the
  // native SDK from AndroidManifest.xml / Info.plist; Dart never needs it, and
  // `.env` accordingly does not carry one.
  @EnviedField(varName: 'ADMOB_NATIVE_AD_UNIT_ANDROID')
  static String admobNativeAdUnitAndroid = _Env.admobNativeAdUnitAndroid;

  @EnviedField(varName: 'ADMOB_NATIVE_AD_UNIT_IOS')
  static String admobNativeAdUnitIos = _Env.admobNativeAdUnitIos;

  @EnviedField(varName: 'ADMOB_INTERSTITIAL_AD_UNIT_ANDROID')
  static String admobInterstitialAdUnitAndroid =
      _Env.admobInterstitialAdUnitAndroid;

  @EnviedField(varName: 'ADMOB_INTERSTITIAL_AD_UNIT_IOS')
  static String admobInterstitialAdUnitIos = _Env.admobInterstitialAdUnitIos;

  @EnviedField(varName: 'ADMOB_TEST_NATIVE_AD_UNIT_ANDROID')
  static String admobTestNativeAdUnitAndroid =
      _Env.admobTestNativeAdUnitAndroid;

  @EnviedField(varName: 'ADMOB_TEST_NATIVE_AD_UNIT_IOS')
  static String admobTestNativeAdUnitIos = _Env.admobTestNativeAdUnitIos;

  @EnviedField(varName: 'ADMOB_TEST_INTERSTITIAL_AD_UNIT_ANDROID')
  static String admobTestInterstitialAdUnitAndroid =
      _Env.admobTestInterstitialAdUnitAndroid;

  @EnviedField(varName: 'ADMOB_TEST_INTERSTITIAL_AD_UNIT_IOS')
  static String admobTestInterstitialAdUnitIos =
      _Env.admobTestInterstitialAdUnitIos;
}
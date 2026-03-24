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
}
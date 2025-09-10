import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

String? baseUrl, razorpayKey,  chatSocketUrl, androidNativeAdUnitId, iosNativeAdUnitId, androidRewardedAdUnitId, androidInterstitialAdUnitId, iosInterstitialAdUnitId;
bool isProdEnvironment = false;
String blueEraPostLink = "BlueEraPostLink";

///THIS RECORD IS SAME FOR ANDROID AND IOS...
String firebaseAppId = Platform.isAndroid
    ? "1:725685070061:android:877400b3bc1273c4ae04e4"
    : Platform.isIOS
        ? "1:725685070061:ios:fd35fe5627c25861ae04e4"
        : "";
String messagingSenderId = "725685070061";
String projectFireBaseId = "blueera-50c05";
String androidFirebaseAPIKey = "AIzaSyCnwQv2WIfK4YsVBGMNpyVZyveBHOw1Z0A";
String iosFirebaseAPIKey = "AIzaSyAgLweZj0Brbx2WkGcLTbU-LFYPD3AqGcc";

///New Key
String googleMapKey = "AIzaSyDdU2Ji6dCQ4Hq0TbLHILxMsdR-M27Ie2g";

String googleAutocomplete =
    "https://maps.googleapis.com/maps/api/place/autocomplete/json";
String googlePlaceId =
    "https://maps.googleapis.com/maps/api/place/details/json";
String googleGeoCode =
    "https://maps.googleapis.com/maps/api/geocode/json";
String googleCountryCode = "&language=en&components=country:IN";

// String privacyLink = "https://doc-hosting.flycricket.io/blueera-privacy-policy/63a9d073-d49c-46a4-a5e3-e7c3647a0756/privacy";
// String tncLink = "https://doc-hosting.flycricket.io/blueera-terms-of-use/adab0d47-85cd-4d63-9494-4c23d34ecbbf/terms";

String privacyLink =
    "https://www.freeprivacypolicy.com/live/f1d1be8d-4563-43e0-9275-c439f46390ad";
String tncLink =
    "https://www.freeprivacypolicy.com/live/2c1f2002-02e5-4acc-8142-e371734c9d9c";

Future<void> projectKeys({required String environmentType}) async {
  if (environmentType == AppConstants.prod) {
    isProdEnvironment = true;
    baseUrl = "https://api.blueera.ai/api/";
    razorpayKey = "rzp_live_Z3hqjlIs4IEKya";
    androidNativeAdUnitId = 'ca-app-pub-4151367085462604/2589840945'; // native adUnit Id for android
    androidRewardedAdUnitId = 'ca-app-pub-4151367085462604/5476692884';
    androidInterstitialAdUnitId = 'ca-app-pub-4151367085462604/9740221584';
    chatSocketUrl = 'http://15.207.121.239:3000/';
    iosNativeAdUnitId = 'ca-app-pub-4151367085462604/4295806298';
    iosInterstitialAdUnitId = 'ca-app-pub-4151367085462604/6615650203';
  } else if (environmentType == AppConstants.dev) {
    isProdEnvironment = false;
    baseUrl = "https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/";
    razorpayKey = "rzp_test_SxJzWVt7su8vd7";
    androidNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
    androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
    androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
    iosNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';
    chatSocketUrl = 'http://15.207.121.239:3000/';
    iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  } else if (environmentType == AppConstants.qa) {
    isProdEnvironment = false;
    baseUrl = "https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/";
    razorpayKey = "rzp_test_SxJzWVt7su8vd7";
  }

  await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);
}

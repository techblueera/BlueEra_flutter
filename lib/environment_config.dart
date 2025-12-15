import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

String? baseUrl, razorpayKey,  chatSocketUrl;
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


String privacyLink =
    "https://www.freeprivacypolicy.com/live/f1d1be8d-4563-43e0-9275-c439f46390ad";
String tncLink =
    "https://www.freeprivacypolicy.com/live/2c1f2002-02e5-4acc-8142-e371734c9d9c";

Future<void> projectKeys({required String environmentType}) async {
  if (environmentType == AppConstants.prod) {
    isProdEnvironment = true;
    baseUrl = "https://be.blueera.ai/api/";
    razorpayKey = "rzp_test_ohzYMNmUvD1Vxg";
    // razorpayKey = "rzp_live_RYv0tzupV710iQ";
    chatSocketUrl = 'wss://chat.blueera.ai';
  } else if (environmentType == AppConstants.dev) {
    isProdEnvironment = false;
    baseUrl = "https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/";
    razorpayKey = "rzp_test_ohzYMNmUvD1Vxg";
    // razorpayKey = "rzp_live_RYv0tzupV710iQ";
    chatSocketUrl = 'wss://chat.blueera.ai';
  } else if (environmentType == AppConstants.qa) {
    isProdEnvironment = false;
    baseUrl = "https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/";
    razorpayKey = "rzp_test_ohzYMNmUvD1Vxg";
    // razorpayKey = "rzp_live_RYv0tzupV710iQ";
  }

  await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);
}

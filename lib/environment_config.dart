import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';

String? baseUrl, razorpayKey,  chatSocketUrl, liveTrackSocket;
bool isProdEnvironment = false;
String blueEraPostLink = "BlueEraPostLink";


///THIS RECORD IS SAME FOR ANDROID AND IOS...
String firebaseAppId = Platform.isAndroid
    ? Env.androidFirebaseAppId
    : Platform.isIOS
    ? Env.iosFirebaseAppId
    : "";
String messagingSenderId = Env.messagingSenderId;
String projectFireBaseId = Env.projectFireBaseId;
String firebaseApiKey = Platform.isAndroid
    ? Env.androidFirebaseAPIKey
    : Platform.isIOS
    ? Env.iosFirebaseAPIKey
    : "";
String googleMapKey = Env.googleMapKey;
String geminiApiKey = Env.geminiApiKey;

String googleAutocomplete =
    "https://maps.googleapis.com/maps/api/place/autocomplete/json";
String googlePlaceId =
    "https://maps.googleapis.com/maps/api/place/details/json";
String googleGeoCode =
    "https://maps.googleapis.com/maps/api/geocode/json";
String googleCountryCode = "&language=en&components=country:IN";

String takeFranchise ="https://bluecs.in/partner";
String privacyLink =
    "https://www.freeprivacypolicy.com/live/f1d1be8d-4563-43e0-9275-c439f46390ad";
String tncLink =
    "https://www.freeprivacypolicy.com/live/2c1f2002-02e5-4acc-8142-e371734c9d9c";

Future<void> projectKeys({required String environmentType}) async {
  if (environmentType == AppConstants.prod) {
    isProdEnvironment = true;
    baseUrl = Env.prodBaseUrl;
    if(kDebugMode){
      razorpayKey = Env.devRazorPayKey;
    }else{
      razorpayKey = Env.prodRazorPayKey;
    }
    chatSocketUrl = Env.chatSocketUrl;
    liveTrackSocket = Env.liveTrackSocket;
  } else if (environmentType == AppConstants.dev) {
    isProdEnvironment = false;
    baseUrl = Env.devBaseUrl;
    razorpayKey = Env.devRazorPayKey;
    chatSocketUrl = Env.chatSocketUrl;
    liveTrackSocket = Env.liveTrackSocket;
  } else if (environmentType == AppConstants.qa) {
    isProdEnvironment = false;
    baseUrl = Env.devBaseUrl;
    razorpayKey = Env.devRazorPayKey;
    chatSocketUrl = Env.chatSocketUrl;
    liveTrackSocket = Env.liveTrackSocket;
    // razorpayKey = "rzp_live_RYv0tzupV710iQ";
  }

  // print('--- 📊 Environment Assignment Results ---');
  // print('Base URL: ${baseUrl ?? "❌ NULL"}');
  // print('Razorpay Key: ${razorpayKey ?? "❌ NULL"}');
  // print('Chat Socket: ${chatSocketUrl ?? "❌ NULL"}');
  // print('Live Track Socket: ${liveTrackSocket ?? "❌ NULL"}');

  await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);
}

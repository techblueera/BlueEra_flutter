import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/env.dart';
import 'package:flutter/foundation.dart';

String? baseUrl, razorpayKey, chatSocketUrl, liveTrackSocket, callBaseUrl;
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
String pinCodeUrl(String pinCode) => "https://api.postalpincode.in/pincode/$pinCode";

String takeFranchise ="https://bluecs.in/partner";
String privacyLink =
    "https://www.freeprivacypolicy.com/live/f1d1be8d-4563-43e0-9275-c439f46390ad";
String tncLink =
    "https://www.freeprivacypolicy.com/live/2c1f2002-02e5-4acc-8142-e371734c9d9c";
String bdoTncLink =
    "https://bluecs.in/bdotc";

Future<void> projectKeys({required String environmentType}) async {
  if (environmentType == AppConstants.prod) {
    isProdEnvironment = true;
    baseUrl = Env.prodBaseUrl;
    if(kDebugMode) {
      razorpayKey = Env.devRazorPayKey;
    }else{
      razorpayKey = Env.prodRazorPayKey;
    }
    chatSocketUrl = Env.chatSocketUrl;
    liveTrackSocket = Env.liveTrackSocket;
    callBaseUrl = "https://call.blueera.ai/";
  } else if (environmentType == AppConstants.dev) {
    isProdEnvironment = false;
    baseUrl = Env.devBaseUrl;
    razorpayKey = Env.devRazorPayKey;
    chatSocketUrl = Env.chatSocketUrl;
    liveTrackSocket = Env.liveTrackSocket;
    callBaseUrl = "https://call.blueera.ai/";
  } else if (environmentType == AppConstants.qa) {
    isProdEnvironment = false;
    baseUrl = Env.devBaseUrl;
    razorpayKey = Env.devRazorPayKey;
    chatSocketUrl = Env.chatSocketUrl;
    liveTrackSocket = Env.liveTrackSocket;
    callBaseUrl = "https://call.blueera.ai/";
    // razorpayKey = "rzp_live_RYv0tzupV710iQ";
  }
  await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);
}

// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZXNzaW9uSWQiOiI2OWM2NjhmMGI2OWQ3YzJhMzU5ODg2NjUiLCJfaWQiOnsiX2lkIjoiNjljNjY4ZjAyYjRmMTc5MTJmYTA0NjA4IiwiaWQiOiI2OWM2NjhmMDJiNGYxNzkxMmZhMDQ2MDgiLCJhY2NvdW50X3R5cGUiOiJHVUVTVCIsImNvbnRhY3Rfbm8iOiIwMDUyMDAwMDAwIiwiYnVzaW5lc3NfaWQiOm51bGwsIm5hbWUiOiJHdWVzdDAwMDAiLCJwcm9maWxlX2ltYWdlIjoiIn0sImlhdCI6MTc3NDYxMDY3MiwiZXhwIjoxNzkwMTYyNjcyfQ.TzAByiQ34ODff8UwFnf8EkPVGzKP6Xyf_0vO3H1PdA0

// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOnsiX2lkIjoiNjljNjY4ZjAyYjRmMTc5MTJmYTA0NjA4IiwiY29udGFjdF9ubyI6IjAwNTIwMDAwMDAiLCJhY2NvdW50X3R5cGUiOiJCVVNJTkVTUyIsImJ1c2luZXNzIjoiNjljNjY5OTcyYjRmMTc5MTJmYTA0ZDEyIn0sImlhdCI6MTc3NDYxMDgzOSwiZXhwIjoxNzc1MDQyODM5fQ.mbOalUqMnad6YpHpZw4CAZ7IcWCSHg0ulk3WhQOLGG4
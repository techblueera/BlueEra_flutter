
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? appVersion = '';
String? authTokenGlobal = '';
String accountTypeGlobal = '';
// String dobDoi = '';
String userNameGlobal = '';
String userProfessionGlobal = '';
String userDesignationGlobal = '';
String userId = '';
String businessId = '';
String userMobileGlobal = '';
String isUserLoginGlobal = '';
String has_reel_profile_status = 'false';
String reel_profile_id_global = '';

String userProfileGlobal = '';
// String userProfile_global = '';
String channelId = '';
String channelName = '';
String channelOwner = '';

String businessNameGlobal = '';
String businessOwnerNameGlobal = '';
String userNameAtGlobal = '';
String businessOwnerAddressGlobal = '';
String businessCategoryGlobal = '';
String businessSubCategoryGlobal = '';
String serviceProviderStatusGlobal = '';
String earnServiceCreatedStatusGlobal = 'false';
String businessTypeGlobal = '';

// String isRiderServiceOpt = '';
// String isEarnServiceOpt = '';

String schoolIDGlobal = '';
String otherServiceIDGlobal = '';
String hotelIDGlobal = '';
String labIDGlobal = '';
String hospitalIDGlobal = '';
String deviceOsVersionGlobal = '';
String userProfileTypeGlobal = '';
// String schoolIDGlobal = '6954c5337ca7a9670dc99129';
String productBusinessProfileIDGlobal = '';

class SharedPreferenceUtils {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
        synchronizable: false,
      ));

  ///STORE...
  static const baseURL = "baseURL";
  static const authToken = "authToken";
  static const loginType = 'loginType';
  static const isUserLogin = 'isUserLogin';
  static const loginUserId = 'userId';
  static const userBusinessId = 'businessId';
  static const accountType = 'accountType';
  static const userName = 'userName';
  static const userLoginMobile = 'userMobile';
  static const userProfile = 'userProfile';
  static const has_reel_profile = 'has_reel_profile';
  static const reel_profile_id = 'reel_profile_id';
  static const saved_contacts = 'saved_contacts';
  /// Set to "true" after the first-install full chat export has been
  /// pulled and hydrated into local storage. Guards re-running the
  /// /chat/export-all API on every subsequent app open.
  static const hasInitialChatExport = 'has_initial_chat_export';
  static const channel_Id = 'channel_id';
  static const alreadyRetried = 'alreadyRetried';
  static const lastVersion = 'last_version';
  static const lastGreetingCallKey = 'last_greeting_call_key';
  static const userProfileType = 'user_profile_type';
  static const userProfession = 'user_profession';
  static const userDesignation = 'userDesignation';
  static const businessName = 'business_name';
  static const businessOwnerName = 'business_owner_name';
  static const userNameAtKey = 'userNameAt';
  static const disableGreetingCardKey = 'disableGreetingCardKey';
  static const channelName = 'channelName';
  static const channelOwner = 'channelOwner';
  static const businessOwnerAddress = 'businessOwnerAddress';
  static const availabilityDetails = 'availabilityDetails';
  static const businessCategory = 'businessCategory';
  static const businessSubCategory = 'businessSubCategory';
  static const serviceProviderStatus = 'serviceProviderStatus';
  static const earnServiceCreatedStatusKey = 'earnServiceCreatedStatusKey';
  static const userServiceExistsKey = 'userServiceExistsKey';
  static const businessType = 'businessType';
  static const notificationDeviceToken = 'notificationDeviceToken';
  static const schoolIDKey = 'schoolIDKey';
  static const hotelIDKey = 'hotelIDKey';
  static const labIDKey = 'labIDKey';
  static const hospitalIDKey = 'hospitalIDKey';
  static const otherServiceIDKey = 'otherServiceIDKey';
  static const productBusinessProfileIDIDKey = 'productBusinessProfileIDIDKey';
  static const hasSelectedLanguage = 'hasSelectedLanguage';

  static Future<void> userLoggedInIndividualGuest({
    required String loginUserId_,
    required String businesId,
    required String contactNo,
    required String getUserName,
    required String profileImage,
    required String profileType,
    required String profession,
    required String designation,
    required String userNameAt,
  }) async {
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    await SharedPreferenceUtils.setSecureValue(loginUserId, loginUserId_);
    await SharedPreferenceUtils.setSecureValue(userLoginMobile, contactNo);
    await SharedPreferenceUtils.setSecureValue(userName, getUserName);
    await SharedPreferenceUtils.setSecureValue(userProfile, profileImage);
    await SharedPreferenceUtils.setSecureValue(userProfileType, profileType);
    await SharedPreferenceUtils.setSecureValue(userProfession, profession);
    await SharedPreferenceUtils.setSecureValue(userDesignation, designation);
    await SharedPreferenceUtils.setSecureValue(userBusinessId, businesId);
    await SharedPreferenceUtils.setSecureValue(userNameAtKey, userNameAt);

    userProfileGlobal = profileImage;
    precacheImage(
      NetworkImage(userProfileGlobal),
      Get.context!,
    );
  }

  static Future<void> guestUserLoggedIn({
    required String loginUserId_,
    required String contactNo,
    required String autToken,
    required String getUserName,
  }) async {
    await SharedPreferenceUtils.setSecureValue(loginUserId, loginUserId_);
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    await SharedPreferenceUtils.setSecureValue(userLoginMobile, contactNo);
    await SharedPreferenceUtils.setSecureValue(authToken, autToken);
    await SharedPreferenceUtils.setSecureValue(userName, getUserName);
  }

  static Future<void> userLoggedInBusiness({
    required String email,
    required String profileImage,
    required String businessName,
    required String businessOwnerName,
    required String businessId,
    required String loginBusinessUserId,
    required String userNameAt,
    required String businessAddress,
    required String categoryOfBusiness,
    required String subCategoryOfBusiness,
    required String typeOfBusiness,
  }) async {
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    // await SharedPreferenceUtils.setSecureValue(
    //     userLoginMobile, email);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.userBusinessId, businessId);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.userProfile, profileImage);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.businessName, businessName);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.businessOwnerName, businessOwnerName);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.loginUserId, loginBusinessUserId);
    await SharedPreferenceUtils.setSecureValue(userNameAtKey, userNameAt);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.businessOwnerAddress, businessAddress);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.businessCategory, categoryOfBusiness);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.businessSubCategory, subCategoryOfBusiness);
    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.businessType, typeOfBusiness);

    userProfileGlobal = profileImage;
    precacheImage(
      NetworkImage(userProfileGlobal),
      Get.context!,
    );
  }

  /// Store the refresh token securely
  ///SET STORAGE VALUE...
  static Future<void> setBaseUrlSecureValue(
      dynamic sharedPreferencesValue) async {
    await _secureStorage.write(key: baseURL, value: sharedPreferencesValue);
  }

  ///GET STORAGE VALUE...
  static Future getBaseUrlSecureValue() async {
    return _secureStorage.read(key: baseURL);
  }

  ///SET STORAGE VALUE...
  static Future<void> setSecureValue(
      String sharedPreferencesKey, dynamic sharedPreferencesValue) async {
    await _secureStorage.write(
        key: sharedPreferencesKey, value: sharedPreferencesValue);
  }

  ///GET STORAGE VALUE...
  static Future getSecureValue(String sharedPreferencesKey) async {
    return _secureStorage.read(key: sharedPreferencesKey);
  }

  static Future<String?> getBookingAvailabilityDetail() async {
    return await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.availabilityDetails);
  }

  ///CLEAR DATA...
  static Future<void> clearPreference() async {
    try {
      await FirebaseMessaging.instance.deleteToken();

      final workManagerBaseUrl =
          await SharedPreferenceUtils.getBaseUrlSecureValue();
      await _secureStorage.deleteAll();
      // await _secureStorage.isCupertinoProtectedDataAvailable();
      Get.delete<SchoolAboutUsController>();
      Get.delete<SchoolController>();
      Get.delete<BusinessProfileFullController>();
      Get.delete<ViewBusinessDetailsController>();
      Get.delete<RestaurantController>();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("last_dialog_shown");
      lastHomeFetchTime = null;
      // Re-init localization Hive box after logout clears disk
      await LocalizationService().init();
      authTokenGlobal = '';
      accountTypeGlobal = '';
      userId = '';
      businessId = '';
      userMobileGlobal = '';
      isUserLoginGlobal = '';
      has_reel_profile_status = 'false';
      reel_profile_id_global = '';
      userNameGlobal = '';
      userProfileGlobal = '';
      channelId = '';
      userProfileTypeGlobal = '';
      userProfessionGlobal = '';
      userDesignationGlobal = '';
      userNameAtGlobal = '';
      serviceProviderStatusGlobal = '';
      earnServiceCreatedStatusGlobal = '"false"';
      businessTypeGlobal = '';
      businessCategoryGlobal = '';
      businessSubCategoryGlobal = '';
      schoolIDGlobal = '';
      hotelIDGlobal = '';
      labIDGlobal = '';
      hospitalIDGlobal = '';
      otherServiceIDGlobal = '';
      productBusinessProfileIDGlobal = '';
      Get.find<AuthController>().imgPath.value = "";
      await SharedPreferenceUtils.setBaseUrlSecureValue(workManagerBaseUrl);
      AppNotificationHandler.getFcmToken();
      await resetLanguageLocalization();
    } on Exception {
      await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);
    }
  }
}

resetLanguageLocalization() async {
  // 1️⃣ Ensure box is opened properly
  final box = await Hive.openBox('translations');

  // 2️⃣ Delete all data
  await box.clear();

  // 3️⃣ Also clear in-memory translations (important!)
  final localizationService = LocalizationService();
  localizationService.clearInMemoryTranslations();

  // 4️⃣ Reset GetX localization system
  Get.clearTranslations();

  // 5️⃣ Optionally set app back to English
  await localizationService.updateLanguage("en");

  print("✅ Language localization fully reset.");
}

///LOGIN USER STATUS...
getUserLoginStatus() async {
  isUserLoginGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.isUserLogin) ??
      "false";
}

getUserLoginBusinessId() async {
  businessId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userBusinessId) ??
      "";
}

getUserLoginAccountType() async {
  accountTypeGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.accountType) ??
      "";
}

getUserAuthToken() async {
  authTokenGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.authToken);
}

getMobileNo() async {
  userMobileGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userLoginMobile) ??
      "";
}

getServiceProviderStatusUtils() async {
  serviceProviderStatusGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.serviceProviderStatus) ??
      "";
}

getEarnServiceCreatedStatusUtils() async {
  earnServiceCreatedStatusGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.earnServiceCreatedStatusKey) ??
      "false";
}

Future<String> getUserServiceExistsKey() async {
  return await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userServiceExistsKey) ??
      'false';
}

// Future<String> getBusinessType() async {
//   return await SharedPreferenceUtils.getSecureValue(
//       SharedPreferenceUtils.businessType) ??
//       BusinessType.Product.name;
// }

///GET USER DATA....
getUserLoginData() async {
  authTokenGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.authToken);
  accountTypeGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.accountType) ??
      '';

  // userName = await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userName) ?? "";
  userId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.loginUserId) ??
      "";
  businessId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userBusinessId) ??
      "";
  userMobileGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userLoginMobile) ??
      "";

  userProfileGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userProfile) ??
      "";

  userNameGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userName) ??
      "";
  userProfileTypeGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userProfileType) ??
      "";
  userProfessionGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userProfession) ??
      "";
  userDesignationGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userDesignation) ??
      "";
  Get.find<AuthController>().imgPath.value = userProfileGlobal;
  has_reel_profile_status = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.has_reel_profile) ??
      "false";

  businessNameGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.businessName) ??
      "";

  businessOwnerNameGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.businessOwnerName) ??
      "";

  businessOwnerAddressGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.businessOwnerAddress) ??
      "";

  userNameAtGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userNameAtKey) ??
      "";

  businessCategoryGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.businessCategory) ??
      "";

  businessSubCategoryGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.businessSubCategory) ??
      "";

  businessTypeGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.businessType) ??
      "OTHER";
}

///GET USER DATA....
getGuestUserLoginData() async {
  userId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.loginUserId) ??
      "";
  businessId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userBusinessId) ??
      "";
  authTokenGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.authToken);
  accountTypeGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.accountType) ??
      '';

  userMobileGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userLoginMobile) ??
      "";

  userNameGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userName) ??
      "";
}

/// GET CHANNEL DATA...
getChannelData() async {
  channelId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.channel_Id) ??
      "";
  channelName = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.channelName) ??
      "";
  channelOwner = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.channelOwner) ??
      "";
}

Future<void> clearSecureStorageIfFreshInstall() async {
  final prefs = await SharedPreferences.getInstance();

  final hasInstalledBefore = prefs.getBool('hasInstalledBefore') ?? false;

  if (!hasInstalledBefore) {
    // Fresh install detected
    await SharedPreferenceUtils.clearPreference();

    // await _storage.deleteAll(); // Clears Keychain entries
    await prefs.setBool('hasInstalledBefore', true);
  }
}

///SET SCHOOL ID....
setSchoolID(String schoolIDValue) {
  SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.schoolIDKey, schoolIDValue.toString());
}

getSchoolID() async {
  schoolIDGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.schoolIDKey);
}

///SET OTHER SERVICE ID....
setOtherServiceID(String serviceIDValue) {
  SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.otherServiceIDKey, serviceIDValue.toString());
}

getOtherServiceID() async {
  otherServiceIDGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.otherServiceIDKey);
}

///SET PRODUCT PROFILE ID....
setProductBusinessProfileID(String productBusinessIDValue) {
  SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.productBusinessProfileIDIDKey,
      productBusinessIDValue.toString());
}

getProductBusinessProfileID() async {
  productBusinessProfileIDGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.productBusinessProfileIDIDKey);
}

///SET HOTEL ID....
setHotelID(String schoolIDValue) {
  SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.hotelIDKey, schoolIDValue.toString());
}

getHotelID() async {
  hotelIDGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.hotelIDKey);
}

///SET LAB ID....
setLabID(String labIDValue) {
  SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.labIDKey, labIDValue.toString());
}

getLabID() async {
  try {
    labIDGlobal = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.labIDKey);
  } on Exception {
    // TODO
  }
}

///SET HOSPITAL ID....
setHospitalID(String labIDValue) {
  SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.hospitalIDKey, labIDValue.toString());
}

Future<String> getHospitalID() async {
  try {
    hospitalIDGlobal = await SharedPreferenceUtils.getSecureValue(
            SharedPreferenceUtils.hospitalIDKey) ??
        "";
  } on Exception {
    hospitalIDGlobal = "";
  }
  return hospitalIDGlobal;
}

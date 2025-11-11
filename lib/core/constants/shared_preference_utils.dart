import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
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
String userWorkTypeGlobal = '';
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
String businessSubCategoryGlobal = '';
String serviceProviderStatusGlobal = '';
String userServiceCreatedStatusGlobal = '';
String businessTypeGlobal = '';

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
  static const channel_Id = 'channel_id';
  static const alreadyRetried = 'alreadyRetried';
  static const lastVersion = 'last_version';
  static const lastGreetingCallKey = 'last_greeting_call_key';
  static const userProfession = 'user_profession';
  static const workTypeKey = 'workTypeKey';
  static const businessName = 'business_name';
  static const businessOwnerName = 'business_owner_name';
  static const userNameAtKey = 'userNameAt';
  static const disableGreetingCardKey = 'disableGreetingCardKey';
  static const channelName = 'channelName';
  static const channelOwner = 'channelOwner';
  static const businessOwnerAddress = 'businessOwnerAddress';
  static const availabilityDetails = 'availabilityDetails';
  static const businessSubCategory = 'businessSubCategory';
  static const serviceProviderStatus = 'serviceProviderStatus';
  static const userServiceCreatedStatusKey = 'userServiceCreatedStatusKey';
  static const userServiceExistsKey = 'userServiceExistsKey';
  static const businessType = 'businessType';
  static const notificationDeviceToken = 'notificationDeviceToken';

  static Future<void> userLoggedInIndividualGuest({
    required String loginUserId_,
    required String businesId,
    required String contactNo,
    required String getUserName,
    required String profileImage,
    required String designation,
    required String workType,
    required String userNameAt,
  }) async {
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    await SharedPreferenceUtils.setSecureValue(loginUserId, loginUserId_);
    await SharedPreferenceUtils.setSecureValue(userLoginMobile, contactNo);
    await SharedPreferenceUtils.setSecureValue(userName, getUserName);
    await SharedPreferenceUtils.setSecureValue(userProfile, profileImage);
    await SharedPreferenceUtils.setSecureValue(userProfession, designation);
    await SharedPreferenceUtils.setSecureValue(workTypeKey, workType);
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
    required String profileImage,
    required String businessName,
    required String businessOwnerName,
    required String businessId,
    required String loginBusinessUserId,
    required String userNameAt,
    required String businessAddress,
    required String subCategoryOfBusiness,
    required String typeOfBusiness,
  }) async {
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
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
      userProfessionGlobal = '';
      userWorkTypeGlobal = '';
      userNameAtGlobal = '';
      serviceProviderStatusGlobal = '';
      userServiceCreatedStatusGlobal = '';
      businessTypeGlobal = '';
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

getUserServiceCreatedStatusUtils() async {
  userServiceCreatedStatusGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userServiceCreatedStatusKey) ??
      "";
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

  userProfessionGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userProfession) ??
      "";
  userWorkTypeGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.workTypeKey) ??
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

import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

String? appVersion = '';
String? authTokenGlobal = '';
String accountTypeGlobal = '';
// String dobDoi = '';
String userNameGlobal = '';
String userProfessionGlobal = '';
String userId = '';
String businessId = '';
String userMobileGlobal = '';
String isUserLoginGlobal = '';
String has_reel_profile_status = 'false';
String reel_profile_id_global = '';

String userProfileGlobal = '';
// String userProfile_global = '';
String channelId = '';

String businessNameGlobal = '';
String businessOwnerNameGlobal = '';

class SharedPreferenceUtils {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions( accessibility: KeychainAccessibility.first_unlock,
        synchronizable: false,));

  ///STORE...
  static const baseURL = "baseURL";
  static const authToken = "authToken";
  static const loginType = 'loginType';
  static const isUserLogin = 'isUserLogin';
  static const loginUserId = 'userId';
  static const userBusinessId = 'businessId';
  static const accountType = 'accountType';
  static const isRegister = 'isRegister';
  static const dobDoi = 'dobDoi';
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
  static const businessName = 'user_profession';
  static const businessOwnerName = 'user_profession';

  static Future<void>   userLoggedIn({
    required String loginUserId_,
    required String businesId,
    required String contactNo,
    required String autToken,
    required String getUserName,
    required String profileImage,
    required String designation,
  }) async {
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    await SharedPreferenceUtils.setSecureValue(loginUserId, loginUserId_);
    await SharedPreferenceUtils.setSecureValue(userBusinessId, businesId);
    await SharedPreferenceUtils.setSecureValue(userLoginMobile, contactNo);
    await SharedPreferenceUtils.setSecureValue(authToken, autToken);
    await SharedPreferenceUtils.setSecureValue(userName, getUserName);
    await SharedPreferenceUtils.setSecureValue(userProfile, profileImage);
    await SharedPreferenceUtils.setSecureValue(userProfession, designation);
  }
  static Future<void> userLoggedInIndivisualGuest({
    required String loginUserId_,
    required String businesId,
    required String contactNo,
    required String getUserName,
    required String profileImage,
    required String designation,

  }) async {
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    await SharedPreferenceUtils.setSecureValue(loginUserId, loginUserId_);
    await SharedPreferenceUtils.setSecureValue(userLoginMobile, contactNo);
    await SharedPreferenceUtils.setSecureValue(userName, getUserName);
    await SharedPreferenceUtils.setSecureValue(userProfile, profileImage);
    await SharedPreferenceUtils.setSecureValue(userProfession, designation);
    await SharedPreferenceUtils.setSecureValue(userBusinessId, businesId);

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

  ///CLEAR DATA...
  static Future<void> clearPreference() async {
    try {
      final workManagerBaseUrl =
          await SharedPreferenceUtils.getBaseUrlSecureValue();
      await _secureStorage.deleteAll();
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
      Get.find<AuthController>().imgPath.value="";
      await SharedPreferenceUtils.setBaseUrlSecureValue(workManagerBaseUrl);
    } on Exception catch (e) {
      await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);

      // TODO
    }
  }
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
getMobileNo()
async {
  userMobileGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.userLoginMobile) ??
      "";
}
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

  Get.find<AuthController>().imgPath.value = userProfileGlobal;
  has_reel_profile_status = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.has_reel_profile) ??
      "false";
  // if (has_reel_profile_status == "true") {
  //   reel_profile_id_global = await SharedPreferenceUtils.getSecureValue(
  //           SharedPreferenceUtils.reel_profile_id) ??
  //       "";
  // }
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

/// GET CHANNEL ID...
getChannelId() async {
  channelId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.channel_Id) ??
      "";
}

/// GET Business Data...
getBusinessData() async {
  businessNameGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.businessName) ??
      "";
  businessOwnerNameGlobal = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.businessOwnerName) ??
      "";
}


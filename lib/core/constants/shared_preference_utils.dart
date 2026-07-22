
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
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

/// In-memory guard so the Discover share-promo dialog shows at most once per app
/// session (the once-per-DAY rule is the persisted `sharePromoLastShownKey`).
/// Reset on logout (see [SharedPreferenceUtils.clearPreferenceDataOnly]) so a
/// fresh login re-shows the promo instead of a stale session flag hiding it.
bool sharePromoShownThisSession = false;

/// Local `yyyy-MM-dd` the merchant add-product prompt last displayed, mirroring
/// the persisted `addProductPromptLastShownKey`.
///
/// The persisted key is the real once-a-day gate; this mirrors it in memory so
/// two mounts in the same frame can't both slip through before the async
/// secure-storage write lands. Keyed by DAY rather than a bool so a session
/// left running across midnight still gets the next day's prompt. Only set when
/// the sheet actually opens — a skipped visit must not burn the day. Reset on
/// logout (see [SharedPreferenceUtils.clearPreferenceDataOnly]).
String? addProductPromptShownForDay;

/// Suppresses the once-a-day promo pops (Discover share-promo sheet, business
/// QR promo sheet) for the rest of THIS session after a fresh account was just
/// created (individual or business — see `addIndividualUser` / `addBusinessUser`
/// in AuthController).
///
/// Account creation navigates to the Discover tab and immediately pushes an
/// "update your data" screen on top; without this guard the Discover mount would
/// pop the share-promo sheet behind that onboarding screen — irritating right
/// when the user is being asked to fill in their profile. Reset on logout (see
/// [SharedPreferenceUtils.clearPreferenceDataOnly]) so the next account/session
/// behaves normally.
bool suppressPromosAfterAccountCreation = false;

/// Local `yyyy-MM-dd` the business-profile QR promo sheet last displayed,
/// mirroring the persisted `qrPromoLastShownKey`.
///
/// Same reasoning as [addProductPromptShownForDay]: the persisted key is the
/// real once-a-day gate; this mirrors it in memory so two mounts in the same
/// frame can't both slip through before the async secure-storage write lands.
/// Keyed by DAY so a session left running across midnight gets the next day's
/// sheet. Only set when the sheet actually opens. Reset on logout (see
/// [SharedPreferenceUtils.clearPreferenceDataOnly]).
String? qrPromoShownForDay;

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
  // Per-business local flag: has this grocery seller set their shop
  // availability at least once? Drives the "set availability" reminder
  // shown on the grocery admin home. Composed with the businessId.
  static const groceryAvailabilitySetPrefix = 'grocery_availability_set_';
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

  /// Referral code captured from a `?referralCode=…` deeplink before
  /// the user signed up. Stored here so the onboarding flow (personal
  /// or business) can pick it up silently and skip the manual
  /// promo-code dialog. Cleared after onboarding consumes it.
  static const deferredReferralCodeKey = 'deferred_referral_code';

  /// One-shot guard so the Google Play install referrer is queried only
  /// once per install. Set after the first successful query so a referral
  /// code already consumed (and cleared) by onboarding can't be revived
  /// from the unchanging install referrer on a later launch.
  static const installReferrerCheckedKey = 'install_referrer_checked';

  /// `yyyy-MM-dd` of the last day the Discover share-profile promo dialog
  /// was shown, so it pops at most once per calendar day (not on every
  /// Discover mount).
  static const sharePromoLastShownKey = 'share_promo_last_shown';

  /// Local `yyyy-MM-dd` the merchant add-product prompt was last shown, so it
  /// pops at most once per calendar day across the me-section admin homes
  /// (grocery, food, product, manufacturer, automotive, medical). One shared
  /// key, not one per service — an account has a single business category, so
  /// it only ever lands on one of those screens.
  static const addProductPromptLastShownKey = 'add_product_prompt_last_shown';

  /// `yyyy-MM-dd` of the last day the business-profile QR promo sheet was
  /// shown, so it pops at most once per calendar day (not on every profile
  /// mount / bottom-nav re-entry).
  static const qrPromoLastShownKey = 'qr_promo_last_shown';

  /// Fingerprint of the phonebook last uploaded to `contact-service`, so an
  /// unchanged phonebook never re-uploads. Separate from the chat-service
  /// contacts cache — see `ContactSyncController`.
  static const contactServiceDigestKey = 'contact_service_digest';

  /// `millisecondsSinceEpoch` of the last successful `contact-service` sync,
  /// used for the ">24h" cadence check without a network round-trip.
  static const contactServiceLastSyncKey = 'contact_service_last_sync';

  /// Persist a referral code that arrived via deeplink before the user
  /// completed onboarding. No-op for empty / whitespace-only input so
  /// a malformed query param can't overwrite a previously-valid one.
  static Future<void> saveDeferredReferralCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    await setSecureValue(deferredReferralCodeKey, trimmed);
  }

  /// Read the deferred referral code, or null when none is stored.
  /// Returns null (not '') for the absent case so callers can use the
  /// idiomatic `if (code != null && code.isNotEmpty)` check.
  static Future<String?> getDeferredReferralCode() async {
    final value = await getSecureValue(deferredReferralCodeKey);
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  /// Wipe the stored code — call after onboarding has applied it, so
  /// a second account creation on the same device doesn't pick up a
  /// stale referral.
  static Future<void> clearDeferredReferralCode() async {
    await _secureStorage.delete(key: deferredReferralCodeKey);
  }

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
    String profileImage = '',
  }) async {
    await SharedPreferenceUtils.setSecureValue(loginUserId, loginUserId_);
    await SharedPreferenceUtils.setSecureValue(isUserLogin, "true");
    await SharedPreferenceUtils.setSecureValue(userLoginMobile, contactNo);
    await SharedPreferenceUtils.setSecureValue(authToken, autToken);
    await SharedPreferenceUtils.setSecureValue(userName, getUserName);
    await SharedPreferenceUtils.setSecureValue(userProfile, profileImage);
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
    // flutter_secure_storage DELETES the key when handed a null value. A
    // nullable API field (e.g. `data.business` that's momentarily null on a
    // login refresh) would therefore silently WIPE a previously-stored good
    // value — this is why `businessId` came back empty in some sessions.
    // Treat null as a no-op; intentional clears go through delete()/
    // deleteAll(), never through a null write.
    if (sharedPreferencesValue == null) return;
    await _secureStorage.write(
        key: sharedPreferencesKey, value: sharedPreferencesValue);
  }

  ///GET STORAGE VALUE...
  static Future getSecureValue(String sharedPreferencesKey) async {
    // Reads can intermittently throw on Android (keystore /
    // EncryptedSharedPreferences decrypt failures). Swallow and return null
    // so callers fall back to their default instead of the exception
    // propagating and leaving a global unset mid-boot.
    try {
      return await _secureStorage.read(key: sharedPreferencesKey);
    } catch (e) {
      debugPrint('getSecureValue($sharedPreferencesKey) failed: $e');
      return null;
    }
  }

  static Future<String?> getBookingAvailabilityDetail() async {
    return await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.availabilityDetails);
  }

  /// Marks (locally) that the given business has set its grocery shop
  /// availability, so the set-availability reminder stops showing.
  static Future<void> setGroceryAvailabilitySet(String businessId) async {
    await setSecureValue(
        '$groceryAvailabilitySetPrefix$businessId', 'true');
  }

  /// Whether the given business has already set its grocery shop
  /// availability locally. Defaults to false when nothing is stored.
  static Future<bool> isGroceryAvailabilitySet(String businessId) async {
    final value =
        await getSecureValue('$groceryAvailabilitySetPrefix$businessId');
    return value == 'true';
  }

  /// Wipe ONLY the Keychain (flutter_secure_storage) without touching
  /// GetX controllers, FCM state, or localization. Safe to call during
  /// early boot when AuthController hasn't been registered yet.
  static Future<void> wipeSecureStorageOnly() async {
    await _secureStorage.deleteAll();
  }

  /// Non-reactive half of `clearPreference()`: secure storage wipe, prefs
  /// removal, plain global-string resets, base URL preserve, FCM token
  /// refresh. Safe to call while screens are still mounted because none of
  /// these touch Rx variables — no Obx rebuilds, no widget re-creations.
  static Future<void> clearPreferenceDataOnly() async {
    try {
      final workManagerBaseUrl =
          await SharedPreferenceUtils.getBaseUrlSecureValue();
      await _secureStorage.deleteAll();

      // Wipe the per-profile Hive caches on every logout path (not just
      // LogoutHelper) so the next login can never replay the previous
      // user's stale business/personal profile and must hit the API
      // fresh. Best-effort: a failure here must not block the wipe.
      try {
        await BusinessProfileCache.clear();
        await PersonalProfileCache.clear();
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("last_dialog_shown");
      lastHomeFetchTime = null;
      // Re-init localization Hive box after logout clears disk
      await LocalizationService().init();

      // Unbind this device from the user on the backend so pushes/calls stop
      // routing here after logout. Runs while authTokenGlobal is still set
      // (the API interceptor reads the in-memory global, which we clear just
      // below) so the request is authenticated. Best-effort: never block or
      // throw out of logout.
      try {
        if (authTokenGlobal != null && authTokenGlobal!.isNotEmpty) {
          await ApiBaseHelper().deleteHTTP(
            'user-service/user/me/device-token',
            showProgress: false,
            onError: (_) {},
            onSuccess: (_) {},
          );
          if (Platform.isIOS) {
            await ApiBaseHelper().deleteHTTP(
              'user-service/user/me/voip-token',
              showProgress: false,
              onError: (_) {},
              onSuccess: (_) {},
            );
          }
        }
      } catch (_) {}

      authTokenGlobal = '';
      accountTypeGlobal = '';
      userId = '';
      businessId = '';
      userMobileGlobal = '';
      // Reset the Discover share-promo session guard so the next login shows it
      // again (its persisted per-day key was just wiped by deleteAll() above).
      sharePromoShownThisSession = false;
      // Same reasoning for the merchant add-product prompt's in-memory day
      // mirror — its persisted key was wiped by deleteAll() above.
      addProductPromptShownForDay = null;
      // ...and for the business-profile QR promo sheet's in-memory day mirror.
      qrPromoShownForDay = null;
      // Clear the account-creation promo suppression so the next session pops
      // the once-a-day promos normally.
      suppressPromosAfterAccountCreation = false;
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
      businessTypeGlobal = '';
      businessCategoryGlobal = '';
      businessSubCategoryGlobal = '';
      schoolIDGlobal = '';
      hotelIDGlobal = '';
      labIDGlobal = '';
      hospitalIDGlobal = '';
      otherServiceIDGlobal = '';
      productBusinessProfileIDGlobal = '';
      await SharedPreferenceUtils.setBaseUrlSecureValue(workManagerBaseUrl);
      await AppNotificationHandler.refreshFcmToken();
    } on Exception {
      await SharedPreferenceUtils.setBaseUrlSecureValue(baseUrl);
    }
  }

  /// Reactive half: writing to AuthController.imgPath (RxString) and
  /// clearing GetX translations both fire Obx rebuilds across the app, so
  /// these MUST run after navigating away from data-driven screens —
  /// otherwise the rebuild storm hits getOrPut(... permanent:true) paths
  /// and re-creates controllers we've already torn down (orphan APIs).
  static Future<void> clearPreferenceReactive() async {
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().imgPath.value = "";
    }
    await resetLanguageLocalization();
  }

  ///CLEAR DATA... (data + reactive in one shot — unchanged behavior for
  /// callers that don't need the phased split, e.g. the 401 handler).
  static Future<void> clearPreference() async {
    await clearPreferenceDataOnly();
    await clearPreferenceReactive();
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
  final stored = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.userBusinessId);
  // Only adopt a non-empty stored id. A transient null/empty read (keystore
  // hiccup, or a refresh that hasn't re-persisted yet) must not wipe a
  // businessId we already hold this session — every downstream business API
  // depends on it. Logout clears it explicitly via clearPreferenceDataOnly().
  if (stored is String && stored.trim().isNotEmpty) {
    businessId = stored;
  }
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
  // Every getSecureValue is a full platform-channel round trip (Android
  // EncryptedSharedPreferences decrypt / iOS Keychain read). Running all
  // ~18 reads sequentially added hundreds of ms to every cold start, so
  // fire them in parallel and assign from the resolved batch.
  final values = await Future.wait<dynamic>([
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.authToken),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.accountType),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.loginUserId),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userBusinessId),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userLoginMobile),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userProfile),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userName),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userProfileType),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userProfession),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userDesignation),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.has_reel_profile),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.businessName),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.businessOwnerName),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.businessOwnerAddress),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.userNameAtKey),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.businessCategory),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.businessSubCategory),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.businessType),
  ]);

  authTokenGlobal = values[0];
  accountTypeGlobal = values[1] ?? '';
  userId = values[2] ?? "";
  businessId = values[3] ?? "";
  userMobileGlobal = values[4] ?? "";
  userProfileGlobal = values[5] ?? "";
  userNameGlobal = values[6] ?? "";
  userProfileTypeGlobal = values[7] ?? "";
  userProfessionGlobal = values[8] ?? "";
  userDesignationGlobal = values[9] ?? "";
  has_reel_profile_status = values[10] ?? "false";
  businessNameGlobal = values[11] ?? "";
  businessOwnerNameGlobal = values[12] ?? "";
  businessOwnerAddressGlobal = values[13] ?? "";
  userNameAtGlobal = values[14] ?? "";
  businessCategoryGlobal = values[15] ?? "";
  businessSubCategoryGlobal = values[16] ?? "";
  // Default to EMPTY, never a sentinel like "OTHER". The key is absent between
  // login and the first business-profile write (logout deleteAll()s storage),
  // and resolveBusinessScreen() distinguishes the two cases purely by
  // emptiness: empty → "still loading, show the shimmer", non-empty → "this is
  // the real type, route on it (or fall back if unrecognised)". A non-empty
  // sentinel here reads as a real-but-unknown type and flashes
  // _UnknownBusinessFallback on every login before the profile lands.
  businessTypeGlobal = values[17] ?? "";

  Get.find<AuthController>().imgPath.value = userProfileGlobal;
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
  final values = await Future.wait<dynamic>([
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.channel_Id),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.channelName),
    SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.channelOwner),
  ]);
  channelId = values[0] ?? "";
  channelName = values[1] ?? "";
  channelOwner = values[2] ?? "";
}

Future<void> clearSecureStorageIfFreshInstall() async {
  final prefs = await SharedPreferences.getInstance();
  final hasInstalledBefore = prefs.getBool('hasInstalledBefore') ?? false;
  if (hasInstalledBefore) return;

  // Persist the flag FIRST. If the keychain wipe below throws for any
  // reason, we must not re-enter this branch on every launch and clobber
  // a freshly-saved auth token.
  await prefs.setBool('hasInstalledBefore', true);

  try {
    // Only wipe the Keychain — that's the sole thing that survives an
    // iOS app-delete/reinstall. Do NOT call clearPreference() here: it
    // calls Get.find<AuthController>() which isn't registered yet at
    // this point in main()'s boot sequence, causing a silent throw that
    // would have prevented the flag write above in the old code.
    await SharedPreferenceUtils.wipeSecureStorageOnly();
  } catch (e) {
    debugPrint('clearSecureStorageIfFreshInstall: $e');
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

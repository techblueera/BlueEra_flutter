import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/others_service_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/features/Emergency/view/emergency_profileScreen.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_screen_updated.dart';
import 'package:BlueEra/features/chat/view/forward_screen/chat_forward_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/onboarding/view/select_language_screen.dart';
import 'package:BlueEra/features/common/profile_share_preview/view/profile_share_preview_screen.dart';
import 'package:BlueEra/features/me/food/view/share/food_product_share_preview_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/grocery/view/share/grocery_product_share_preview_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/share_product_screen.dart';
import 'package:BlueEra/main.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openNextScreen();
  }

  void _openNextScreen() async {
    final tempLoginType = await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.accountType);
    accountTypeGlobal = tempLoginType.toString();

    var isLoginStatus = await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.isUserLogin);
    if (isLoginStatus == null) isLoginStatus = "false";

    // Fresh install attribution: a shared Play Store link carries the
    // referrer (`referralCode=…`). Capture it before the user reaches
    // signup so onboarding can auto-fill the promo code. Only needed for
    // not-yet-logged-in users; logged-in sessions already have it (or
    // never will).
    if (isLoginStatus != "true") {
      await _captureInstallReferrerOnce();
    }

    // ✅ Check if app was updated
    // final logoutRequired = await _shouldLogoutAfterUpdate();
    // log('logout required--> $logoutRequired');

    // If a call was accepted from CallKit during cold start, skip everything
    if (CallController.launchedForCall.value) return;

    // If shared media is pending and user is logged in, skip splash delay
    if (isLoginStatus == "true" && pendingSharedMedia != null && !isGuestUser()) {
      final media = pendingSharedMedia!;
      pendingSharedMedia = null; // consume it so it's never handled again
      // Also reset the platform-level initial media so _getSharedMedia()
      // won't pick it up a second time.
      try {
        ShareHandlerPlatform.instance.resetInitialSharedMedia();
      } catch (_) {}
      final sharedText = media.content;
      final attachments = media.attachments ?? [];
      if ((sharedText != null && sharedText.isNotEmpty) || attachments.isNotEmpty) {
        if (accountTypeGlobal.toUpperCase() == AppConstants.individual) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            arguments: {ApiKeys.initialIndex: 1},
            (Route<dynamic> route) => false,
          );
        } else {
          // Business cold-starts onto its own Me tab (0); individuals → Discover.
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            arguments: {ApiKeys.initialIndex: 0},
            (Route<dynamic> route) => false,
          );
        }

        if (sharedText != null && sharedText.isNotEmpty) {
          Get.to(() => ChatForwardScreen(sharedText: sharedText));
        } else {
          Get.to(() => ChatForwardScreen(sharedFiles: attachments));
        }
        return;
      }
    }

    Timer(const Duration(milliseconds: 200), () async {
      // If a call was accepted from CallKit (killed state), skip normal navigation —
      // CallController will navigate directly to ActiveCallScreen
      if (CallController.launchedForCall.value) {
        return;
      }

      // If app was launched by tapping a notification, stay on splash screen
      // and wait for notification handler to navigate to the correct screen.
      if (AppNotificationHandler.launchedFromNotification && isLoginStatus == "true") {
        // Wait for notification navigation to complete (with a safety timeout)
        if (AppNotificationHandler.notificationNavigationCompleter != null) {
          await AppNotificationHandler.notificationNavigationCompleter!.future
              .timeout(const Duration(seconds: 5), onTimeout: () {});
        }
        // Reset the flag so it doesn't block future navigations
        AppNotificationHandler.launchedFromNotification = false;
        return;
      }

      // First-launch (or post-logout) language selection. Logged-in users skip
      // this since they have already picked a language during onboarding.
      if (isLoginStatus != "true") {
        final hasSelectedLanguage =
            await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.hasSelectedLanguage) ?? "false";
        if (hasSelectedLanguage != "true") {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SelectLanguageScreen()),
            (Route<dynamic> route) => false,
          );
          return;
        }
      }

      if (isLoginStatus == "true") {
        // Resolve any cold-start deep link first, but DO NOT navigate to
        // it yet — we need to replace the splash with the bottom-nav
        // before pushing the target on top. Otherwise back-press from
        // the deep-link screen pops back to splash (which has no further
        // navigation) and the app appears stuck.
        final initialDeepLink = await _initDeepLinks();
        final sharedMedia = await _getSharedMedia();

        if (!mounted) return;
        if (accountTypeGlobal.toUpperCase() == AppConstants.individual) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            (Route<dynamic> route) => false,
            arguments: {
              ApiKeys.initialIndex: 1,
              if (sharedMedia != null) 'sharedMedia': sharedMedia,
            },
          );
        } else {
          // Business cold-starts onto its own Me tab (0); individuals → Discover.
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            (Route<dynamic> route) => false,
            arguments: {
              ApiKeys.initialIndex: 0,
              if (sharedMedia != null) 'sharedMedia': sharedMedia,
            },
          );
        }

        // Now that the bottom-nav is the root of the navigator stack,
        // push the deep-link target on top. Back-press from the target
        // will pop to the bottom-nav instead of leaving the user on the
        // dead-end splash screen.
        if (initialDeepLink != null) {
          _handleDeepLink(initialDeepLink);
        }
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteHelper.getMobileNumberLoginRoute(),
          (Route<dynamic> route) => false,
        );
      }
    });

    // await OnesignalService().initialize();
  }

  Future<SharedMedia?> _getSharedMedia() async {
    try {
      final handler = ShareHandlerPlatform.instance;
      final media = await handler.getInitialSharedMedia();
      if (media != null) {
        handler.resetInitialSharedMedia();
      }
      if (media?.content?.isNotEmpty ?? false) return media;
      if (media?.attachments?.isNotEmpty ?? false) return media;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reads the Google Play install referrer once per install and, if it
  /// carries a `referralCode`, stashes it via [saveDeferredReferralCode]
  /// so onboarding auto-fills the promo code. This is the Play-Store
  /// counterpart to the `?referralCode=` deeplink path in
  /// [_handleDeepLink]; the shared store link encodes the same code as
  /// `&referrer=referralCode%3D<code>`, which Play returns (decoded) as
  /// `referralCode=<code>`.
  Future<void> _captureInstallReferrerOnce() async {
    // Install referrer is an Android/Play-Store-only mechanism.
    if (!Platform.isAndroid) return;
    try {
      // Query at most once: the referrer never changes for an install, so
      // re-reading it after onboarding cleared the code would resurrect a
      // stale referral on a second account on the same device.
      final already = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.installReferrerCheckedKey);
      if (already == "true") return;

      final details = await AndroidPlayInstallReferrer.installReferrer;
      final referrer = details.installReferrer;
      if (referrer != null && referrer.isNotEmpty) {
        final code = Uri.splitQueryString(referrer)['referralCode'];
        if (code != null && code.trim().isNotEmpty) {
          await SharedPreferenceUtils.saveDeferredReferralCode(code);
        }
      }
      // Mark checked only after a successful query so a transient failure
      // (e.g. Play Store not ready yet) retries on the next cold start.
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.installReferrerCheckedKey, "true");
    } catch (e) {
      logs('Install referrer capture failed: $e');
    }
  }

  late final AppLinks _appLinks;

  /// Resolves the cold-start deep link (returns `null` when there isn't
  /// one) and subscribes to warm-state links. The cold-start URI is
  /// returned so the caller can replace splash with the home shell first
  /// and *then* push the target on top — otherwise back-press from the
  /// target lands on splash and the app appears stuck.
  Future<Uri?> _initDeepLinks() async {
    _appLinks = AppLinks();
    // Warm-state links: app is already running so splash is not on the
    // stack — `Get.to` from the handler pushes the target normally.
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    return await _appLinks.getInitialLink();
  }

  bool _isValidMongoId(String id) {
    return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint("=====================================Deep link received:========================= $uri");
    try {
      // Every BlueEra deeplink carries `?referralCode=…` when shared
      // by a verified BDM. Capture it before path-based routing so it
      // survives whatever screen the link takes the user to — the
      // onboarding flow consumes it from secure prefs at signup time.
      final referral = uri.queryParameters['referralCode'];
      if (referral != null && referral.trim().isNotEmpty) {
        await SharedPreferenceUtils.saveDeferredReferralCode(referral);
      }

      // Emergency profile QR / sticker links use a dedicated host:
      //   https://emergency.beapp.in/<profileId>
      // The viewer is typically a responder, not the owner, so open the
      // read-only profile view for that explicit id.
      if (uri.host == 'emergency.beapp.in') {
        final emergencyId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (emergencyId.isNotEmpty && _isValidMongoId(emergencyId)) {
          Get.to(() => EmergencyProfileScreen1(profileId: emergencyId));
        } else {
          logs('Invalid emergency profile id in deep link: $emergencyId');
        }
        return;
      }

      final segments = uri.pathSegments; // e.g., [app, post, 123]
      print("segments==== ${segments}");

      // Education (school) share/QR links carry an extra `education` segment:
      //   https://beapp.in/app/business/education/<id>
      // Route these straight to the Discover school home screen instead of the
      // generic business share-preview. Checked before the generic `app`
      // handling below because the id sits at segments[3], not segments[2].
      if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'education') {
        final schoolId = segments[3];
        if (!_isValidMongoId(schoolId)) {
          logs('Invalid education id in deep link: $schoolId');
          return;
        }
        _openEducationSchool(schoolId);
        return;
      }

      // Grocery store share/QR links carry an extra `grocery` segment:
      //   https://beapp.in/app/business/grocery/<id>
      // Route these straight to the grocery store screen
      // ([VisitGroceryStoreScreen]) instead of the generic business
      // share-preview. Checked before the generic `app` handling below
      // because the id sits at segments[3], not segments[2]. Mirrors the
      // education branch above.
     else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'grocery') {
        final groceryBusinessId = segments[3];
        if (!_isValidMongoId(groceryBusinessId)) {
          logs('Invalid grocery id in deep link: $groceryBusinessId');
          return;
        }
        _openGroceryStore(groceryBusinessId);
        return;
      }

      // Hotel share/QR links carry an extra `hotel` segment:
      //   https://beapp.in/app/business/hotel/<businessId>
      // Route these straight to the hotel detail screen
      // ([HotelDiscoverHomeScreen]) instead of the generic business
      // share-preview. Like education/grocery, the id sits at segments[3],
      // so this is checked before the generic 3-segment `app` handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'hotel') {
        final hotelBusinessId = segments[3];
        if (!_isValidMongoId(hotelBusinessId)) {
          logs('Invalid hotel id in deep link: $hotelBusinessId');
          return;
        }
        deepLinkNetworkResources.navigateToHotelDetail(hotelBusinessId);
        return;
      }

      // Hospital share/QR links carry an extra `hospital` segment:
      //   https://beapp.in/app/business/hospital/<businessId>
      // Route these straight to the hospital detail screen
      // ([DiscoverHospitalHomeScreen]) instead of the generic business
      // share-preview. Like education/grocery/hotel, the id sits at
      // segments[3], so this is checked before the generic 3-segment `app`
      // handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'hospital') {
        final hospitalBusinessId = segments[3];
        if (!_isValidMongoId(hospitalBusinessId)) {
          logs('Invalid hospital id in deep link: $hospitalBusinessId');
          return;
        }
        _openHospital(hospitalBusinessId);
        return;
      }

      // Medical (pharmacy) share/QR links carry an extra `medical` segment:
      //   https://beapp.in/app/business/medical/<businessId>
      // Route these straight to the pharmacy detail screen
      // ([MedicalPharmacyDetailScreen]) instead of the generic business
      // share-preview. Like education/grocery/hotel/hospital, the id sits at
      // segments[3], so this is checked before the generic 3-segment `app`
      // handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'medical') {
        final medicalBusinessId = segments[3];
        if (!_isValidMongoId(medicalBusinessId)) {
          logs('Invalid medical id in deep link: $medicalBusinessId');
          return;
        }
        _openMedicalPharmacy(medicalBusinessId);
        return;
      }

      // Financial (finance) share/QR links carry an extra `financial` segment:
      //   https://beapp.in/app/business/financial/<businessId>
      // Route these straight to the finance detail screen
      // ([FinanceDetailScreen]) instead of the generic business share-preview.
      // Like education/grocery/hotel/hospital/medical, the id sits at
      // segments[3], so this is checked before the generic 3-segment `app`
      // handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'financial') {
        final financeBusinessId = segments[3];
        if (!_isValidMongoId(financeBusinessId)) {
          logs('Invalid financial id in deep link: $financeBusinessId');
          return;
        }
        _openFinance(financeBusinessId);
        return;
      }

      // Professionals (consultant) share/QR links carry the pair of
      // `professionals/consultant` segments:
      //   https://beapp.in/app/professionals/consultant/<visitUserId>
      // Route these straight to the "other" service detail screen
      // ([OthersServiceDetailScreen]) instead of the generic business
      // share-preview. The id sits at segments[3], so this is checked before
      // the generic 3-segment `app` handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'professionals' &&
          segments[2] == 'consultant') {
        final consultantId = segments[3];
        if (!_isValidMongoId(consultantId)) {
          logs('Invalid professionals consultant id in deep link: $consultantId');
          return;
        }
        _openProfessionalsConsultant(consultantId);
        return;
      }


      // Product store share/QR links carry an extra `shopping` segment:
      //   https://beapp.in/app/business/shopping/<visitUserId>
      // Route these straight to the product store detail screen
      // ([VisitProductStoreDetailsScreen]) instead of the generic business
      // share-preview. Like education/grocery/hotel/hospital/medical/financial,
      // the id sits at segments[3], so this is checked before the generic
      // 3-segment `app` handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'shopping') {
        final shopUserId = segments[3];
        if (!_isValidMongoId(shopUserId)) {
          logs('Invalid shopping id in deep link: $shopUserId');
          return;
        }
        _openProductStore(shopUserId);
        return;
      }

      // Professional/consulting business share/QR links carry an extra
      // `services` segment:
      //   https://beapp.in/app/business/services/<userId>
      // Route these straight to the discover professionals view screen
      // ([DiscoverProfessionalsViewScreen]) instead of the generic business
      // share-preview. Like education/grocery/hotel/hospital/medical/financial/
      // shopping, the id sits at segments[3], so this is checked before the
      // generic 3-segment `app` handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'services') {
        final servicesUserId = segments[3];
        if (!_isValidMongoId(servicesUserId)) {
          logs('Invalid business services id in deep link: $servicesUserId');
          return;
        }
        _openBusinessServices(servicesUserId);
        return;
      }

    else   if (segments.length >= 3 && segments[0] == 'app') {
        final type = segments[1]; // post | video | short | job | product
        final id = segments[2];
print("type==== ${type}");
        // Validate that the ID follows the expected MongoDB ObjectID format (24 hex characters)
        if (!_isValidMongoId(id)) {
          logs('Invalid ID format in deep link: $id');
          return;
        }

        switch (type) {
          case 'post':
            Get.to(() => PostDeatilPage(), arguments: {"postId": id});
            break;
          case 'product':
            Get.to(() => ShareProductScreen(productId: id));
            break;
          case 'vehicle':
            // Public vehicle share/QR landing
            // (`https://beapp.in/app/vehicle/<id>`). The screen fetches its own
            // data from [VehicleController.fetchVehicleById] in initState, so
            // passing the id is enough to hydrate the full detail view.
            Get.to(() => VehicleDetailScreen(vehicleId: id));
            break;
          case 'hotel':
            // Public hotel share/QR landing
            // (`https://beapp.in/app/hotel/<businessId>`). Unlike vehicles, the
            // hotel screen needs a fully-hydrated HotelServiceData, so we fetch
            // it by businessId first and then open HotelDiscoverHomeScreen.
            deepLinkNetworkResources.navigateToHotelDetail(id);
            break;
          case 'grocery':
            // Public grocery share landing — fetches the product itself
            // and renders the deep-link-only preview.
            Get.to(() => GroceryProductSharePreviewScreen(productId: id));
            break;
          case 'medical':
            // Public pharmacy share/QR landing
            // (`https://beapp.in/app/medical/<businessId>`). The pharmacy
            // screen takes the businessId and hydrates itself (profile +
            // inventory) behind its own loader, so navigation is instant.
            _openMedicalPharmacy(id);
            break;
          case 'food':
            // Public food share landing — fetches the food product itself
            // (`GET /food-service/api/foodProduct/{id}`) and renders the
            // deep-link-only preview.
            Get.to(() => FoodProductSharePreviewScreen(foodId: id));
            break;
          case 'chat':
            final conversationId = id;
            final queryParams = uri.queryParameters;
            final chatUserId = queryParams['userId'] ?? '';
            final chatType = queryParams['chatType'] ?? 'personal';
            final chatName = queryParams['name'] ?? '';

            // Validate chatUserId if it's provided
            if (chatUserId.isNotEmpty && !_isValidMongoId(chatUserId)) {
              logs('Invalid chat user ID in deep link: $chatUserId');
              return;
            }

            if (chatType == 'business') {
              Get.to(() => BusinessChatScreenUpdated(
                    conversationId: conversationId,
                    userId: chatUserId,
                    type: chatType,
                    name: chatName,
                    isInitialMessage: false,
                  ));
            } else {
              Get.to(() => PersonalChatScreen(
                    conversationId: conversationId,
                    userId: chatUserId,
                    type: chatType,
                    name: chatName,
                    isInitialMessage: false,
                  ));
            }
            break;
          case 'profile':
          case 'business':
            // Both share-link shapes land on the public share-preview screen.
            // The URL prefix ('profile' vs 'business') is just a hint for the
            // account-type pill while the API fetch is in flight — the
            // /share/users/{id}/profile-overview response is the source of
            // truth. Older 4-segment 'profile/{id}/{accountType}' links from
            // pre-launch sharing pass the same id through cleanly.
            final accountTypeHint = type == 'business' ? AppConstants.business : AppConstants.individual;
            Get.to(() => ProfileSharePreviewScreen(
                  userId: id,
                  accountTypeHint: accountTypeHint,
                ));
            break;
          default:
            logs('Unknown deep link type: $type');
        }
      } else {
        debugPrint("SEGMENTS==== ELSE");

        // Fallback: try last segment as id (legacy)
        final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (last.isNotEmpty && _isValidMongoId(last)) {
          Get.to(() => PostDeatilPage(), arguments: {"postId": last});
        } else if (last.isNotEmpty) {
          logs('Invalid legacy ID in deep link: $last');
        }
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  /// Opens [DiscoverSchoolHomeScreen] for a school reached via deep link / QR
  /// scan. The link carries a single id (the owner/business id used when the
  /// school was shared). The screen reads its data from
  /// [SchoolAboutUsController], so the controller is registered first, reset to
  /// an empty school (so a previously-viewed school doesn't flash), then the
  /// fetch is kicked off. The id is passed as both `schoolID` and `ownerID`:
  /// the controller tries the school-id lookup first and transparently falls
  /// back to the owner-id lookup, so it resolves regardless of which the id
  /// actually is — mirroring the in-app tap flow from the education list.
  void _openEducationSchool(String id) {
    final schoolAboutUsController = getOrPut(() => SchoolAboutUsController());
    schoolAboutUsController.schoolDetailsData?.value = SchoolDetailsData();
    Get.to(() => DiscoverSchoolHomeScreen());
    schoolAboutUsController.getSchoolByIdController(
      schoolID: id,
      ownerID: id,
    );
  }

  /// Opens [VisitGroceryStoreScreen] for a grocery store reached via deep
  /// link / QR scan (`https://beapp.in/app/business/grocery/<id>`). The link
  /// carries a single id (the owner/business id used when the store was
  /// shared), passed as both `visitBusinessId` and `userId` — mirroring the
  /// in-app tap flow from the profile share-preview redirect
  /// ([ProfileSharePreviewScreen._openBusinessDetail]). The screen fetches
  /// its own profile + grocery data from its controllers, and the
  /// cart/checkout flow works exactly as in the normal navigation path.
  /// Deep links are only resolved for logged-in users (see [_initDeepLinks]
  /// call site), so the authenticated ordering flow is always available here.
  void _openGroceryStore(String id) {

    Get.to(() => VisitGroceryStoreScreen(
          visitBusinessId: id,
          userId: id,
        ));
  }

  /// Opens [DiscoverHospitalHomeScreen] for a hospital reached via deep link /
  /// QR scan (`https://beapp.in/app/business/hospital/<businessId>`). The link
  /// carries a single id (the hospital's business id used when it was shared).
  /// [DiscoverHospitalHomeScreen] reads its data from
  /// [HospitalServiceAiController] and calls `Get.find` for both that and
  /// [ViewBusinessDetailsController] in its initState, so both are registered
  /// first. The model is seeded with just the id — the screen's initState then
  /// fetches the full profile via `viewBusinessProfileById` and merges the
  /// hospital sections, mirroring the in-app tap flow from the hospital list
  /// ([HospitalListScreen._openDetail]).
  void _openHospital(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    final hospitalController = getOrPut(() => HospitalServiceAiController());
    hospitalController.hospitalDataResModel?.value =
        HospitalFullDetailsResModel(success: true, data: HospitalFullData(id: id));
    Get.to(() => const DiscoverHospitalHomeScreen());
  }

  /// Opens [MedicalPharmacyDetailScreen] for a pharmacy reached via deep link /
  /// QR scan (`https://beapp.in/app/business/medical/<businessId>`). The link
  /// carries a single id (the pharmacy's business id used when it was shared).
  /// The screen does `Get.find<ViewBusinessDetailsController>()` in its
  /// initState, so that controller is registered first. It then takes the
  /// `businessId` and hydrates itself (profile + inventory) behind its own
  /// loader, so navigation is instant with no pre-fetch lag — mirroring the
  /// in-app tap flow from the medical list.
  void _openMedicalPharmacy(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => MedicalPharmacyDetailScreen(businessId: id));
  }

  /// Opens [FinanceDetailScreen] for a finance business reached via deep link /
  /// QR scan (`https://beapp.in/app/business/financial/<businessId>`). The
  /// screen reads its data from [FinanceDiscoverController], so the controller
  /// is registered first. The full profile is fetched up-front (via
  /// `fetchDetail`) so the screen shows its loader instead of a half-empty
  /// header; [FinanceDiscoverController.selectedDetail] is left null so the
  /// screen's initState doesn't kick off a second fetch. Mirrors the in-app tap
  /// flow from the finance list ([FinanceListScreen]).
  void _openFinance(String id) {
    final controller = getOrPut(() => FinanceDiscoverController());
    controller.selectedDetail.value = null;
    controller.fetchDetail(id);
    Get.to(() => const FinanceDetailScreen());
  }

  /// Opens [OthersServiceDetailScreen] for a professional/consultant reached
  /// via deep link / QR scan
  /// (`https://beapp.in/app/professionals/consultant/<visitUserId>`). The link
  /// carries the owner/business (visit) id used when the listing was shared.
  /// The screen does `Get.find<ViewBusinessDetailsController>()` in its
  /// initState, so that controller is registered first; the screen then fetches
  /// its own profile + inventory behind its own loader, so navigation is
  /// instant — mirroring the in-app tap flow from the service business card
  /// ([ServiceBusinessCard._openStore]).
  void _openProfessionalsConsultant(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => OthersServiceDetailScreen(visitUserId: id));
  }



  /// Opens [VisitProductStoreDetailsScreen] for a product store reached via
  /// deep link / QR scan
  /// (`https://beapp.in/app/business/shopping/<visitUserId>`). The link carries
  /// the owner (user) id used when the store was shared. The screen does
  /// `Get.find<ViewBusinessDetailsController>()` in its initState, so that
  /// controller is registered first; the screen then fetches its own profile +
  /// inventory behind its own loader, so navigation is instant — mirroring the
  /// in-app tap flow that opens `VisitProductStoreDetailsScreen(visitUserId:
  /// ownerId)`.
  void _openProductStore(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => VisitProductStoreDetailsScreen(visitUserId: id));
  }

  /// Opens [DiscoverProfessionalsViewScreen] for a professional/consulting
  /// business reached via deep link / QR scan
  /// (`https://beapp.in/app/business/services/<userId>`). The link carries the
  /// owner (user) id used when the listing was shared. The screen fetches its
  /// own [ProfessionalConsData] via `DiscoverController.getProfessionalByUserId`
  /// in its initState (registering the controller itself), so passing the id as
  /// `userId` is enough to hydrate the full view — mirroring the in-app tap flow
  /// from the Discover professionals list.
  void _openBusinessServices(String id) {
    Get.to(() => DiscoverProfessionalsViewScreen(userId: id));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Spacer(flex: 3),
          CustomText(
            "🇮🇳  MADE IN INDIA",
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
          ),
          Spacer(flex: 10),
          LocalAssets(
            imagePath: AppIconAssets.blueEraIcon,
            height: SizeConfig.size100,
          ),
          Spacer(flex: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size40),
            child: LocalAssets(
              imagePath: AppImageAssets.splashBgImage,
              height: SizeConfig.size70,
            ),
          ),
          Spacer(flex: 1),
        ],
      ),
    );
  }
}

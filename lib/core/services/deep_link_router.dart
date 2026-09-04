import 'dart:async';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/others_service_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/profile_share_preview/model/share_profile_overview_response.dart';
import 'package:BlueEra/features/common/profile_share_preview/repo/share_profile_overview_repo.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_listing_detail_screen_v3.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_detail_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/Emergency/view/emergency_profileScreen.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_screen_updated.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/profile_share_preview/view/profile_share_preview_screen.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/me/food/view/share/food_product_share_preview_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/grocery/view/share/grocery_product_share_preview_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/share_product_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Routes an incoming deeplink / QR URL to the screen it names.
///
/// Lifted out of `SplashScreen` so the SAME routing can run from more than one
/// place. Splash still handles the cold-start and warm-state links, but a link
/// that arrived while the user was signed out (or on a guest account) is
/// stashed by [SharedPreferenceUtils.saveDeferredDeepLink] and replayed
/// through here by the home shell once a real account exists — otherwise the
/// vehicle-QR "Report parking issue" button opens the login screen and the
/// chat it was pointing at is lost. See `lib/docs/VEHICLE_QR_FLUTTER_GUIDE.md`.
///
/// Everything here navigates with `Get`, never with a `BuildContext`, which is
/// why it can run from a splash that is about to be torn down or from a
/// post-frame callback on the home shell.
class DeepLinkRouter {
  const DeepLinkRouter._();

  /// Routes [uri] if this session can open it, and stashes it for later if it
  /// cannot.
  ///
  /// Two cases stash instead of routing:
  ///   • signed out — there is no session at all, so the link waits for login
  ///   • a guest opening a link that [requiresRealAccount]
  ///
  /// In both, `BottomNavigationBarScreen` replays it once a real account
  /// exists. Splash does this same decision inline for the cold-start link
  /// (it has just read the login flag out of secure storage and does not need
  /// the in-memory globals); this entry point is for links that arrive while
  /// the app is already running.
  static Future<void> routeOrDefer(Uri uri) async {
    final isSignedIn = isUserLoginGlobal == "true";
    if (isBrowserBounce(uri) ||
        (isSignedIn && !(isGuestUser() && requiresRealAccount(uri)))) {
      await handle(uri);
      return;
    }
    await SharedPreferenceUtils.saveDeferredDeepLink(uri.toString());
    logs('Deep link deferred until the user has an account: $uri');
  }

  /// True for the vehicle-safety sticker URL (`emergency.beapp.in/v/{code}`),
  /// which [handle] does not route at all — it re-launches it in the browser.
  ///
  /// It has to be recognised BEFORE the session checks: the scan page is a
  /// full web journey (register, OTP claim, terms, SOS) that needs no BlueEra
  /// account, and stashing it for after login would leave the scanner staring
  /// at a login screen for a page they were never meant to see in the app.
  static bool isBrowserBounce(Uri uri) =>
      uri.host == 'emergency.beapp.in' &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == 'v';

  /// Links that need a REAL account behind them, not just "some session".
  ///
  /// Only chat so far: a guest has no profile for the other side to reply to,
  /// and every in-app chat entry point already bounces a guest to account
  /// creation (see `DiscoverChatIcon`). Landing a guest in a chat they cannot
  /// hold is worse than asking them to finish signing up first, so the caller
  /// keeps the link stashed and sends them to [createProfileScreen] instead.
  static bool requiresRealAccount(Uri uri) {
    final segments = uri.pathSegments;
    return segments.length >= 3 && segments[0] == 'app' && segments[1] == 'chat';
  }

  static bool isValidMongoId(String id) {
    return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
  }

  static Future<void> handle(Uri uri) async {
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
        // Vehicle-safety stickers encode `https://emergency.beapp.in/v/{code}`
        // on the SAME host, and that URL belongs to the browser — the whole
        // scan / register / OTP-claim / parking-report page is web-only and
        // the app has no screen for it. We can't simply not claim the host:
        // the intent filter above is unscoped (it exists for the older
        // `/<profileId>` emergency QR) and Android hands us every path on it,
        // so hand `/v/*` straight back to the browser instead of dead-ending
        // on "invalid id". The web page then deep-links back in via
        // `/app/chat/new` when the reporter taps "Report parking issue".
        if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'v') {
          try {
            await launchURL(uri.toString());
          } catch (e) {
            logs('Could not hand vehicle QR link to the browser: $e');
          }
          return;
        }

        final emergencyId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (emergencyId.isNotEmpty && isValidMongoId(emergencyId)) {
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
        if (!isValidMongoId(schoolId)) {
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
        if (!isValidMongoId(groceryBusinessId)) {
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
        if (!isValidMongoId(hotelBusinessId)) {
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
        if (!isValidMongoId(hospitalBusinessId)) {
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
        if (!isValidMongoId(medicalBusinessId)) {
          logs('Invalid medical id in deep link: $medicalBusinessId');
          return;
        }
        _openMedicalPharmacy(medicalBusinessId);
        return;
      }

      // Laboratory share/QR links carry an extra `labs` segment:
      //   https://beapp.in/app/business/labs/<businessId>
      // Route these straight to the lab detail screen ([LabDetailScreen])
      // instead of the generic business share-preview. Like education/grocery/
      // hotel/hospital/medical, the id sits at segments[3], so this is checked
      // before the generic 3-segment `app` handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'labs') {
        final labBusinessId = segments[3];
        if (!isValidMongoId(labBusinessId)) {
          logs('Invalid lab id in deep link: $labBusinessId');
          return;
        }
        _openLaboratory(labBusinessId);
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
        if (!isValidMongoId(financeBusinessId)) {
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
        if (!isValidMongoId(consultantId)) {
          logs('Invalid professionals consultant id in deep link: $consultantId');
          return;
        }
        _openBusinessProfessionalServices(consultantId);

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
        if (!isValidMongoId(shopUserId)) {
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
        if (!isValidMongoId(servicesUserId)) {
          logs('Invalid business services id in deep link: $servicesUserId');
          return;
        }
        _openServicesScreen(servicesUserId);

        return;
      }

      // Food store profile share/QR links carry the pair of `profile/food`
      // segments:
      //   https://beapp.in/app/profile/food/<businessId>
      // Route these straight to the food store detail screen
      // ([VisitFoodStoreDetailsScreen]) instead of the generic profile
      // share-preview. Like the other typed profile links, the id sits at
      // segments[3], so this is checked before the generic 3-segment `app`
      // handling below.
      else if (segments.length >= 4 &&
          segments[0] == 'app' &&
          segments[1] == 'profile' &&
          segments[2] == 'food') {
        final foodBusinessId = segments[3];
        if (!isValidMongoId(foodBusinessId)) {
          logs('Invalid food profile id in deep link: $foodBusinessId');
          return;
        }
        _openFoodStore(foodBusinessId);
        return;
      }

      // Home-made-food store share/QR links carry the trio of
      // `business/homemade/food` segments:
      //   https://beapp.in/app/business/homemade/food/<userId>
      // Route these straight to the home-made-food store detail screen
      // ([HmfStoreDetailsDiscoverScreen]) instead of the generic business
      // share-preview. The store owner's user id sits at segments[4], so this
      // is checked before the generic 3-segment `app` handling below.
      else if (segments.length >= 5 &&
          segments[0] == 'app' &&
          segments[1] == 'business' &&
          segments[2] == 'homemade' &&
          segments[3] == 'food') {
        final hmfUserId = segments[4];
        if (!isValidMongoId(hmfUserId)) {
          logs('Invalid homemade food id in deep link: $hmfUserId');
          return;
        }
        _openHomeMadeFoodStore(hmfUserId);
        return;
      }

    else   if (segments.length >= 3 && segments[0] == 'app') {
        final type = segments[1]; // post | video | product | profile | …
        final id = segments[2];
print("type==== ${type}");

        // `chat/new` is the one id slot that is NOT an ObjectId.
        //
        // A vehicle-QR parking report opens a chat between two strangers, who
        // by definition have no conversation yet, so the backend sends the
        // literal `new` and chat-service creates the conversation when the
        // first message is sent. See docs/backend/VEHICLE_QR_FRONTEND_GUIDE.md
        // §2a-app.
        //
        // Scoped to `chat` deliberately, rather than waved through for every
        // type: `app/post/new` or `app/product/new` would otherwise pass this
        // gate and open a detail screen for a record whose id is the word
        // "new" — a broken screen instead of a rejected link.
        final isNewChat = type == 'chat' && id == 'new';

        // Validate that the ID follows the expected MongoDB ObjectID format (24 hex characters)
        if (!isNewChat && !isValidMongoId(id)) {
          logs('Invalid ID format in deep link: $id');
          return;
        }

        switch (type) {
          case 'post':
            Get.to(() => PostDeatilPage(), arguments: {"postId": id});
            break;
          case 'video':
            // Public video/reel share landing
            // (`https://beapp.in/app/video/<videoId>`). Both `videoDeepLink`
            // and `shortDeepLink` emit this same path, so the id alone doesn't
            // say whether it's a long video or a short. Fetch it first and let
            // [navigateToVideoDetail] branch on the resolved type: longs open
            // the watch page, shorts open the fullscreen reels player.
            deepLinkNetworkResources.navigateToVideoDetail(id);
            break;
          case 'product':
            // `?seller=<userId>` is optional and carries the STORE the link
            // was shared from. The path id is the master product record, which
            // every store listing the product shares, so without the seller
            // the landing screen has to fall back to whoever created the
            // record — see [ShareProductScreen]. Links minted before the
            // parameter existed simply arrive without it.
            final sellerUserId = uri.queryParameters['seller']?.trim() ?? '';
            Get.to(() => ShareProductScreen(
                  productId: id,
                  sellerUserId:
                      isValidMongoId(sellerUserId) ? sellerUserId : null,
                ));
            break;
          case 'vehicle':
            // Public vehicle share/QR landing
            // (`https://beapp.in/app/vehicle/<id>`). The id is now an
            // **inventory** id — the rebuilt service dropped `/vehicles/*`, so
            // the screen reads `GET /inventory/:id` and hydrates itself from
            // that. Links minted before the rebuild carry ids that no longer
            // resolve; the screen shows its "no longer available" state.
            Get.to(() => VehicleListingDetailScreenV3(listingId: id));
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
            // A `new` chat has no conversation yet, so it opens in
            // initial-message mode with an EMPTY conversationId — chat-service
            // mints the conversation when the first message is sent. Anything
            // else is an existing conversation, opened as before.
            final conversationId = isNewChat ? '' : id;
            final queryParams = uri.queryParameters;
            final chatUserId = queryParams['userId'] ?? '';
            final chatType = queryParams['chatType'] ?? 'personal';
            final chatName = queryParams['name'] ?? '';

            // A vehicle-QR parking report (`&source=vehicle_qr`) also carries
            // the plate, so seed the first message with it: the owner is a
            // stranger to the reporter and would otherwise get a blank chat
            // with no idea why. Scoped to that source so no other `chat/new`
            // link inherits vehicle wording, and to a non-empty plate so the
            // sentence never renders with a hole in it.
            final vehicleNumber = queryParams['vehicleNumber']?.trim() ?? '';
            final prefilledMessage = queryParams['source'] == 'vehicle_qr' &&
                    vehicleNumber.isNotEmpty
                ? 'Regarding your vehicle $vehicleNumber - '
                : null;

            // Validate chatUserId if it's provided.
            //
            // For a NEW chat it is not optional: with no conversation to open,
            // the other party's id is the only thing that says who the chat is
            // with, and an empty one would land the reporter in a chat with
            // nobody.
            if (chatUserId.isEmpty && isNewChat) {
              logs('Deep link chat/new carried no userId — nothing to open');
              return;
            }
            if (chatUserId.isNotEmpty && !isValidMongoId(chatUserId)) {
              logs('Invalid chat user ID in deep link: $chatUserId');
              return;
            }

            // `new` means "the backend does not know whether these two have
            // talked before" — not "they definitely have not". It has no
            // conversation id to send because it never looked one up. So
            // resolve it the way every in-app "message this person" entry
            // point does, rather than assuming a blank thread:
            //
            //   • first-time reporter → no conversation comes back → the chat
            //     opens in initial-message mode and shows its "say Namaste"
            //     starter
            //   • repeat reporter (same car, or the two have chatted before)
            //     → the existing thread opens WITH its history, instead of a
            //     blank screen that hides the messages they already exchanged
            //
            // It also fills in the owner's avatar and contact number, which
            // the link does not carry, so the app bar is not half-empty.
            if (isNewChat) {
              final opened = await getOrPut(() => ChatViewController())
                  .checkChatConnectionAndOpenChat(
                userId: chatUserId,
                name: chatName.isNotEmpty ? chatName : null,
                route: chatType == AppConstants.business_Chat_Type
                    ? AppConstants.route_discover
                    : AppConstants.route_contact,
                prefilledMessage: prefilledMessage,
              );
              // Only when the lookup could not open anything (offline with an
              // empty cache) do we fall through and open the chat blind — a
              // scanned sticker must never dead-end on a snackbar.
              if (opened) break;
              logs('chat/new lookup failed, opening the chat without it');
            }

            if (chatType == AppConstants.business_Chat_Type) {
              Get.to(() => BusinessChatScreenUpdated(
                    conversationId: conversationId,
                    userId: chatUserId,
                    type: chatType,
                    name: chatName,
                    isInitialMessage: isNewChat,
                    prefilledMessage: prefilledMessage,
                  ));
            } else {
              Get.to(() => PersonalChatScreen(
                    conversationId: conversationId,
                    userId: chatUserId,
                    type: chatType,
                    name: chatName,
                    isInitialMessage: isNewChat,
                    prefilledMessage: prefilledMessage,
                  ));
            }
            break;
          case 'profile':
            // Individual profile share/QR landing
            // (`https://beapp.in/app/profile/<userId>`). A `profile` link is
            // generated for *any* individual profile type (self-employed,
            // consultant, gig, social), so we can't assume self-employed here —
            // doing so would call the earn-service-only fetch and show an empty
            // screen for every other type. Resolve the profile type first, then
            // route straight to the matching rich screen.
            _openProfileDeepLink(id);
            break;
          case 'business':
            // Business share-link lands on the public share-preview screen.
            // The URL prefix is just a hint for the account-type pill while the
            // API fetch is in flight — the /share/users/{id}/profile-overview
            // response is the source of truth.
            Get.to(() => ProfileSharePreviewScreen(
                  userId: id,
                  accountTypeHint: AppConstants.business,
                ));
            break;
          default:
            logs('Unknown deep link type: $type');
        }
      } else {
        debugPrint("SEGMENTS==== ELSE");

        // Fallback: try last segment as id (legacy)
        final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (last.isNotEmpty && isValidMongoId(last)) {
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
  static void _openEducationSchool(String id) {
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
  static void _openGroceryStore(String id) {

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
  static void _openHospital(String id) {
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
  static void _openMedicalPharmacy(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => MedicalPharmacyDetailScreen(businessId: id));
  }

  /// Opens [LabDetailScreen] for a laboratory reached via deep link / QR scan
  /// (`https://beapp.in/app/business/labs/<businessId>`). The link carries the
  /// lab's business-profile id — the same `item.id` the in-app lab list passes
  /// into the screen. [LabDetailScreen] does
  /// `Get.find<ViewBusinessDetailsController>()` in its field initializers, so
  /// that controller is registered first; the screen then self-hydrates in its
  /// initState — fetching the business profile, resolving the
  /// `LaboratoryProfile._id`, and loading the tests — so passing the id is
  /// enough to render the full detail view and keep the popular-test /
  /// category / enquiry taps working, mirroring the in-app tap flow from the
  /// lab list ([LabProfilesListScreen]).
  static void _openLaboratory(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => LabDetailScreen(businessId: id));
  }

  /// Opens [FinanceDetailScreen] for a finance business reached via deep link /
  /// QR scan (`https://beapp.in/app/business/financial/<businessId>`). The
  /// screen reads its data from [FinanceDiscoverController], so the controller
  /// is registered first. The full profile is fetched up-front (via
  /// `fetchDetail`) so the screen shows its loader instead of a half-empty
  /// header; [FinanceDiscoverController.selectedDetail] is left null so the
  /// screen's initState doesn't kick off a second fetch. Mirrors the in-app tap
  /// flow from the finance list ([FinanceListingScreen]).
  static void _openFinance(String id) {
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
  static void _openServicesScreen(String id) {
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
  static void _openProductStore(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => VisitProductStoreDetailsScreen(visitUserId: id));
  }

  /// Opens [VisitFoodStoreDetailsScreen] for a food store reached via deep
  /// link / QR scan (`https://beapp.in/app/profile/food/<businessId>`). The
  /// link carries the store's business id used when it was shared. The screen
  /// does `Get.find<ViewBusinessDetailsController>()` in its initState, so that
  /// controller is registered first; the screen then fetches its own profile +
  /// menu behind its own loader, so navigation is instant — mirroring the
  /// in-app tap flow from the profile share-preview redirect
  /// ([ProfileSharePreviewScreen._openBusinessDetail]).
  static void _openFoodStore(String id) {
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: id));
  }

  /// Opens [HmfStoreDetailsDiscoverScreen] for a home-made-food store reached
  /// via deep link / QR scan
  /// (`https://beapp.in/app/business/homemade/food/<userId>`). The link carries
  /// the store owner's user id — the backend resolves the store (home-foods +
  /// tiffins) by userId. The screen registers its own [HmfStoreDetailsController]
  /// (tagged by userId) and self-hydrates behind its own loader, so passing the
  /// id is enough — mirroring the in-app tap flow from the home-made-food list
  /// ([HmfCategoryDiscoverScreen._openStore]).
  static void _openHomeMadeFoodStore(String id) {
    Get.to(() => HmfStoreDetailsDiscoverScreen(userId: id));
  }

  /// Resolves a generic `profile` deep link
  /// (`https://beapp.in/app/profile/<userId>`) to the correct rich profile
  /// screen. The `profile` prefix is emitted by [profileDeepLink] for every
  /// individual profile type, so the target screen isn't known from the URL
  /// alone — we fetch the trimmed share overview (the same
  /// `/share/users/{id}/profile-overview` endpoint used by
  /// [ProfileSharePreviewScreen]) to read `accountType` / `professionType`,
  /// then route:
  ///   • individual + consultant  → [DiscoverProfessionalsViewScreen]
  ///   • individual (skilled/self) → [SelfEmployeeViewDiscoverScreen]
  ///   • business / unknown / null → [ProfileSharePreviewScreen] (which does
  ///     its own business-category resolution, so nothing dead-ends).
  /// Both individual screens hydrate themselves from just the `userId`, so the
  /// self-employed empty-screen case (earn-service fetch returning null for a
  /// non-self-employed user) can no longer happen.
  static Future<void> _openProfileDeepLink(String id) async {
    ShareUser? user;
    try {
      final res = await ShareProfileOverviewRepo().getShareProfileOverview(id);
      if (res.isSuccess && res.response?.data is Map<String, dynamic>) {
        user = ShareProfileOverviewResponse.fromJson(
          res.response!.data as Map<String, dynamic>,
        ).user;
      }
    } catch (e) {
      logs('Profile overview fetch failed for deep link $id: $e');
    }

    final accountType = (user?.accountType ?? '').toUpperCase();
    if (accountType == AppConstants.individual) {
      final type = (user?.professionType ?? '').trim().toLowerCase();
      final isConsultant = type == AppConstants.consultant.toLowerCase() ||
          type.contains('consult') ||
          type.contains('professional');
      if (isConsultant) {
        Get.to(() => DiscoverProfessionalsViewScreen(userId: id));
      } else {
        // Pre-fetch the provider's service document by userId (the by-user
        // endpoint `earn-service/services/user/{id}`, not the category-scoped
        // `fetchEarnServices` list — the deep link carries no profession/
        // category to drive that list). Passing the fetched [ServiceData] as
        // `service` opens the screen already hydrated; if the fetch returns
        // null we still hand over `userId` so the screen self-fetches and
        // shows its own loader/empty state.
        final controller = getOrPut(() => DiscoverController());
        final ServiceData? service =
            await controller.getEarnServiceByUserId(id);
        Get.to(() => SelfEmployeeViewDiscoverScreen(
              service: service,
              userId: id,
            ));
      }
      return;
    }

    // Business, unknown, or a failed overview fetch: hand off to the
    // share-preview screen, which resolves the business category itself and
    // always renders *something* (preview + retry) instead of an empty view.
    Get.to(() => ProfileSharePreviewScreen(
          userId: id,
          accountTypeHint:
              accountType == AppConstants.business ? AppConstants.business : null,
        ));
  }

  /// Opens [DiscoverProfessionalsViewScreen] for a professional/consulting
  /// business reached via deep link / QR scan
  /// (`https://beapp.in/app/business/services/<userId>`). The link carries the
  /// owner (user) id used when the listing was shared. The screen fetches its
  /// own [ProfessionalConsData] via `DiscoverController.getProfessionalByUserId`
  /// in its initState (registering the controller itself), so passing the id as
  /// `userId` is enough to hydrate the full view — mirroring the in-app tap flow
  /// from the Discover professionals list.
  static void _openBusinessProfessionalServices(String id) {
    Get.to(() => DiscoverProfessionalsViewScreen(userId: id));
  }}

/// Owns the app-links plumbing for the whole process.
///
/// The warm-state subscription used to live on `SplashScreen`, which meant it
/// was tied to a widget that is torn down seconds after launch. It survived
/// only because it was never cancelled — a leak the app happened to depend on.
/// Holding it here makes that explicit: one subscription, opened once at
/// launch, alive for as long as the app is.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// The URL the app was launched with, or null on a normal launch.
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  /// Subscribes to links that arrive while the app is already running.
  /// Idempotent — calling it twice does not double-handle a link.
  void startListening() {
    _sub ??= _appLinks.uriLinkStream.listen(
      DeepLinkRouter.routeOrDefer,
      onError: (Object e) => logs('Deep link stream error: $e'),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
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
        if (await _initDeepLinks()) {
          // handled deep link
        } else {
          final sharedMedia = await _getSharedMedia();
          if (accountTypeGlobal.toUpperCase() == AppConstants.individual) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteHelper.getBottomNavigationBarScreenRoute(),
              arguments: {
                ApiKeys.initialIndex: 1,
                if (sharedMedia != null) 'sharedMedia': sharedMedia,
              },
              (Route<dynamic> route) => false,
            );
          } else {
            // Business cold-starts onto its own Me tab (0); individuals → Discover.
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteHelper.getBottomNavigationBarScreenRoute(),
              arguments: {
                ApiKeys.initialIndex: 0,
                if (sharedMedia != null) 'sharedMedia': sharedMedia,
              },
              (Route<dynamic> route) => false,
            );
          }
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

  Future<bool> _initDeepLinks() async {
    _appLinks = AppLinks();
    // Handle links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    var uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(uri);
      return true;
    } else {
      return false;
    }
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
      if (segments.length >= 3 && segments[0] == 'app') {
        final type = segments[1]; // post | video | short | job | product
        final id = segments[2];

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

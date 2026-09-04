import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/deep_link_router.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/view/forward_screen/chat_forward_screen.dart';
import 'package:BlueEra/features/common/onboarding/view/select_language_screen.dart';
import 'package:BlueEra/main.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
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
    // Both secure reads in one parallel batch — each is a platform-channel
    // round trip.
    final prefValues = await Future.wait<dynamic>([
      SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.accountType),
      SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.isUserLogin),
    ]);
    accountTypeGlobal = prefValues[0].toString();
    final String isLoginStatus = prefValues[1] ?? "false";

    // Read the launch URI regardless of login state, and BEFORE any of the
    // early returns below (share intent, notification launch, language
    // selection). A deep link that arrives while signed out has to survive the
    // login, not be discarded by it — the person scanning a vehicle-safety
    // sticker on a stranger's windscreen is exactly the person least likely to
    // already be signed in. See lib/docs/VEHICLE_QR_FLUTTER_GUIDE.md.
    final Uri? initialDeepLink = await _initDeepLinks();
    // The vehicle-safety sticker itself is not app navigation — it is handed
    // straight back to the browser — so it is settled here, before any session
    // check, and never waits on a login the web page does not need.
    final bool bounceToBrowser =
        initialDeepLink != null && DeepLinkRouter.isBrowserBounce(initialDeepLink);
    if (bounceToBrowser) {
      await DeepLinkRouter.handle(initialDeepLink);
    }
    // A guest passes the `isUserLogin` gate but has no profile behind it, so a
    // chat link can't be opened for one either — it is stashed too, and the
    // home shell sends them to account creation (case 4 in the guide).
    final bool canRouteDeepLink = initialDeepLink != null &&
        !bounceToBrowser &&
        isLoginStatus == "true" &&
        !(isGuestUser() && DeepLinkRouter.requiresRealAccount(initialDeepLink));
    if (initialDeepLink != null && !bounceToBrowser && !canRouteDeepLink) {
      // Stashed, not dropped: BottomNavigationBarScreen replays it the moment
      // a real account exists.
      await SharedPreferenceUtils.saveDeferredDeepLink(initialDeepLink.toString());
      logs('Deep link deferred until the user has an account: $initialDeepLink');
    } else if (canRouteDeepLink) {
      // The link the user just acted on wins over anything left stashed from an
      // earlier attempt they abandoned — otherwise the home shell would replay
      // that one on top of this one. Cleared here, before any navigation, so
      // it cannot race the shell's post-frame replay.
      await SharedPreferenceUtils.clearDeferredDeepLink();
    }

    // Fresh install attribution: a shared Play Store link carries the
    // referrer (`referralCode=…`). Capture it before the user reaches
    // signup so onboarding can auto-fill the promo code. Only needed for
    // not-yet-logged-in users; logged-in sessions already have it (or
    // never will). Fire-and-forget: the code is only consumed at signup
    // (minutes away), so the Play Store IPC must not delay the splash.
    if (isLoginStatus != "true") {
      unawaited(_captureInstallReferrerOnce());
    }

    // ✅ Check if app was updated
    // final logoutRequired = await _shouldLogoutAfterUpdate();
    // log('logout required--> $logoutRequired');

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
        // No `initialIndex` — the home shell resolves the landing tab itself
        // (see BottomNavigationBarScreen._resolveLandingIndex): Discover for
        // everyone, Me only for gig workers / riders.
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          (Route<dynamic> route) => false,
        );

        if (sharedText != null && sharedText.isNotEmpty) {
          Get.to(() => ChatForwardScreen(sharedText: sharedText));
        } else {
          Get.to(() => ChatForwardScreen(sharedFiles: attachments));
        }
        return;
      }
    }

    Timer(const Duration(milliseconds: 200), () async {
      // Splash no longer bails out for a killed-state call accept. It used to,
      // because the call screen had replaced `home` and normal navigation would
      // have fought it. The app now boots normally and CallController pushes
      // the call room on top once we land, so splash must run as usual —
      // otherwise the user is left on the splash screen for the whole call.

      // The notification-launch check runs in _initDeferred after runApp —
      // wait for it (bounded) before reading its flag, otherwise this timer
      // can race the check, misread a notification launch as a normal one,
      // and clobber the deep-link routing with home navigation.
      final launchCheck = AppNotificationHandler.notificationLaunchCheckFuture;
      if (launchCheck != null) {
        try {
          await launchCheck.timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      // A killed-state INCOMING CALL launch is the one notification launch with
      // no screen to navigate to: main()'s pre-runApp checks already accepted
      // the call, and the cold-start router deliberately skips `incoming_call`
      // payloads. Holding the splash for that navigation left the navigator
      // with splash as its only page for the whole call — the call room was
      // pushed on top of it, so backing out of the call landed the user on a
      // dead branded page with no way into the app. Boot normally instead, and
      // re-open the call room on top once the home shell is in place.
      final isCallLaunch = AppNotificationHandler.launchedFromIncomingCall ||
          (Get.isRegistered<CallController>() &&
              Get.find<CallController>().isCallLive);
      // Consume only the call marker. `launchedFromNotification` stays as it
      // is: firebaseNotificationSetup()'s iOS cold-start block still gates its
      // own routing on it, and splash reads it exactly once per process.
      if (isCallLaunch) {
        AppNotificationHandler.launchedFromIncomingCall = false;
      }

      // If app was launched by tapping a notification, stay on splash screen
      // and wait for notification handler to navigate to the correct screen.
      if (!isCallLaunch &&
          AppNotificationHandler.launchedFromNotification &&
          isLoginStatus == "true") {
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
        // The cold-start deep link was resolved at the top of this method, but
        // is deliberately NOT navigated to yet — we need to replace the splash
        // with the bottom-nav before pushing the target on top. Otherwise
        // back-press from the deep-link screen pops back to splash (which has
        // no further navigation) and the app appears stuck.
        final sharedMedia = await _getSharedMedia();

        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          (Route<dynamic> route) => false,
          // Deliberately NO `initialIndex`: leaving it unset is what lets the
          // home shell pick the landing tab from the profile globals (which
          // main() has already loaded from prefs by now) instead of the splash
          // hard-coding one. See _resolveLandingIndex.
          arguments: {
            if (sharedMedia != null) 'sharedMedia': sharedMedia,
          },
        );

        // Now that the bottom-nav is the root of the navigator stack,
        // push the deep-link target on top. Back-press from the target
        // will pop to the bottom-nav instead of leaving the user on the
        // dead-end splash screen.
        if (canRouteDeepLink) {
          DeepLinkRouter.handle(initialDeepLink);
        }

        // Killed-state call accept: the `pushNamedAndRemoveUntil` above wipes
        // the whole stack, so a call room already pushed on top of splash went
        // with it. Put it back — now with the home shell underneath, so Back
        // minimises to the top call strip and lands on the app.
        if (isCallLaunch && Get.isRegistered<CallController>()) {
          Get.find<CallController>().reopenCallRoomIfActive();
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

  // The cold-start landing tab is NOT decided here any more. This used to
  // return an index (and returned 0 — the Me tab — for every logged-in user,
  // which is why businesses opened on their own dashboard instead of
  // Discover). The single source of truth is now
  // BottomNavigationBarScreen._resolveLandingIndex, which reads the profile
  // globals: Discover (1) for business and individual alike, Me (0) only for
  // gig workers / riders. A deep link or notification still overrides it by
  // passing its own `initialIndex` through the route arguments.

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
  /// [DeepLinkRouter.handle]; the shared store link encodes the same code as
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

  /// Resolves the cold-start deep link (returns `null` when there isn't one)
  /// and subscribes to warm-state links. The cold-start URI is returned so the
  /// caller can replace splash with the home shell first and *then* push the
  /// target on top — otherwise back-press from the target lands on splash and
  /// the app appears stuck.
  ///
  /// Called for EVERY launch, signed in or not: a link that arrives while
  /// signed out has to survive the login, not be discarded by it. The caller
  /// decides what to do with the returned URI — route it now, or stash it.
  ///
  /// The warm-state subscription deliberately lives in [DeepLinkService], not
  /// in this widget: splash is torn down seconds after launch, and a link
  /// tapped an hour later still has to open. It is process-lifetime state, so
  /// there is nothing here to cancel in `dispose`.
  Future<Uri?> _initDeepLinks() async {
    DeepLinkService.instance.startListening();
    return await DeepLinkService.instance.getInitialLink();
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

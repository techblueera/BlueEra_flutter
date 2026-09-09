import 'package:BlueEra/widgets/go_live_nudge_sheet.dart';
import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/deep_link_router.dart';
import 'package:BlueEra/core/services/chat_media_storage_service.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/account_plan/view/deposit_migration_sheet.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/view/social_main_screen.dart';
import 'package:BlueEra/features/common/Discover/view/v2/discover_screen_v2.dart';
// Discover v1, kept for the swap-back documented at the `case 1:` below.
// Commented rather than deleted: with the import live but the widget only
// named inside a comment, the analyzer reports it as an unused import.
// import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/address/address_picker.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/common/joining_bounce/view/claim_bonus_dialog.dart';
import 'package:BlueEra/features/common/joining_bounce/view/guest_claim_bonus_dialog.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/ai_chat_guest_controller.dart';
import 'package:BlueEra/features/business/widgets/business_qr_promo_sheet.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/ios_update_dialog.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_shimmer.dart';
import 'package:BlueEra/features/common/connect/view/connect_main_page.dart';
import 'package:BlueEra/features/common/delivery_partner/view/gig_work_options_screen.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_parts_screen.dart';
import 'package:BlueEra/features/me/automotive_service/automotive_service_main.dart';
import 'package:BlueEra/features/me/content_creator/content_creator_main.dart';
import 'package:BlueEra/features/me/doctor/doctor_main.dart';
import 'package:BlueEra/features/me/food/view/admin/food_main_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_main.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_main.dart';
import 'package:BlueEra/features/me/kickstart/add_products_kickstart.dart';
import 'package:BlueEra/features/me/laboratory/view/laboratory_main.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_screen.dart';
import 'package:BlueEra/features/me/others/others_main.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/product_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_main.dart';
import 'package:BlueEra/features/me/school/view/school_main.dart';
// Two different screens are called SocialMainScreen: the app's top-level
// Social section (chat/view/social_main_screen.dart, the Feed/Bites/My Post
// tabs) and the "Me > Social" profile below. This file is the only place that
// needs both, so the Me-side one is prefixed rather than renamed.
import 'package:BlueEra/features/me/social/view/social_main.dart' as me_social;
import 'package:BlueEra/features/me/vehicle/v3/view/vehicle_screen_v3.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/location_permission_banner.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/controller/chat_theme_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../delivery_partner/controller/delivery_partner_orders_controller.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final int? initialIndex;
  final SharedMedia? sharedMedia;

  /// When `true` this screen was created only as the BACKGROUND host while a
  /// notification deep link is being routed on top of it. In that case the
  /// Discover-only eager startup work (categories API) is skipped at cold
  /// start and runs the first time the user actually navigates a tab — so a
  /// notification open doesn't boot the home feed behind the target screen.
  /// See docs/backend/notification_fast_open_design.md (Phase 2).
  final bool deferHeavyInit;

  /// When `true` (set only on a fresh individual login — see verifyOTP), the
  /// rider go-live permission gate runs once the personal-profile fetch
  /// settles. Kept login-only so it doesn't re-prompt on every app-open.
  final bool runRiderGoLiveGate;

  /// Land on Discover after signing in — set ONLY by the post-OTP login
  /// navigation.
  ///
  /// Applies to every account type EXCEPT gig workers (riders included, since
  /// the rider professions live under the GIG_WORKER profile type). A gig
  /// worker's whole use of the app is their own dashboard — jobs, go-live,
  /// earnings — so login drops them there like every other entry point does.
  /// Everyone else has just come from outside the app, and Discover is what
  /// shows them what happened while they were gone; their Me tab is one tap
  /// away.
  ///
  /// Both halves of the routing honour that exception — the initState decision
  /// in [_resolveLandingIndex] and the deferred snap in
  /// [_maybeCorrectLandingTabForMeProfile]. The deferred one is what actually
  /// moves a gig worker on a fresh login: the profile fetch is deliberately
  /// deferred past this navigation, so `userProfileTypeGlobal` is still empty
  /// when the shell is built and there is nothing to decide on yet.
  final bool landOnDiscover;

  const BottomNavigationBarScreen(
      {super.key,
      this.initialIndex = 1,
      this.sharedMedia,
      this.deferHeavyInit = false,
      this.runRiderGoLiveGate = false,
      this.landOnDiscover = false});

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int chatNotificationCount = 0;
  final ValueNotifier<bool> bottomBarVisibleNotifier = ValueNotifier(true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bottomBarController = Get.put(BottomBarController());
  final chatViewController = getOrPut(() => ChatViewController());
  final viewPersonalDetailsController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final inventoryController = Get.put(InventoryController());
  final orderController = getOrPut(() => DeliverPartnerOrdersController());
  final dialogService = Get.put(DialogService());

  void handleRejectOrder(String orderId) {
    orderController.updateOrderStatusFromPialot(
      {ApiKeys.action: "reject"},
      orderId,
    );
  }

  void handleAcceptOrder(String orderId) {
    orderController.updateOrderStatusFromPialot(
      {ApiKeys.action: "accept"},
      orderId,
    );
  }

  /// nav bar + subscription peek by flipping
  /// `BottomBarController.isBottomNavVisible` — no callback prop-drilling.
  Worker? _bottomNavVisibilityWorker;

  @override
  void initState() {
    super.initState();
    _bottomNavVisibilityWorker =
        ever<bool>(bottomBarController.isBottomNavVisible, (visible) {
      _toggleAppBar(visible);
    });
    _checkAndFetchLocationData();
    // NOTE: this used to clear the rider's Android PiP flag on every launch of
    // the shell, undoing whatever the rider screens had armed. There is no
    // rider PiP any more — riders navigate in the phone's Google Maps and the
    // order card carries the job — so there is nothing left to disarm.
    // if (isGuestUser()) {
    //   logs("DIALOGE CALL");
    //   _checkAndShowDialog();
    // }
    // On a notification deep-link open this screen is just the background
    // host — skip the Discover categories fetch until the user navigates a
    // tab (see _ensureHeavyInit). On a normal launch it runs as before.
    if (!widget.deferHeavyInit) {
      _getAllCategories();
      _heavyInitDone = true;
    }
    _initializeControllers();
    _initializeUserData();
    _initializeSocketConnections();
    _initializeChatMediaFolders();
    checkByRiderCall();
    // Resolved BEFORE the first build so frame 1 renders the tab the user
    // actually lands on — but only into a plain field, NOT into the Rx. Writing
    // `currentIndex` here would notify listeners while the framework is still
    // building: mounting this screen via `Get.offAllNamed` (backing out of
    // account creation, for one) happens mid-build, and any already-mounted Obx
    // watching the index then throws "setState() called during build".
    // [_tabContent] reads this field on its first pass; the post-frame callback
    // below commits it to the Rx, where notifying is safe.
    _pendingLandingIndex = _resolveLandingIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Store update check — once per process, and never on a deep-link
      // background host. Both gates live in _getPackageData.
      _getPackageData();
      _commitLandingTab();
      _handlePostFrameInitialization();
      // One-shot per launch: surface the joining-bonus claim popup when the
      // profile API says so. Skipped on deep-link background hosts.
      if (!widget.deferHeavyInit) {
        _maybeShowJoiningBonus();
      } else {
        logs("JOINING_BONUS: skip — deferHeavyInit=true "
            "(deep-link/background host)");
      }
      // _setupCallKitEventListener();
    });
  }

  /// One-shot PER DEVICE (not per launch): show the joining-bonus claim popup.
  /// The `joining_bounce` object is read from the profile response the app
  /// already loads (business → business profile, individual → personal profile)
  /// — no extra API call. The gate is the backend's `show_card` flag (surfaced
  /// via [JoiningBounce.shouldShow]); when it is false there is nothing to show.
  /// Claiming is handled inside the dialog.
  ///
  /// When the user DOES claim, the backend flips `show_card` off and the card
  /// never returns on its own. When they just close it, `show_card` stays true
  /// forever — which used to re-pop the card on every single app open. So the
  /// display itself is also recorded locally ([_markJoiningBonusShownOnDevice])
  /// and that record is the first gate: seen once, never auto-shown again.
  static bool _joiningBonusShown = false;
  Worker? _joiningBonusWorker;

  /// Per-account prefix for the "this card has already been shown" flag.
  /// Deliberately in SharedPreferences, NOT flutter_secure_storage: logout
  /// wipes secure storage wholesale (clearPreferenceDataOnly), which would
  /// resurrect the popup for a user who had already dismissed it.
  static const String _joiningBonusShownPrefix = 'joining_bonus_shown_';

  /// Keyed per account so a different login on the same device still gets its
  /// own one-time card ('guest' before an account exists).
  static String get _joiningBonusPrefKey =>
      '$_joiningBonusShownPrefix${userId.isNotEmpty ? userId : 'guest'}';

  static Future<bool> _joiningBonusShownOnDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_joiningBonusPrefKey) ?? false;
    } catch (_) {
      // Storage hiccup — fail OPEN (show the card) rather than silently
      // swallowing a bonus the user has never seen.
      return false;
    }
  }

  /// Records that the card has been put on screen. Written at DISPLAY time,
  /// not on dismiss, so a process kill while the dialog is open can't hand out
  /// a second showing.
  static Future<void> _markJoiningBonusShownOnDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_joiningBonusPrefKey, true);
    } catch (_) {}
  }

  Future<void> _maybeShowJoiningBonus() async {
    if (_joiningBonusShown) {
      logs("JOINING_BONUS: skip — already shown this launch");
      return;
    }
    if (await _joiningBonusShownOnDevice()) {
      logs("JOINING_BONUS: skip — already shown once on this device "
          "(key=$_joiningBonusPrefKey)");
      return;
    }
    if (!mounted) return;
    if (isGuestUser()) {
      // Guests have no profile (and no real bonus), so show the guest scratch
      // card — it never exposes an amount; scratching just unlocks the
      // "Create Profile" CTA. Shown once per device, like the real card.
      logs("JOINING_BONUS: guest user — showing GuestClaimBonusDialog");
      _joiningBonusShown = true;
      _markJoiningBonusShownOnDevice();
      _joiningBonusWorker?.dispose();
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const GuestClaimBonusDialog(),
      );
      return;
    }

    final bool business = isBusiness();
    final businessController = business
        ? getOrPut(() => ViewBusinessDetailsController(), permanent: true)
        : null;
    final Rxn<JoiningBounce> source = business
        ? businessController!.joiningBounce
        : viewPersonalDetailsController.joiningBounce;
    logs("JOINING_BONUS: gate started (isBusiness=$business)");

    void show(JoiningBounce? bounce) {
      if (_joiningBonusShown) {
        logs("JOINING_BONUS: show() skip — already shown");
        return;
      }
      if (!mounted) {
        logs("JOINING_BONUS: show() skip — widget not mounted");
        return;
      }
      if (bounce == null) {
        logs("JOINING_BONUS: show() skip — bounce is null "
            "(joining_bounce not parsed from profile yet)");
        return;
      }
      logs("JOINING_BONUS: bounce received -> "
          "joiningBounceId='${bounce.joiningBounceId}', "
          "isClaimed=${bounce.isClaimed}, showCard=${bounce.showCard}, "
          "enrolled=${bounce.enrolled}, status='${bounce.status}', "
          "eligible=${bounce.eligible}, bonusInr=${bounce.bonusInr}, "
          "shouldShow=${bounce.shouldShow}");
      if (!bounce.shouldShow) {
        logs("JOINING_BONUS: show() skip — shouldShow=false "
            "(backend show_card flag is not true)");
        return;
      }
      _joiningBonusShown = true;
      // Burn the one-time device slot the moment it goes on screen — whether
      // the user claims or just closes it, this card is done auto-popping.
      _markJoiningBonusShownOnDevice();
      _joiningBonusWorker?.dispose();
      logs("JOINING_BONUS: showing ClaimBonusDialog ✅");
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => ClaimBonusDialog(bounce: bounce),
      );
    }

    // Fetch-then-check: the profile response carries `joining_bounce`, so we
    // must have profile data before deciding. If nothing is loaded yet, fetch
    // and await it here (covers the case where the boot fetch was skipped or
    // already finished without a value). A fetch already in flight (LOADING)
    // is left alone — the reactive worker below catches its completion.
    if (source.value == null) {
      final Status? status = business
          ? businessController!.viewBusinessResponse.status
          : viewPersonalDetailsController.viewPersonalResponse.value.status;
      logs("JOINING_BONUS: no bounce yet — profile status=$status");
      if (status == null ||
          status == Status.INITIAL ||
          status == Status.ERROR) {
        logs("JOINING_BONUS: fetching profile before checking…");
        if (business) {
          await businessController!.viewBusinessProfile();
        } else {
          await viewPersonalDetailsController.viewPersonalProfile();
        }
        logs("JOINING_BONUS: profile fetch finished — re-checking");
      } else {
        logs("JOINING_BONUS: profile fetch already in flight — "
            "will check when it completes");
      }
    }

    if (!mounted) return;

    // Check against whatever we have now (may have just been fetched)…
    logs("JOINING_BONUS: source.value is "
        "${source.value == null ? 'null' : 'present'} after fetch step");
    show(source.value);

    // …and keep listening so a later/concurrent profile refresh still triggers
    // the card if it wasn't ready yet.
    if (!_joiningBonusShown) {
      logs("JOINING_BONUS: not shown yet — listening for profile updates");
      _joiningBonusWorker = ever<JoiningBounce?>(source, show);
    }
  }

  Future<void> checkByRiderCall() async {
    String? orderId = await getCurrentCall();
    if (orderId != null) {
      // Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
      Future.delayed(Duration(seconds: 1), () {
        FlutterCallkitIncoming.endAllCalls();
      });
    }
  }

  Future<String?> getCurrentCall() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        // Skip voice/video calls — those are handled by CallController
        final extra =
            Map<String, dynamic>.from(calls[0]['extra'] as Map? ?? {});
        final operation = (extra['operation'] ?? '').toString();
        if (operation == 'incoming_call') return null;

        bool accepted = calls[0]['accepted'];

        if (accepted) {
          return extra['orderId'].toString();
        } else {
          return 'rejected';
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> _checkAndFetchLocationData() async {
    // Cold start already kicks off a fetch in main._initDeferred; only
    // fetch here if that hasn't populated coords yet (avoids a duplicate
    // permission prompt / position request).
    if (LocationService.lat == 0.0 && LocationService.lng == 0.0) {
      await LocationService.fetchLocation();
    }
  }

  /// One-shot guard for the deferred (deep-link) home init. On a normal launch
  /// this is set in initState; on a deferred open it stays false until the
  /// user first taps a bottom-nav tab.
  bool _heavyInitDone = false;

  /// Runs the home init that was skipped because this screen was created as a
  /// deep-link background host. Safe to call repeatedly — only fires once.
  void _ensureHeavyInit() {
    if (_heavyInitDone) return;
    _heavyInitDone = true;
    _getAllCategories();
    // Run the home-boot data fetches that were skipped because this screen was
    // created only as a deep-link background host (see initState /
    // _initializeUserData / _handlePostFrameInitialization).
    if (isIndividual()) {
      _initializeIndividualUser();
    }
    _fetchOwnProfileIfNeeded();
  }

  void _getAllCategories() {
    // Defer to after the first frame: the cache-first path applies cached
    // categories synchronously via `assignAll` on observable lists, which
    // would notify an `Obx` mid-build and throw "markNeedsBuild called
    // during build" if invoked straight from initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().loadCategoriesCacheFirstThenRefresh();
    });
  }

  /// One-shot PER PROCESS, not per mount. This shell is mounted more than once
  /// in a session — `Get.offAllNamed` after OTP login, backing out of account
  /// creation, and the notification re-navigation all rebuild it — and without
  /// this guard each remount fired another store check and could re-throw the
  /// full-screen Play update sheet at someone who had just dismissed it.
  static bool _updateCheckStarted = false;

  /// Store update check, run once after the first frame. Android hands the
  /// whole flow to Play; iOS gets [showIosUpdateDialog].
  Future<void> _getPackageData() async {
    // Deep-link background host: this screen only exists behind the screen the
    // notification actually opened, so don't drop a store prompt on top of it.
    // The check simply waits for the next real app open.
    if (widget.deferHeavyInit) return;
    if (_updateCheckStarted) return;
    _updateCheckStarted = true;
    await _checkForUpdate();
  }

  /// Verbose update logging, debug builds only — `debugPrint` is NOT compiled
  /// out of release, and this path is chatty enough to be noise in a prod
  /// logcat.
  void _updateLog(String message) {
    if (kDebugMode) debugPrint("[UpdateCheck] $message");
  }

  Future<void> _checkForUpdate() async {
    try {
      _updateLog("START (platform=${Platform.operatingSystem})");

      if (Platform.isAndroid) {
        // Play owns the entire Android flow — its own UI, its own download and
        // install. `packageInfo` isn't needed here at all, so it is fetched
        // only on the iOS branch below.
        final InAppUpdateManager manager = InAppUpdateManager();
        final AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();

        if (appUpdateInfo == null) {
          // Normal on any build Play doesn't own: sideloaded APKs, debug
          // builds, devices without Play Services.
          _updateLog("Android: checkForUpdate returned null");
          return;
        }

        _updateLog("Android availability=${appUpdateInfo.updateAvailability} "
            "immediateAllowed=${appUpdateInfo.immediateAllowed} "
            "flexibleAllowed=${appUpdateInfo.flexibleAllowed} "
            "availableVersionCode=${appUpdateInfo.availableVersionCode}");

        if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress) {
          _updateLog("Resuming in-progress immediate update…");
          _logUpdateFlowResult('immediate',
              await manager.startAnUpdate(type: AppUpdateType.immediate));
        } else if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          if (appUpdateInfo.immediateAllowed) {
            _updateLog("Starting immediate update flow…");
            _logUpdateFlowResult('immediate',
                await manager.startAnUpdate(type: AppUpdateType.immediate));
          } else if (appUpdateInfo.flexibleAllowed) {
            _updateLog("Starting flexible update flow…");
            _logUpdateFlowResult('flexible',
                await manager.startAnUpdate(type: AppUpdateType.flexible));
          } else {
            _updateLog(
                "Update available, but neither flow is permitted by Play");
          }
        } else {
          _updateLog("No update available");
        }
      } else if (Platform.isIOS) {
        final PackageInfo packageInfo = await PackageManager.getPackageInfo();
        if (packageInfo.packageName.isEmpty) {
          // PackageManager swallows failures into an empty PackageInfo(); an
          // empty bundle id would just make the iTunes lookup return nothing.
          _updateLog("iOS: no bundle id — skipping store lookup");
          return;
        }
        // The iTunes lookup is per STOREFRONT: querying a country the app
        // isn't published in comes back empty and the plugin reports no store
        // version at all. Use the device's own region (the plugin reads it
        // from NSLocale) and fall back to the home market.
        final String region =
            packageInfo.regionCode.isNotEmpty ? packageInfo.regionCode : 'IN';
        _updateLog("iOS: querying App Store (region=$region)…");
        final VersionInfo versionInfo = await UpgradeVersion.getiOSStoreVersion(
            packageInfo: packageInfo, regionCode: region);
        _updateLog("iOS local=${versionInfo.localVersion} "
            "store=${versionInfo.storeVersion} "
            "canUpdate=${versionInfo.canUpdate}");
        if (!versionInfo.canUpdate) return;
        if (versionInfo.appStoreLink.isEmpty) {
          // Nothing for the Update button to open — a prompt that can't act
          // is worse than no prompt.
          _updateLog("iOS: update available but no App Store link returned");
          return;
        }
        if (!mounted) return;
        await showIosUpdateDialog(context, versionInfo);
      }
      _updateLog("COMPLETE");
    } catch (e, stackTrace) {
      _updateLog("ERROR: $e");
      _updateLog("StackTrace: $stackTrace");
    }
  }

  /// `startAnUpdate` returns NULL on success and a message only when the flow
  /// failed or the user cancelled it — logging the raw value made a completed
  /// update read as "result: null" and a cancellation read like a success.
  void _logUpdateFlowResult(String type, String? message) {
    _updateLog(message == null
        ? "$type update accepted by user"
        : "$type update did not start: $message");
  }

  void _initializeControllers() {
    getOrPut(() => ChatThemeController());
  }

  Future<void> _initializeUserData() async {
    AppNotificationHandler().getInitialMsg();
    AppNotificationHandler().onMsgOpen();
    // The channel-details fetch is part of the home boot. When this screen is
    // only the deep-link background host, skip it now — it runs from
    // _ensureHeavyInit() the first time the user navigates a tab.
    if (widget.deferHeavyInit) return;
    if (isIndividual()) await _initializeIndividualUser();
  }

  Future<void> _initializeIndividualUser() async {
    await Future.delayed(Duration(seconds: 2));

    if (channelId.isNotEmpty) return;

    final channelModel = await getChannelDetails();
    if (channelModel?.data == null) return;

    final data = channelModel!.data;
    channelId = data.id;
    channelName = data.name;
    channelOwner = data.username;
    // channelOwner = data.ownership.claimedBy;

    await Future.wait([
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channel_Id, channelId),
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channelName, channelName),
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channelOwner, channelOwner),
    ]);
  }

  void _initializeSocketConnections() {
    chatViewController.connectSocket().then((_) {
      _handleSharedMedia();
    });
    // groupChatViewController.connectSocket();
  }

  /// Pre-create BlueEra media folders and request storage permissions early.
  void _initializeChatMediaFolders() {
    ChatMediaStorageService.initializeMediaFolders();
    if (Platform.isIOS) {
      ChatMediaStorageService.requestPhotoLibraryPermission();
    }
  }

  void _handleSharedMedia() {
    final media = widget.sharedMedia;
    if (media == null || !mounted) return;

    final sharedText = media.content;
    final attachments = media.attachments ?? [];

    if (sharedText != null && sharedText.isNotEmpty) {
      Get.to(() => ChatForwardScreen(sharedText: sharedText));
    } else if (attachments.isNotEmpty) {
      Get.to(() => ChatForwardScreen(sharedFiles: attachments));
    }
  }

  /// Picks the tab the app opens on. PURE — it only computes, it must never
  /// touch `currentIndex`, because it runs from `initState` and writing an
  /// observable there notifies listeners mid-build.
  ///
  /// `BottomBarController.currentIndex` is born at 0 (Me), so whatever the
  /// first frame reads is what it paints. Deciding after that frame made the
  /// app mount the user's me-section dashboard for a single frame on every
  /// launch: its `initState` fired the tab's boot APIs, then the index flipped
  /// to Discover and disposed it while those requests were still in flight.
  /// Hence the split: resolve here, paint from [_pendingLandingIndex], commit
  /// in [_commitLandingTab].
  ///
  /// Every input here is a global resolved in `main()` before `runApp`, so
  /// there is nothing to wait a frame for.
  /// Landing tab for this mount, held until the first frame is done.
  ///
  /// Non-null only between `initState` and the post-frame commit. While set it
  /// OVERRIDES `currentIndex` for [_tabContent], which is what keeps frame 1 on
  /// the right tab without touching an observable mid-build.
  int? _pendingLandingIndex;

  /// Moves the resolved landing tab into the Rx. Called from the post-frame
  /// callback — outside the build phase — so the Obx rebuild it triggers is
  /// legal. Clears the override FIRST so that rebuild reads the live value.
  void _commitLandingTab() {
    final landing = _pendingLandingIndex;
    if (landing == null) return;
    _pendingLandingIndex = null;
    // Assigning the same value is a no-op in GetX (no notification), which is
    // exactly right: the tab on screen already matches.
    bottomBarController.currentIndex.value = landing;
  }

  /// True once the user has actually tapped a bottom-nav tab on this mount.
  /// Guards [_maybeCorrectLandingTabForMeProfile] so the deferred correction
  /// can never yank someone off a tab they picked themselves.
  bool _userPickedTab = false;

  /// Single source of truth for the landing tab. Callers (splash, post-login
  /// nav) deliberately pass NO `initialIndex` so this decides; only an
  /// explicit tab request (deep link / notification) overrides it.
  int _resolveLandingIndex() {
    if (isBusiness()) {
      // Business users land on Discover (1) by default on app open / login /
      // signup — same as individuals. They used to open straight onto their
      // own Me dashboard, which meant the app opened on a screen the owner
      // already knows and hid everything happening around them; their shop is
      // one tab away either way. An explicit deep-link tab (notification, or a
      // post-action nav that requests a specific tab) still wins because it
      // passes a non-null initialIndex.
      return widget.initialIndex ?? 1;
    }
    // Signing in used to be a blanket exception: EVERYONE landed on Discover,
    // gig workers included. Gig workers are now excluded from that exception —
    // they go to their Me dashboard on login like they do on every other entry
    // point. Every other account type (business, and the other three individual
    // profile types) still lands on Discover.
    //
    // On a FRESH login this still returns Discover, because the profile fetch
    // is deferred and `userProfileTypeGlobal` is empty at this moment. It is
    // [_maybeCorrectLandingTabForMeProfile] that actually moves a gig worker
    // across once their type lands. On a cold start the globals are already in
    // prefs, so [_wantsMeTab] is true here and the tab is right immediately.
    if (widget.landOnDiscover && !_wantsMeTab) {
      return widget.initialIndex ?? 1;
    }
    // Otherwise riders (bike rider / car-taxi driver) and gig workers always
    // land on the Me tab (index 0) — regardless of whether their profile has
    // been created yet — so their dashboard / onboarding is front and centre.
    // Every other individual type uses the requested initial tab (Discover by
    // default).
    return _wantsMeTab ? 0 : (widget.initialIndex ?? 1);
  }

  /// Whether this account's home is the Me tab rather than Discover.
  ///
  /// Riders are a PROFESSION (bike rider, car-taxi driver, …) that lives under
  /// the GIG_WORKER profile type, so the second test already covers them; the
  /// first is kept because `userProfessionGlobal` and `userProfileTypeGlobal`
  /// are populated from different payloads and can land out of step.
  ///
  /// False whenever the globals are still empty — which is the case for the
  /// whole of a fresh login until the deferred profile fetch settles.
  bool get _wantsMeTab =>
      isRiderProfession(userProfessionGlobal) ||
      userProfileTypeGlobal == GIG_WORKER;

  void _handlePostFrameInitialization() {
    // Own-profile fetch is part of the home boot. When this screen is only the
    // deep-link background host (deferHeavyInit), skip it until the user first
    // navigates a tab — it then runs from _ensureHeavyInit().
    final boot = !widget.deferHeavyInit;
    // A deeplink that arrived before the user had an account to open it with
    // (signed out, or on a guest account) was stashed rather than dropped.
    // This is the one place every route into a real session converges —
    // login, signup, and a guest upgrading their account all land here — so it
    // is where the link gets replayed. Skipped on a deep-link background host,
    // which already has its own target to open.
    if (boot) unawaited(_resumeDeferredDeepLink());
    // Deposit → account-plan migration offer. Not account-type specific: both
    // businesses and individuals share the go-live gate, so this sits outside
    // the branch below. The helper asks the backend whether this user is even
    // a deposit holder and shows nothing otherwise.
    if (boot) showDepositMigrationIfNeeded(context);
    if (isBusiness()) {
      // Landing tab is already resolved — see _resolveLandingIndex (initState)
      // and _commitLandingTab (this same post-frame callback, just above).
      //
      // Keep the controller registered even on a deferred open so any
      // Get.find<ViewBusinessDetailsController>() elsewhere stays safe; only
      // the network fetch is part of the home boot and gets deferred.
      final businessCtrl =
          getOrPut(() => ViewBusinessDetailsController(), permanent: true);
      // Already in the business branch — fetch directly (no second isBusiness
      // check), unless it's already loaded.
      if (boot && businessCtrl.viewBusinessResponse.status != Status.COMPLETE) {
        // whenComplete guarantees the navigate-first Me-tab loader clears once
        // the fetch settles: success flips isBusinessProfileReady via
        // _applyBusinessProfileData, and this also covers failure/timeout so
        // the loader can't get stuck (it then falls through to the normal
        // fallback instead of spinning forever).
        businessCtrl.viewBusinessProfile().whenComplete(
            () => businessCtrl.isBusinessProfileReady.value = true);
      }
      // A merchant with an empty catalogue opens straight onto Quick Upload.
      // Waits for the profile itself and checks every reason not to show, so it
      // is safe to call unconditionally here; skipped entirely on a deep-link
      // background host, which is not really an app open.
      if (boot) _maybeShowAddProductsKickstart();
    } else {
      // Individual own-profile fetch — the personal profile carries
      // the Go-Live gate, joining_bounce, etc. Fetch directly
      // here since we already know it's an individual, unless already loaded.
      if (boot &&
          viewPersonalDetailsController.viewPersonalResponse.value.status !=
              Status.COMPLETE) {
        // forceRefresh so we actually hit /user/get on every launch (the
        // method is cache-first and would otherwise skip the network on
        // cached launches) — needed for a fresh go-live gate.
        // It still shows the cached profile first, then updates from the API.
        final fetch = viewPersonalDetailsController.viewPersonalProfile(
            forceRefresh: true);
        // whenComplete fires when the fetch settles (success, non-success
        // response, or early return all complete the future) — so the
        // navigate-first Me-tab loader always clears, and on a fresh individual
        // login the rider go-live gate runs once userProfessionGlobal is known.
        fetch.whenComplete(() {
          viewPersonalDetailsController.isPersonalProfileReady.value = true;
          _maybeCorrectLandingTabForMeProfile();
          if (widget.runRiderGoLiveGate) _maybeRunRiderGoLiveGate();
        });
      } else {
        // Already loaded (globals known) — mark ready and, on a fresh login,
        // run the rider gate directly.
        viewPersonalDetailsController.isPersonalProfileReady.value = true;
        if (widget.runRiderGoLiveGate) _maybeRunRiderGoLiveGate();
      }
    }
  }

  /// Set once a guest has already been asked to finish signing up for a
  /// stashed link, so backing out of account creation and returning to the
  /// home shell does not re-open it on a loop. Process-lifetime, not
  /// persisted: the ask is worth repeating on a later launch, just not on
  /// every rebuild of this screen.
  static bool _guestAskedToUpgradeForDeepLink = false;

  /// Replays a deeplink that could not be routed when it arrived.
  ///
  /// The vehicle-safety QR is the case this exists for: whoever taps "Report
  /// parking issue" on a stranger's windscreen is rarely signed in, so the
  /// link lands on the login screen and used to die there. Now it waits in
  /// secure storage and opens the owner's chat — with the plate already in the
  /// input — the moment sign-in completes.
  ///
  /// A guest is still not a real account (chat has nobody to reply to), so a
  /// link that [DeepLinkRouter.requiresRealAccount] stays stashed and the
  /// guest is sent to account creation instead, matching every other in-app
  /// chat entry point.
  Future<void> _resumeDeferredDeepLink() async {
    final pending = await SharedPreferenceUtils.getDeferredDeepLink();
    if (pending == null || pending.isEmpty) return;

    final uri = Uri.tryParse(pending);
    if (uri == null) {
      logs('Deferred deep link is not a valid URL, dropping: $pending');
      await SharedPreferenceUtils.clearDeferredDeepLink();
      return;
    }

    if (isGuestUser() && DeepLinkRouter.requiresRealAccount(uri)) {
      if (_guestAskedToUpgradeForDeepLink) return;
      _guestAskedToUpgradeForDeepLink = true;
      // Keep the link stashed — it is replayed by this same method once the
      // guest finishes and lands back on the home shell with a real account.
      createProfileScreen();
      return;
    }

    // Cleared BEFORE routing, never after: a failure inside the routing must
    // not leave a link that reopens on every launch from here on.
    await SharedPreferenceUtils.clearDeferredDeepLink();
    await DeepLinkRouter.handle(uri);
  }

  /// App-open Quick Upload page for a catalogue business (grocery / food /
  /// product) that has published nothing — see
  /// [showAddProductsKickstartIfNeeded], which owns every gate: account type,
  /// business type, whether the catalogue is actually empty, and whether
  /// anything else is already on screen.
  ///
  /// Fired from here rather than from the Me screens because business accounts
  /// land on Discover, so the merchant home may never mount on a launch — and
  /// an empty shop is exactly the case where they have no reason to open it.
  ///
  /// Deliberately NOT awaited: it waits on the profile fetch and a catalogue
  /// lookup, and nothing else in the boot sequence depends on the result.
  void _maybeShowAddProductsKickstart() {
    if (!mounted) return;
    showAddProductsKickstartIfNeeded(context);
  }

  /// Re-runs the landing-tab decision once the personal-profile fetch has
  /// resolved `userProfileTypeGlobal` / `userProfessionGlobal`.
  ///
  /// Needed because on a FRESH login those globals don't exist yet — verifyOTP
  /// navigates here before the profile is fetched (deliberately: the fetch is a
  /// full round-trip and would sit on the OTP screen). So the shell lands on
  /// Discover, and this snaps gig workers / riders onto Me the moment their
  /// type lands. On a cold start the globals are already loaded from prefs, so
  /// [_resolveLandingIndex] got it right in initState and this is a no-op.
  ///
  /// Deliberately conservative — it only moves the tab when NOTHING else has
  /// claimed it: no explicit `initialIndex` (deep link / notification), no tab
  /// tap by the user, and the app is still sitting on the Discover default.
  void _maybeCorrectLandingTabForMeProfile() {
    if (!mounted) return;
    if (_userPickedTab) return;
    if (widget.initialIndex != null) return;
    // A login mount sits on Discover for everyone EXCEPT gig workers, who are
    // sent to their Me dashboard. On a fresh login this correction is the only
    // thing that can move them, because the profile type lands after
    // navigation — `_resolveLandingIndex()` had nothing to decide on when the
    // shell was built. Every other account type keeps the Discover landing.
    if (widget.landOnDiscover && !_wantsMeTab) return;
    if (bottomBarController.currentIndex.value != 1) return;
    if (_resolveLandingIndex() != 0) return;
    logs("LANDING_TAB: profile resolved to "
        "'$userProfileTypeGlobal'/'$userProfessionGlobal' — moving to Me tab");
    bottomBarController.onChangeIndex(0);
  }

  /// Rider go-live permission gate — runs after the personal-profile fetch on
  /// a fresh individual login (see [BottomNavigationBarScreen.runRiderGoLiveGate]).
  ///
  /// We pass runRiderGoLiveGate=true for EVERY individual login because the
  /// profile type isn't known yet at verifyOTP time. Of the four individual
  /// profile types (SOCIAL_PROFILE / GIG_WORKER / SELF_EMPLOYED / PROFESSIONAL),
  /// this only does anything for GIG_WORKER riders — the `isRider` guard below
  /// makes it a no-op for the other three, so passing the flag unconditionally
  /// is safe. (Riders are the BIKE_RIDER / CAR_TAXI_DRIVER professions, which
  /// live under the GIG_WORKER profile type.)
  ///
  /// Riders must be reachable for live dispatch, so if the required permissions
  /// (background location + overlay) aren't granted we push the permission
  /// screen on top of the home shell. Gates on areRequiredGranted (NOT
  /// areAllGranted) — battery optimization can't be reliably granted on
  /// Android 13+/16. Covers all five rider professions via [isRiderProfession]
  /// (BIKE_RIDER, AUTO_TAXI, CAR_TAXI, CAR_TAXI_DRIVER, GOODS_TAXI).
  Future<void> _maybeRunRiderGoLiveGate() async {
    if (!isRiderProfession(userProfessionGlobal)) return;
    if (await GoLivePermissionService.areRequiredGranted()) return;
    if (!mounted) return;
    await Get.to(() => const GoLivePermissionScreen());
  }

  /// Fetches the signed-in user's own profile (business or personal) unless it
  /// is already loaded. Part of the home boot; gated behind [deferHeavyInit] so
  /// a notification deep-link open doesn't fire it behind the target screen.
  void _fetchOwnProfileIfNeeded() {
    if (isBusiness()) {
      final viewProfileController =
          getOrPut(() => ViewBusinessDetailsController(), permanent: true);
      if (viewProfileController.viewBusinessResponse.status !=
          Status.COMPLETE) {
        viewProfileController.viewBusinessProfile();
      }
    } else {
      if (viewPersonalDetailsController.viewPersonalResponse.value.status !=
          Status.COMPLETE) {
        viewPersonalDetailsController.viewPersonalProfile();
      }
    }
  }

  // GET CHANNEL DETAILS...
  Future<ChannelModel?> getChannelDetails() async {
    try {
      ResponseModel response =
          await ChannelRepo().getChannelDetails(channelOrUserId: userId);

      if (response.statusCode == 200) {
        return ChannelModel.fromJson(response.response?.data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _bottomNavVisibilityWorker?.dispose();
    _joiningBonusWorker?.dispose();
    bottomBarVisibleNotifier.dispose(); // Clean up
    // Only fully dispose socket if no active call — otherwise the socket
    // gets killed when the widget tree rebuilds after returning from the call
    // room and can never reconnect (listeners are cleared permanently).
    final hasActiveCall = Get.isRegistered<CallController>() &&
        Get.find<CallController>().callStatus.value != CallStatus.idle;
    // Also skip when a notification tap is re-navigating the root onto a new
    // bottom-nav host (e.g. the admin_broadcast flow). This dispose fires while
    // the incoming host is being built; tearing the socket down here would kill
    // the connection that tap just warmed and drop the broadcast-history fetch,
    // leaving the tapped message invisible until the thread is reopened.
    if (!hasActiveCall &&
        !AppNotificationHandler.suppressSocketDisposeForRenav) {
      chatViewController.disposeSocket();
    }
    super.dispose();
  }

  final callController = getOrPut(() => CallController());

  /// The active tab, built exactly ONCE and reused for the whole lifetime of
  /// this screen. Its own [Obx] rebuilds the inner tab subtree only when
  /// [BottomBarController.currentIndex] changes (a real tab switch). Because it
  /// is a stable widget instance, nothing else — call/live status ticks, the
  /// hide-on-scroll toggle, the keyboard opening — rebuilds the page; those
  /// only reposition or wrap this same element.
  late final Widget _tabContent = Obx(() {
    // Still subscribe to the Rx (this is what rebuilds on a real tab switch),
    // but let the not-yet-committed landing tab win on the first pass — see
    // [_pendingLandingIndex]. Without that, frame 1 would paint index 0 (the Me
    // tab) for every user, mounting a whole me-section dashboard and firing its
    // boot APIs just to tear it down a frame later.
    final live = bottomBarController.currentIndex.value;
    final index = _pendingLandingIndex ?? live;
    // Single app-wide hide-on-scroll wrapper so EVERY tab and every "Me"
    // sub-screen (individual + business) gets the same behaviour — including
    // the ones that don't wrap themselves (SelfEmployee, Professionals, Food,
    // Grocery, Hospital, Others, Product, Manufacturer, Vehicle, …). Keyed per
    // index so each tab keeps its own scroll accumulator; tab switches reset
    // visibility in BottomBarController.onChangeIndex.
    return BottomNavHideOnScroll(
      key: ValueKey('navHideOnScroll_$index'),
      child: _getScreen(index),
    );
  });

  @override
  Widget build(BuildContext context) {
    // Capture keyboard state at the top of build, before the Scaffold's
    // `resizeToAvoidBottomInset: true` strips viewInsets from the
    // MediaQuery handed to its body. The build method depends on
    // MediaQuery (we just read it), so it re-runs whenever the keyboard
    // shows or hides — propagating the new value through the closures
    // below.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      key: _scaffoldKey,
      body: ValueListenableBuilder(
          valueListenable: bottomBarVisibleNotifier,
          builder: (context, isVisible, _) {
            return Stack(
              children: [
                // Offset wrapper — reacts to call / rider-live status only and
                // re-positions the stable [_tabContent] element without
                // rebuilding the page. A call heartbeat / rider-live refresh no
                // longer re-runs _getScreen → resolveIndividualScreen.
                Obx(() {
                  final isRiderLive =
                      viewPersonalDetailsController.shopStatusOpenClose.value;
                  // Push content down for the "I'm Live" bar only.
                  //
                  // There used to be a `hasActiveCall → topOffset = 50` branch
                  // reserving room for an ongoing-call bar that NOTHING ever
                  // rendered (the widget was the commented-out OngoingCallOverlay
                  // in main.dart). So a live call just left a 50px empty band at
                  // the top of every tab — the "missing call bar". The call
                  // indicator is now OngoingCallStrip, mounted app-wide in
                  // main.dart's builder, which pushes the whole app down itself;
                  // reserving space here as well would double the gap.
                  final double topOffset = isRiderLive ? 42 : 0;

                  return Positioned.fill(
                    top: topOffset,
                    child: _tabContent,
                  );
                }),

                // Fixed "I'm Live" bar at top
                Obx(() {
                  final isLive =
                      viewPersonalDetailsController.shopStatusOpenClose.value;
                  // Hide when call overlay is showing (call takes priority)
                  final hasActiveCall =
                      callController.callStatus.value != CallStatus.idle;
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: (!isLive || hasActiveCall)
                        ? const SizedBox.shrink()
                        : const _RiderLiveBar(),
                  );
                }),

                // Bottom Nav Animation using ValueListenableBuilder (Bottom tabs)
                Obx(() {
                  // Hide the bar whenever the soft keyboard is up,
                  // otherwise it floats above the keyboard and covers
                  // the focused text field. `keyboardOpen` is captured
                  // at the top of `build` (above the Scaffold) so the
                  // viewInsets are still intact there.
                  final showBar = isVisible && !keyboardOpen;
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSlide(
                      offset: showBar ? Offset.zero : const Offset(0, 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App-wide "turn on location" nudge, sits directly
                          // above the bottom nav. Self-hides when GPS is on.
                          const LocationPermissionBanner(),
                          BottomNavigationBarWidget(
                            onHeaderVisibilityChanged: _toggleAppBar,
                            isBottomNavVisible: isVisible,
                            currentIndex:
                                bottomBarController.currentIndex.value,
                            showShadow: true,
                            onTap: (index) async {
                              // Tabs: 0=Me, 1=Discover, 2=Chat, 3=Reels.
                              // Location is fetched at app start (and on resume via
                              // AppLifecycleHandler), so tab changes no longer gate
                              // on lat/lng — gating blocked navigation when the
                              // first-launch fetch hadn't completed yet.
                              // If this screen was a deep-link background host,
                              // run the home init that cold start skipped now
                              // that the user is actually navigating.
                              _ensureHeavyInit();
                              // From here on the tab is the user's choice — the
                              // deferred landing-tab correction must not move
                              // it out from under them.
                              _userPickedTab = true;
                              bottomBarController.onChangeIndex(index);
                            },
                            chatNotificationCount: chatNotificationCount,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return meScreens();
      case 1:
        // Back handling for all tabs lives in BottomNavigationBarWidget
        // (_handleBackPress) — the single source of truth. Wrapping tab
        // screens in their own PopScope here registered a *second*
        // canPop:false handler on the same route, so a single back press
        // fired both callbacks and produced erratic navigation.
        // Discover — now the v2 layout (`assets/discover.png`): the header +
        // search, the ten-tile Quick Access launcher, the two near-me rails,
        // recent stores, refer & earn, and the QR pair.
        //
        // The previous page ([DiscoverScreen], the chip-row + folder-grid
        // catalogue) is NOT deleted — it is still in
        // `Discover/view/discover_screen.dart` and still reachable, and every
        // destination v2 offers is the same call it made. Swap the two lines
        // below to put it back.
        return const DiscoverScreenV2();
      // return const DiscoverScreen();
      case 2:
        return const ConnectMainPage();
      case 3:
      // return const ReelsTabScreen();

      default:
        return const SocialMainScreen();
    }
  }

  void _toggleAppBar(bool visible) {
    // Only update when different to avoid unnecessary rebuilds
    if (bottomBarVisibleNotifier.value != visible) {
      bottomBarVisibleNotifier.value = visible;
    }
  }

  Widget meScreens() {
    if (isGuestUser()) return GuestDashBoardScreen();
    if (isBusinessUser()) return resolveBusinessScreen();
    if (isIndividualUser()) return resolveIndividualScreen();

    // Fallback (required)
    return PersonalProfileSetupNewScreen();
  }

  Widget resolveBusinessScreen() {
    final businessCtrl =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    return Obx(() {
      // Subscribe to the fetch flags so this Obx rebuilds when a profile fetch
      // settles/populates the data — `businessTypeGlobal` is a NON-reactive
      // global, so on its own it can never trigger a rebuild. Reading these two
      // (`isBusinessProfileReady` flips on first load, `isMeProfileFetching` on
      // every refresh) is what re-runs this builder against the fresh globals.
      businessCtrl.isBusinessProfileReady.value;
      businessCtrl.isMeProfileFetching.value;
      final error = businessCtrl.meProfileError.value;
      if (businessTypeGlobal.isEmpty) {
        // The fetch settled and could not produce a profile (request failed, or
        // login carried no business_id to fetch with) → say so and offer a
        // retry. Without this the tab shimmered forever, because a failed fetch
        // leaves businessTypeGlobal empty exactly like one still in flight.
        if (error.isNotEmpty && !businessCtrl.isMeProfileFetching.value) {
          return _MeTabError(
            message: error,
            onRetry: () => businessCtrl.viewBusinessProfile(),
          );
        }
        // Type not resolved yet (first load, re-login with a stale ready flag,
        // or an in-flight refresh) → branded SHIMMER. NEVER fall through to
        // _UnknownBusinessFallback here: that fallback is reserved for a
        // genuinely UNRECOGNISED *non-empty* type (handled inside
        // _buildBusinessScreen).
        return const MeTabShimmer();
      }
      // Wrapped so the two behaviours that used to live in
      // BusinessOwnProfileScreen's initState still happen: the go-live deep
      // link and the once-a-day QR promo. The host sits ABOVE the per-type
      // screen, so it runs once for whichever of Food / Grocery / School /
      // Hospital / Hotel / Product / ... was resolved, instead of being
      // duplicated into every one of them.
      return _BusinessMeHost(
        controller: businessCtrl,
        child: _buildBusinessScreen(),
      );
    });
  }

  Widget _buildBusinessScreen() {
    logs("businessTypeGlobal=== ${businessTypeGlobal}");
    logs("businessCategoryGlobal=== ${businessCategoryGlobal}");
    // 1. First, check if it is a Food business
    if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Food.name.toUpperCase()) {
      return const FoodMainScreen(fromBottomNavBar: true);
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Grocery.name.toUpperCase()) {
      return const GroceryScreen(fromBottomNavBar: true);
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Siksha.name.toUpperCase()) {
      return const SchoolMain();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Healthcare.name.toUpperCase()) {
      // DOCTORS / CLINICS are STANDALONE DOCTORS — independent practitioners
      // with their own listing, professional profile and appointment inbox
      // (hospital-service/doctors*). They get their own module; everything
      // else in Healthcare keeps its existing destination, so the hospital
      // OPD flow below is unchanged.
      final category = businessCategoryGlobal.toUpperCase();
      if (_isStandaloneDoctor()) {
        return const DoctorMain();
      } else if (category == BusinessCategoryTokens.hospitals ||
          category == BusinessCategoryTokens.alternativeHealth) {
        return const HospitalMain();
      } else if (category == BusinessCategoryTokens.diagnostic) {
        return const LaboratoryMain();
      } else if (category == BusinessCategoryTokens.pharmacy) {
        return const MedicalScreen(fromBottomNavBar: true);
      }
      return const OthersMain();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Motel.name.toUpperCase()) {
      return const HotelMain();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Product.name.toUpperCase()) {
      return const ProductScreen();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Finance.name.toUpperCase()) {
      return const OthersMain();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Service.name.toUpperCase()) {
      return const OthersMain();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Manufacturing.name.toUpperCase()) {
      // return const ManufactureMain();
      //
      // Manufacturing splits by WHAT IS MADE. The onboarding API serves four
      // categories under it — grocery & stationary, product, healthcare and
      // automotive — and each one's goods already have a catalogue screen in the
      // app, so the merchant lands on the one built for their own stock instead
      // of every manufacturer sharing the generic product screen.
      //
      // Matched on a token rather than an exact string, for the same reason the
      // automotive helpers below are: `businessCategoryGlobal` carries the
      // display name ("Manufacturing Healthcare") on some paths and the tag id
      // ("MANUFACTURING_HEALTHCARE") on others. Each of these three tokens
      // appears in exactly one manufacturing category, so either shape lands.
      final category = businessCategoryGlobal.toUpperCase();
      logs("MANUFACTURING -> category= $category");
      if (category.contains(BusinessCategoryTokens.groceryToken)) {
        return const GroceryScreen(fromBottomNavBar: true);
      } else if (category.contains(BusinessCategoryTokens.healthcareToken)) {
        return const MedicalScreen(fromBottomNavBar: true);
      } else if (category.contains(BusinessCategoryTokens.automotiveToken)) {
        return const AutomotivePartsScreen();
      }
      // MANUFACTURING_PRODUCT — and deliberately also anything added
      // server-side later. A new manufacturing category then gets the general
      // goods catalogue, which is where every manufacturer landed until now,
      // rather than the unknown-business fallback.
      return const ManufacturerProductScreen();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Automotive.name.toUpperCase()) {
      // All Automotive sub-categories route from this single branch based on
      // the business category. Order matters — a category can satisfy more
      // than one check (e.g. VEHICLE_SALES), and the first match wins, same
      // precedence as the previous separate else-if chain.
      final category = businessCategoryGlobal.toUpperCase();
      logs("AUTOMOTIVE -> category= $category");
      if (_isSpecificServiceAutomotive()) {
        // VEHICLE_SALES → vehicle showroom, on the rebuilt (v3) service.
        // VehicleHomeScreenV2 is left in the tree but no longer routed to:
        // it reads the `/vehicles/*` API that the service replaced, so its
        // tabs would sit on 404s.
        return const VehicleScreenV3(fromBottomNavBar: true);
      } else if (_isSpecificServiceSpecialAutomotive()) {
        // VEHICLE_SERVICE / TRANSPORT_LOGISTIC / VEHICLE_SUPPORT — their own
        // module entry that currently reuses the OthersMain UI (other_repo.dart
        // APIs), in a separate directory so the UI can diverge later.
        return const AutomotiveServiceMain();
      } else if (_isSpecificProductAutomotive()) {
        // "AUTO PARTS" category → product/parts catalog screen.
        return const AutomotivePartsScreen();
      }
      return const _UnknownBusinessFallback();
    } else {
      return const _UnknownBusinessFallback();
    }
  }

  /// True for a Healthcare business whose category is DOCTORS or CLINICS —
  /// the standalone-doctor module.
  ///
  /// The category arrives from the API in several shapes ("DOCTORS",
  /// "Doctors", "Clinic Doctors", "CLINICS"), so this normalises case and
  /// matches on the token rather than an exact string, the same way the
  /// automotive helpers below do.
  bool _isStandaloneDoctor() {
    if (businessTypeGlobal.toUpperCase() !=
        BusinessType.Healthcare.name.toUpperCase()) {
      return false;
    }
    final category = businessCategoryGlobal.toUpperCase().trim();
    return category.contains(BusinessCategoryTokens.doctorToken) ||
        category.contains(BusinessCategoryTokens.clinicToken);
  }

  bool _isSpecificServiceAutomotive() {
    final category = businessCategoryGlobal.toUpperCase();

    // Automotive AND one of the showroom (vehicle-sales) categories.
    return businessTypeGlobal.toUpperCase() ==
            BusinessType.Automotive.name.toUpperCase() &&
        BusinessCategoryTokens.automotiveVehicleSales.contains(category);
  }

  bool _isSpecificServiceSpecialAutomotive() {
    final category = businessCategoryGlobal.toUpperCase();
    logs("category=== ${category}");

    // Automotive AND one of the service / support / transport categories.
    return businessTypeGlobal.toUpperCase() ==
            BusinessType.Automotive.name.toUpperCase() &&
        BusinessCategoryTokens.automotiveServiceAndSupport.contains(category);
  }

  bool _isSpecificProductAutomotive() {
    final category = businessCategoryGlobal.toUpperCase();

    // The "AUTO PARTS" category (with its space, as the API returns it) maps
    // to the parts catalog screen.
    return businessTypeGlobal.toUpperCase() ==
            BusinessType.Automotive.name.toUpperCase() &&
        category.contains(BusinessCategoryTokens.autoPartsToken);
  }

  Widget resolveIndividualScreen() {
    return Obx(() {
      // Subscribe to the fetch flags so this Obx rebuilds when a profile fetch
      // settles/populates the data — `userProfileTypeGlobal` is a NON-reactive
      // global, so on its own it can never trigger a rebuild. Reading these two
      // (`isPersonalProfileReady` flips on first load, `isMeProfileFetching` on
      // every refresh) is what re-runs this builder against the fresh globals.
      viewPersonalDetailsController.isPersonalProfileReady.value;
      viewPersonalDetailsController.isMeProfileFetching.value;
      final error = viewPersonalDetailsController.meProfileError.value;
      if (userProfileTypeGlobal.isEmpty) {
        // The fetch settled and could not produce a profile → say so and offer
        // a retry, rather than shimmering forever (a failed fetch leaves the
        // type global empty exactly like one still in flight).
        if (error.isNotEmpty &&
            !viewPersonalDetailsController.isMeProfileFetching.value) {
          return _MeTabError(
            message: error,
            onRetry: () => viewPersonalDetailsController.viewPersonalProfile(
                forceRefresh: true),
          );
        }
        // Type not resolved yet (first load, re-login with a stale ready flag,
        // or an in-flight refresh) → branded SHIMMER. NEVER fall through to
        // _UnknownProfileFallback here: that fallback is reserved for a
        // genuinely UNRECOGNISED *non-empty* type (handled inside
        // _buildIndividualScreen).
        return const MeTabShimmer();
      }
      // Same host the business branch uses, so the "You're offline" nudge
      // reaches individual Me screens too. Riders are excluded inside it — the
      // rider dashboard runs its own copy with its own gating and copy.
      return _IndividualMeHost(
        controller: viewPersonalDetailsController,
        child: _buildIndividualScreen(),
      );
    });
  }

  Widget _buildIndividualScreen() {
    final String currentType = userProfileTypeGlobal;
    debugPrint("User Profile Type: $currentType");
    debugPrint("User Profession: $userProfessionGlobal");

    // Using a Switch statement makes it cleaner and easier to add new types
    switch (currentType) {
      case SELF_EMPLOYED:
        return const SelfEmployeeScreen();

      case GIG_WORKER:
        return const GigWorkOptionsScreen(fromBottomNavBar: true);

      case SOCIAL_PROFILE:
        if (userProfessionGlobal == CONTENT_CREATOR ||
            userProfessionGlobal == ARTIST) {
          return const ContentCreatorMainScreen();
        }
        return const me_social.SocialMainScreen();

      case PROFESSIONAL:
        return const ProfessionalsMainScreen();

      default:
        return const _UnknownProfileFallback();
    }
  }
}

/// Fallback shown on the "Me" tab when [userProfileTypeGlobal] doesn't
/// match any of the known individual profile types. Surfaces the basic
/// identity we have on hand (name + profile type + profession) so the
/// user isn't staring at a blank screen.
class _UnknownProfileFallback extends StatelessWidget {
  const _UnknownProfileFallback();

  @override
  Widget build(BuildContext context) {
    final name = userNameGlobal.isNotEmpty ? userNameGlobal : '—';
    final type = userProfileTypeGlobal.isNotEmpty ? userProfileTypeGlobal : '—';
    final profession =
        userProfessionGlobal.isNotEmpty ? userProfessionGlobal : '—';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SizeConfig.size20),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 44,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              name,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size20),
            _infoRow(AppStrings.profileTypeLabel.tr, type),
            Container(height: 1, color: AppColors.greyE5),
            _infoRow(AppStrings.professionLabel.tr, profession),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          CustomText(
            value,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

/// Fallback shown on the "Me" tab when [businessTypeGlobal] /
/// [businessCategoryGlobal] don't match any of the known business
/// modules. Surfaces the business identity (name + owner + type +
/// category) so the user isn't staring at a blank screen.
/// Shown on the "Me" tab when the own-profile fetch could not produce a usable
/// profile — the request failed, or login returned no `business` /
/// `business_id` to fetch with.
///
/// This exists because the tab's only other "type is empty" state is the
/// shimmer, and a FAILED fetch leaves the type globals empty exactly like a
/// fetch that has not finished — so the tab used to shimmer forever with no
/// way out. A dead end with no explanation and no retry is worse than an error.
///
/// Carries the same hamburger → ProfileMenuDrawer as every real Me screen. That
/// is the ONLY route to Logout, and an account whose profile will not load is
/// exactly the account that needs it — without the menu here the user is stuck
/// on a broken tab with no way to sign out and try another account.
class _MeTabError extends StatelessWidget {
  const _MeTabError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  void _openDrawer(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ProfileMenuDrawer(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding:
                EdgeInsets.only(left: SizeConfig.size12, top: SizeConfig.size8),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openDrawer(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.menu,
                        size: 22, color: AppColors.primaryColor),
                  ),
                ),
              ),
            ),
          ),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 44,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              message,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              AppStrings.profileLoadFailedHint.tr,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: SizeConfig.size24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: CustomText(
                AppStrings.tryAgain.tr,
                fontSize: SizeConfig.medium15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size24,
                  vertical: SizeConfig.size12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownBusinessFallback extends StatelessWidget {
  const _UnknownBusinessFallback();

  @override
  Widget build(BuildContext context) {
    final name = businessNameGlobal.isNotEmpty ? businessNameGlobal : '—';
    final owner =
        businessOwnerNameGlobal.isNotEmpty ? businessOwnerNameGlobal : '—';
    final type = businessTypeGlobal.isNotEmpty ? businessTypeGlobal : '—';
    final category =
        businessCategoryGlobal.isNotEmpty ? businessCategoryGlobal : '—';
    final subCategory =
        businessSubCategoryGlobal.isNotEmpty ? businessSubCategoryGlobal : '—';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SizeConfig.size20),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 44,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              name,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size20),
            _infoRow(AppStrings.owner.tr, owner),
            Container(height: 1, color: AppColors.greyE5),
            _infoRow(AppStrings.businessTypeLabel.tr, type),
            Container(height: 1, color: AppColors.greyE5),
            _infoRow(AppStrings.category.tr, category),
            Container(height: 1, color: AppColors.greyE5),
            _infoRow(AppStrings.subCategoryLabel.tr, subCategory),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          CustomText(
            value,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

/// Fixed "I'm Live" bar shown at the top of the BottomNavigationBarScreen
/// when the rider is online. Matches the WhatsApp call-bar style.
class _RiderLiveBar extends StatefulWidget {
  const _RiderLiveBar();

  @override
  State<_RiderLiveBar> createState() => _RiderLiveBarState();
}

class _RiderLiveBarState extends State<_RiderLiveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        getOrPut(() => ViewPersonalDetailsController(), permanent: true);

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2E35),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pulsing green dot
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final opacity = 0.4 + (_pulseController.value * 0.6);
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00C853).withValues(alpha: opacity),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Color(0xFF00C853).withValues(alpha: opacity * 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),

            // "I'm Live" label
            Expanded(
              child: Text(
                AppStrings.imLive.tr,
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),

            // Go Offline button
            GestureDetector(
              onTap: () => controller.toggleShopStatus(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA4335),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  AppStrings.goOffline.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Host for the business "Me" tab. Sits above whichever per-type screen
/// [_buildBusinessScreen] resolved (Food / Grocery / School / Hospital /
/// Hotel / Product / Manufacturing / Automotive / ...) and owns the two
/// once-per-open behaviours that used to live in the deleted
/// BusinessOwnProfileScreen's `initState`:
///
///   1. the `business_go_live_reminder` / `go_live` notification deep link,
///      which arrives as [BottomBarController.pendingBusinessGoLive] and opens
///      the shop-availability sheet; and
///   2. the once-a-day "your QR code" promo sheet.
///
/// They are mutually exclusive, exactly as before — when the go-live deep link
/// is opening its own sheet the promo is skipped, so the two never stack.
///
/// This is built inside the `resolveBusinessScreen()` Obx, which re-runs on
/// every profile fetch. Because the host keeps its type and position across
/// those rebuilds, Flutter reuses this State and `initState` fires only on the
/// first build that has a resolved business type — i.e. once the profile is
/// actually available, which is what both behaviours need.
class _BusinessMeHost extends StatefulWidget {
  const _BusinessMeHost({required this.controller, required this.child});

  final ViewBusinessDetailsController controller;
  final Widget child;

  @override
  State<_BusinessMeHost> createState() => _BusinessMeHostState();
}

class _BusinessMeHostState extends State<_BusinessMeHost> {
  Worker? _meTabWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runEntryActions());
    _watchMeTabEntry();
  }

  @override
  void dispose() {
    _meTabWorker?.dispose();
    super.dispose();
  }

  /// Re-runs the arrival checks whenever the bottom nav lands back on Me.
  ///
  /// This host is kept alive between tab switches, so coming back rebuilds
  /// nothing and fires no lifecycle callback — the bottom bar's index is the
  /// only signal that the merchant is looking at this screen again. Without it
  /// `initState` would be the one and only check, and a merchant who bounced to
  /// Discover and back would never be asked again however long they then sat
  /// there offline. Mirrors the rider dashboard's `_watchMeTabEntry`.
  void _watchMeTabEntry() {
    if (!Get.isRegistered<BottomBarController>()) return;
    final bar = Get.find<BottomBarController>();
    _meTabWorker = ever<int>(bar.currentIndex, (index) {
      if (index != BottomBarController.meTabIndex || !mounted) return;
      // After the frame that swaps the tab in, so nothing goes up against a
      // half-built screen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _runEntryActions());
    });
  }

  /// At most ONE prompt per arrival, in priority order. Stacking sheets on a
  /// screen the merchant just opened is how a dashboard becomes a queue of
  /// modals to dismiss before any of it can be read.
  Future<void> _runEntryActions() async {
    if (!mounted) return;
    // Something is already up — another sheet, a dialog, a pushed screen.
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return;

    // 1. Deep-link from the go-live notification. Consumed (not just read) so a
    //    later tab switch doesn't re-open the sheet. Explicit user intent, so
    //    it outranks anything this screen would have volunteered.
    if (BottomBarController.pendingBusinessGoLive) {
      BottomBarController.pendingBusinessGoLive = false;
      await widget.controller.openAvailabilityControl();
      return;
    }

    // 2. Offline nudge. Ranked above the QR promo because being offline means
    //    the shop is invisible and earning nothing, which is worth more than a
    //    share prompt. When the shop IS live this falls through, so the promo
    //    still gets its once-a-day slot.
    if (_maybeNudgeGoLive()) return;

    // 3. The once-a-day "your QR code" promo. Self-gating (own day key +
    //    waits for the profile), so calling it on every arrival is free.
    if (!mounted) return;
    await showBusinessQrPromoSheetIfNeeded(
      context: context,
      controller: widget.controller,
    );
  }

  /// Offers the shared "You're offline" sheet. Returns true when it was shown,
  /// so the caller knows a prompt has already claimed this arrival.
  ///
  /// Deliberately shallow, exactly like the rider version: it asks only "can
  /// this shop be live, and isn't it?". It does NOT work out WHY — no hours
  /// yet, plan unpaid, nothing in the catalogue are all diagnosed by
  /// [ViewBusinessDetailsController.toggleLiveNow], which the button routes
  /// through and which says the right thing for each. Two places deciding what
  /// blocks a merchant is two places to get out of step.
  bool _maybeNudgeGoLive() {
    if (!GoLiveNudgeCooldown.isDue) return false;
    // Wait for the profile before claiming anything about the shop's state —
    // an unfetched profile reads as closed and would nudge every merchant on
    // every cold start, live ones included.
    if (!widget.controller.isBusinessProfileReady.value) return false;
    if (widget.controller.isLive.value) return false;

    GoLiveNudgeCooldown.markShown();
    showGoLiveNudgeSheet(
      title: AppStrings.goLiveNudgeTitle.tr,
      message: AppStrings.goLiveNudgeBusinessBody.tr,
      ctaLabel: AppStrings.goLiveNudgeCta.tr,
      // The SAME entry point the go-live pill uses, so the sheet's button is
      // not a second way to go live with its own rules.
      onGoLive: widget.controller.toggleLiveNow,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Individual counterpart to [_BusinessMeHost]. Wraps whichever per-profile-type
/// screen `_buildIndividualScreen()` resolved and owns the one arrival
/// behaviour they share: the "You're offline" go-live nudge.
///
/// RIDERS ARE EXCLUDED. `RiderServiceScreen` runs its own copy of this prompt
/// with rider-specific gating (onboarding must be submitted or approved) and
/// rider-specific copy ("ride requests"), and it re-checks on app resume as
/// well as Me-tab entry. Nudging from here as well would show two sheets, so
/// this defers to it.
class _IndividualMeHost extends StatefulWidget {
  const _IndividualMeHost({required this.controller, required this.child});

  final ViewPersonalDetailsController controller;
  final Widget child;

  @override
  State<_IndividualMeHost> createState() => _IndividualMeHostState();
}

class _IndividualMeHostState extends State<_IndividualMeHost> {
  Worker? _meTabWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNudgeGoLive());
    if (Get.isRegistered<BottomBarController>()) {
      final bar = Get.find<BottomBarController>();
      _meTabWorker = ever<int>(bar.currentIndex, (index) {
        if (index != BottomBarController.meTabIndex || !mounted) return;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeNudgeGoLive());
      });
    }
  }

  @override
  void dispose() {
    _meTabWorker?.dispose();
    super.dispose();
  }

  void _maybeNudgeGoLive() {
    if (!mounted) return;
    // The rider dashboard prompts for itself — see the class doc.
    if (isRiderProfession(userProfessionGlobal)) return;
    // A social profile has no go-live at all; there is nothing to turn on.
    if (userProfileTypeGlobal == SOCIAL_PROFILE) return;
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return;
    if (!GoLiveNudgeCooldown.isDue) return;
    // An unfetched profile reads as closed and would nudge everyone on a cold
    // start, live ones included.
    if (!widget.controller.isPersonalProfileReady.value) return;
    if (widget.controller.shopStatus.value.isOpenNow) return;

    GoLiveNudgeCooldown.markShown();
    showGoLiveNudgeSheet(
      title: AppStrings.goLiveNudgeTitle.tr,
      message: AppStrings.goLiveNudgeIndividualBody.tr,
      ctaLabel: AppStrings.goLiveNudgeCta.tr,
      // Routed through the same entry point the Go-Live pill uses, with the
      // controller's own gate so an unpaid provider is told why and routed to
      // the plan flow rather than the tap doing nothing.
      onGoLive: () => widget.controller
          .toggleLiveNow(gate: widget.controller.ensureCanGoLive),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

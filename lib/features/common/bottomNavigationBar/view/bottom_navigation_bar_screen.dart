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
import 'package:BlueEra/core/services/chat_media_storage_service.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/view/order_main_chat_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/joining_bounce/model/joining_bounce_model.dart';
import 'package:BlueEra/features/common/joining_bounce/view/claim_bonus_dialog.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/ai_chat_guest_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/connect/view/connect_main_page.dart';
import 'package:BlueEra/features/common/delivery_partner/view/gig_work_options_screen.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_parts_screen.dart';
import 'package:BlueEra/features/me/automotive_service/automotive_service_main.dart';
import 'package:BlueEra/features/me/content_creator/content_creator_main.dart';
import 'package:BlueEra/features/me/food/view/admin/food_main_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_main.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_main.dart';
import 'package:BlueEra/features/me/laboratory/view/laboratory_main.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_screen.dart';
import 'package:BlueEra/features/me/others/others_main.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/product_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_main.dart';
import 'package:BlueEra/features/me/school/view/school_main.dart';
import 'package:BlueEra/features/me/social/view/social_main.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/vehicle_home_screen_v2.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/location_permission_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/controller/chat_theme_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../delivery_partner/controller/pip_floating_page_controller.dart';

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

  const BottomNavigationBarScreen(
      {super.key,
      this.initialIndex = 1,
      this.sharedMedia,
      this.deferHeavyInit = false});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int chatNotificationCount = 0;
  final ValueNotifier<bool> bottomBarVisibleNotifier = ValueNotifier(true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bottomBarController = Get.put(BottomBarController());
  final chatViewController = getOrPut(() => ChatViewController());
  final viewPersonalDetailsController = getOrPut(() => ViewPersonalDetailsController(), permanent: true);
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
    _bottomNavVisibilityWorker = ever<bool>(bottomBarController.isBottomNavVisible, (visible) {
      _toggleAppBar(visible);
    });
    _checkAndFetchLocationData();
    if (Platform.isAndroid) {
      final pipController = getOrPut(() => PipFloatingPageController());
      pipController.setPipStatus(false);
    }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePostFrameInitialization();
      _maybePromptGuestToCreateProfile();
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

  /// One-shot per-session prompt: when the user lands on the home and
  /// their session is in guest mode, surface a friendly dialog asking
  /// them to create a profile so chat / bookings / orders unlock. The
  /// dialog from re-firing on tab swaps inside the same launch.
  /// One-shot per launch: show the joining-bonus claim popup. The
  /// `joining_bounce` object is read from the profile response the app already
  /// loads (business → business profile, individual → personal profile) — no
  /// extra API call. The gate is the backend's `show_card` flag (surfaced via
  /// [JoiningBounce.shouldShow]); when it is false there is nothing to show.
  /// Claiming is handled inside the dialog.
  static bool _joiningBonusShown = false;
  Worker? _joiningBonusWorker;

  Future<void> _maybeShowJoiningBonus() async {
    if (_joiningBonusShown) {
      logs("JOINING_BONUS: skip — already shown this launch");
      return;
    }
    if (isGuestUser()) {
      // Guests have no profile (and no real bonus), so show the guest scratch
      // card — it never exposes an amount; scratching just unlocks the
      // "Create Profile" CTA. Shown once per launch, like the real card.
      if (!mounted) return;
      logs("JOINING_BONUS: guest user — showing GuestClaimBonusDialog");
      _joiningBonusShown = true;
      _joiningBonusWorker?.dispose();
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const GuestClaimBonusDialog(),
      );
      return;
    }

    final bool business = isBusiness();
    final businessController =
        business ? getOrPut(() => ViewBusinessDetailsController(), permanent: true) : null;
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

  static bool _guestPromptShown = false;

  void _maybePromptGuestToCreateProfile() {
    if (_guestPromptShown) return;
    if (!isGuestUser()) return;
    if (!mounted) return;
    _guestPromptShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 36,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                AppStrings.createYourProfile.tr,
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                AppStrings.guestBrowsingHint.tr,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
              SizedBox(height: SizeConfig.size16),
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      onTap: () => Navigator.of(ctx).pop(),
                      title: AppStrings.maybeLater.tr,
                      bgColor: AppColors.transparent,
                      textColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                      radius: 10,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomBtn(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        createProfileScreen();
                      },
                      title: AppStrings.createProfile.tr,
                      bgColor: AppColors.primaryColor,
                      textColor: AppColors.white,
                      radius: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        final extra = Map<String, dynamic>.from(calls[0]['extra'] as Map? ?? {});
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
      SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.channel_Id, channelId),
      SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.channelName, channelName),
      SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.channelOwner, channelOwner),
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

  void _handlePostFrameInitialization() {
    // Own-profile fetch is part of the home boot. When this screen is only the
    // deep-link background host (deferHeavyInit), skip it until the user first
    // navigates a tab — it then runs from _ensureHeavyInit().
    final boot = !widget.deferHeavyInit;
    if (isBusiness()) {
      // Business users land on the Me tab (0) by default on app open / login /
      // signup so their own shop/dashboard is front and centre. An explicit
      // deep-link tab (notification, or a post-action nav that requests a
      // specific tab) still wins because it passes a non-null initialIndex.
      bottomBarController.currentIndex.value = widget.initialIndex ?? 0;
      // Keep the controller registered even on a deferred open so any
      // Get.find<ViewBusinessDetailsController>() elsewhere stays safe; only
      // the network fetch is part of the home boot and gets deferred.
      final businessCtrl =
          getOrPut(() => ViewBusinessDetailsController(), permanent: true);
      // Already in the business branch — fetch directly (no second isBusiness
      // check), unless it's already loaded.
      if (boot &&
          businessCtrl.viewBusinessResponse.status != Status.COMPLETE) {
        businessCtrl.viewBusinessProfile();
      }
    } else {
      // Riders (bike rider / car-taxi driver) and gig workers always land on
      // the Me tab (index 0) on login — regardless of whether their profile
      // has been created yet — so their dashboard / onboarding is front and
      // centre. Every other individual type uses the requested initial tab
      // (Discover by default).
      final isRider = userProfessionGlobal == BIKE_RIDER || userProfessionGlobal == CAR_TAXI_DRIVER;
      final isGigWorker = userProfileTypeGlobal == GIG_WORKER;
      if (isRider || isGigWorker) {
        bottomBarController.currentIndex.value = 0;
      } else {
        bottomBarController.currentIndex.value = widget.initialIndex ?? 1;
      }
      // Individual own-profile fetch — the personal profile carries
      // securityDeposit (Go-Live gate), joining_bounce, etc. Fetch directly
      // here since we already know it's an individual, unless already loaded.
      if (boot &&
          viewPersonalDetailsController.viewPersonalResponse.value.status !=
              Status.COMPLETE) {
        // forceRefresh so we actually hit /user/get on every launch (the
        // method is cache-first and would otherwise skip the network on
        // cached launches) — needed for fresh securityDeposit / go-live gate.
        // It still shows the cached profile first, then updates from the API.
        viewPersonalDetailsController.viewPersonalProfile(forceRefresh: true);
      }
    }
  }

  /// Fetches the signed-in user's own profile (business or personal) unless it
  /// is already loaded. Part of the home boot; gated behind [deferHeavyInit] so
  /// a notification deep-link open doesn't fire it behind the target screen.
  void _fetchOwnProfileIfNeeded() {
    if (isBusiness()) {
      final viewProfileController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
      if (viewProfileController.viewBusinessResponse.status != Status.COMPLETE) {
        viewProfileController.viewBusinessProfile();
      }
    } else {
      if (viewPersonalDetailsController.viewPersonalResponse.value.status != Status.COMPLETE) {
        viewPersonalDetailsController.viewPersonalProfile();
      }
    }
  }

  // GET CHANNEL DETAILS...
  Future<ChannelModel?> getChannelDetails() async {
    try {
      ResponseModel response = await ChannelRepo().getChannelDetails(channelOrUserId: userId);

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
    // gets killed when the widget tree rebuilds after returning from CallActivity
    // and can never reconnect (listeners are cleared permanently).
    final hasActiveCall = Get.isRegistered<CallController>() &&
        (Get.find<CallController>().callStatus.value != CallStatus.idle ||
            CallController.isCallActivityActive);
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
    final index = bottomBarController.currentIndex.value;
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
                  final hasActiveCall = callController.callStatus.value == CallStatus.connected;
                  final isRiderLive = viewPersonalDetailsController.shopStatusOpenClose.value;
                  // Push content down when live bar or call bar is showing
                  double topOffset = 0;
                  if (hasActiveCall)
                    topOffset = 50;
                  else if (isRiderLive) topOffset = 42;

                  return Positioned.fill(
                    top: topOffset,
                    child: _tabContent,
                  );
                }),

                // Fixed "I'm Live" bar at top
                Obx(() {
                  final isLive = viewPersonalDetailsController.shopStatusOpenClose.value;
                  // Hide when call overlay is showing (call takes priority)
                  final hasActiveCall = callController.callStatus.value != CallStatus.idle;
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: (!isLive || hasActiveCall) ? const SizedBox.shrink() : const _RiderLiveBar(),
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
                            currentIndex: bottomBarController.currentIndex.value,
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
        return const DiscoverScreen();
      case 2:
        return const ConnectMainPage();
      case 3:
      // return const ReelsTabScreen();

      default:
        return const OrderMainChatScreen();
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
    logs("businessTypeGlobal=== ${businessTypeGlobal}");
    logs("businessCategoryGlobal=== ${businessCategoryGlobal}");
    // 1. First, check if it is a Food business
    if (businessTypeGlobal.toUpperCase() == BusinessType.Food.name.toUpperCase()) {
      return const FoodMainScreen(fromBottomNavBar: true);
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Grocery.name.toUpperCase()) {
      return const GroceryScreen(fromBottomNavBar: true);
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Siksha.name.toUpperCase()) {
      return const SchoolMain();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Healthcare.name.toUpperCase()) {
      if ((businessCategoryGlobal.toUpperCase() == "HOSPITALS") ||
          (businessCategoryGlobal.toUpperCase() == "Alternative Health".toUpperCase()) ||
          (businessCategoryGlobal.toUpperCase() == "Doctors".toUpperCase()) ||
          (businessCategoryGlobal.toUpperCase() == "CLINICS")) {
        return const HospitalMain();
      } else if (businessCategoryGlobal.toUpperCase() == "Diagnostic".toUpperCase()) {
        return const LaboratoryMain();
      } else if (businessCategoryGlobal.toUpperCase() == "PHARMACY") {
        return const MedicalScreen(fromBottomNavBar: true);
      }
      return const OthersMain();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Motel.name.toUpperCase()) {
      return const HotelMain();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Product.name.toUpperCase()) {
      return const ProductScreen();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Finance.name.toUpperCase()) {
      return const OthersMain();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Service.name.toUpperCase()) {
      return const OthersMain();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Manufacturing.name.toUpperCase()) {
      // return const ManufactureMain();
      return const ManufacturerProductScreen();
    } else if (businessTypeGlobal.toUpperCase() == BusinessType.Automotive.name.toUpperCase()) {
      // All Automotive sub-categories route from this single branch based on
      // the business category. Order matters — a category can satisfy more
      // than one check (e.g. VEHICLE_SALES), and the first match wins, same
      // precedence as the previous separate else-if chain.
      final category = businessCategoryGlobal.toUpperCase();
      logs("AUTOMOTIVE -> category= $category");
      if (_isSpecificServiceAutomotive()) {
        // VEHICLE_SALES → vehicle showroom.
        return const VehicleHomeScreenV2();
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

  bool _isSpecificServiceAutomotive() {
    final category = businessCategoryGlobal.toUpperCase();

    // 1. Define the Automotive sectors that count as "Others"
    final automotiveOthersSectors = {
      "VEHICLE_SALES",
      "VEHICLE SALES",
      // "VEHICLE_PARTS",
      // "VEHICLE_RENTAL",
      // "AUTO PARTS",
      // "VEHICLE RENTAL",
      // "AUTO RENTAL",
    };

    // 2. Check if it's Automotive AND in one of those sectors
    return businessTypeGlobal.toUpperCase() == BusinessType.Automotive.name.toUpperCase() &&
        automotiveOthersSectors.contains(category);
  }

  bool _isSpecificServiceSpecialAutomotive() {
    final category = businessCategoryGlobal.toUpperCase();
    logs("category=== ${category}");
    final automotiveOthersSpecialSectors = {
      "VEHICLE SERVICE",
      "VEHICLE_SERVICE",
      // "TRANSPORT_LOGISTIC",
      // "TRANSPORT LOGISTIC",
      "VEHICLE_SUPPORT",
      "VEHICLE SUPPORT",
      "TRANSPORT_LOGISTICS_PARKING",
      "TRANSPORT LOGISTICS PARKING",
    };

    // 2. Check if it's Automotive AND in one of those sectors
    return businessTypeGlobal.toUpperCase() == BusinessType.Automotive.name.toUpperCase() &&
        automotiveOthersSpecialSectors.contains(category);
  }

  bool _isSpecificProductAutomotive() {
    final category = businessCategoryGlobal.toUpperCase();

    // The "AUTO PARTS" category (with its space, as the API returns it) maps
    // to the parts catalog screen.
    return businessTypeGlobal.toUpperCase() == BusinessType.Automotive.name.toUpperCase() &&
        category.toUpperCase().contains('AUTO PARTS');
  }

  Widget resolveIndividualScreen() {
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
        if (userProfessionGlobal == CONTENT_CREATOR || userProfessionGlobal == ARTIST) {
          return const ContentCreatorMainScreen();
        }
        return const SocialMainScreen();

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
    final profession = userProfessionGlobal.isNotEmpty ? userProfessionGlobal : '—';

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
class _UnknownBusinessFallback extends StatelessWidget {
  const _UnknownBusinessFallback();

  @override
  Widget build(BuildContext context) {
    final name = businessNameGlobal.isNotEmpty ? businessNameGlobal : '—';
    final owner = businessOwnerNameGlobal.isNotEmpty ? businessOwnerNameGlobal : '—';
    final type = businessTypeGlobal.isNotEmpty ? businessTypeGlobal : '—';
    final category = businessCategoryGlobal.isNotEmpty ? businessCategoryGlobal : '—';
    final subCategory = businessSubCategoryGlobal.isNotEmpty ? businessSubCategoryGlobal : '—';

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

class _RiderLiveBarState extends State<_RiderLiveBar> with SingleTickerProviderStateMixin {
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
    final controller = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

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
                        color: Color(0xFF00C853).withValues(alpha: opacity * 0.5),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

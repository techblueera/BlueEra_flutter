import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
// Store "Manage your store" CTA + Inquiry chat list removed with the Store /
// Inquiry tabs — Inquiry import kept commented for easy restore.
// import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/service/rider_auto_golive_scheduler.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_order_tab.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_overview_tab.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_post_tab.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_statics_tab.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/rider_go_live_prompts.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderServiceScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const RiderServiceScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<RiderServiceScreen> createState() => _RiderServiceScreenState();
}

class _RiderServiceScreenState extends State<RiderServiceScreen>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        MeTabBackHandlerMixin {
  final controller = getOrPut(() => DeliveryPartnerController());
  final _ordersCtrl = getOrPut(() => DeliverPartnerOrdersController());
  final _viewCtrl = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  late final TabController _tabController;

  // Chat was its own top-level tab; it now lives as a sub-tab inside
  // My Order (once verification is approved). _orderSubTab tracks
  // which of the two sub-tabs is active. Rentals are not a tab either
  // â€” they're surfaced as a CTA card inside the Overview tab (see
  // _buildRentalCard), so the top strip stays at four entries.
  // Inquiry sub-tab removed — the Preference/Order | Inquiry toggle is gone,
  // so the preference/orders content renders directly with no sub-tab state.
  // static const _orderSubOrders = 0;
  // static const _orderSubChat = 1;
  // int _orderSubTab = _orderSubOrders;



  @override
  void initState() {
    super.initState();
    // Store tab removed → 4 top-level tabs (My Order, Overview, Post, Statistics).
    _tabController = TabController(length: 4, vsync: this);
    registerMeTabBackHandler(_tabController);
    // Switching tabs re-checks the onboarding status (throttled — see
    // DeliveryPartnerController.statusFreshFor). Nothing here remounts on a tab
    // change, so without this a rider approved while the screen was open kept
    // seeing "pending" until they killed the app.
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
    _checkRiderStatus();
    // Resume the best-effort daily auto go-live scheduler if the rider opted in
    // on a previous session (08:00–22:00 auto open/close while the app is open;
    // backend cron is authoritative — see the scheduler doc).
    RiderAutoGoLiveScheduler().ensureStartedIfEnabled();
    _viewCtrl.UserFollowersAndPostsCount(userId);
    // The onboarding status is fetched asynchronously, so on a cold open this
    // screen is built before we know whether the rider is verified or has paid.
    // Re-check the prompt whenever it lands; [_maybeShowGoLivePrompt] is a
    // one-shot, so a later refresh costs nothing.
    _goLivePromptWorker =
        ever(controller.riderOnboardingStatusData, (_) => _maybeShowGoLivePrompt());
    _watchMeTabEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() == AppConstants.OPEN.toUpperCase();
      // Runs after the line above, so the live/offline check reads the real
      // status rather than the Rx's initial value.
      _maybeShowGoLivePrompt();
    });
  }

  /// Nudge a rider who has finished setting up but is not live.
  ///
  /// The check is deliberately shallow: has the profile been submitted (or
  /// approved), and are they offline? If so, offer the button. It does NOT try
  /// to work out WHY they are offline — deposit unpaid, permissions missing,
  /// documents still in review are all already diagnosed by [handleGoLiveTap],
  /// which the sheet's button routes through and which says the right thing for
  /// each case. Two places deciding what blocks a rider is two places to get out
  /// of step.
  ///
  /// Riders who have not submitted anything yet are skipped: their screen is
  /// still an onboarding form, and a "go live" nudge on top of it is noise about
  /// a button they do not have.
  ///
  /// Re-checked every time the rider ARRIVES on the Me section — not once per
  /// launch. This screen lives inside a keep-alive tab, so `initState` runs on
  /// the first mount and never again: without the Me-tab worker in
  /// [_watchMeTabEntry], a rider who bounced to Discover and back would never
  /// be asked again, however long they then sat there offline.
  ///
  /// [_promptCooldown] is what keeps that from nagging. Dismissing it buys
  /// quiet for a while; arriving again later asks again, because the thing it
  /// is asking about — you are offline and earning nothing — has not changed.
  /// Acting on it needs no cooldown: the "already live" guard below stays
  /// silent for as long as they remain online.
  static const Duration _promptCooldown = Duration(minutes: 15);
  static DateTime? _promptShownAt;
  Worker? _goLivePromptWorker;
  Worker? _meTabWorker;

  /// Re-runs the prompt check whenever the bottom nav lands on the Me tab.
  ///
  /// This screen is kept alive between tab switches, so arriving back on Me
  /// rebuilds nothing and fires no lifecycle callback — the bottom bar's index
  /// is the only signal that the rider is looking at this screen again.
  ///
  /// No-op when the dashboard was reached by its own route instead of the tab
  /// (deep link, CallKit hand-off): there is no bottom bar to watch, and the
  /// post-frame check in initState has already covered that entry.
  void _watchMeTabEntry() {
    if (!Get.isRegistered<BottomBarController>()) return;
    final bottomBar = Get.find<BottomBarController>();
    _meTabWorker = ever<int>(bottomBar.currentIndex, (index) {
      if (index != BottomBarController.meTabIndex || !mounted) return;
      // After the frame that swaps the tab in, so the dialog never goes up
      // against a half-built screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowGoLivePrompt();
      });
    });
  }

  void _maybeShowGoLivePrompt() {
    if (!mounted) return;
    final shownAt = _promptShownAt;
    if (shownAt != null &&
        DateTime.now().difference(shownAt) < _promptCooldown) {
      return;
    }
    // Profile submitted (in review) or approved. `pending` means the documents
    // are in and being looked at; anything before that has no onboarding record
    // at all and the screen is still a form.
    final state = controller.riderVerificationState;
    final submittedOrApproved = state == RiderVerificationState.completed ||
        state == RiderVerificationState.pending;
    if (!submittedOrApproved) return;

    // Already working. Nothing to nudge.
    if (_viewCtrl.shopStatusOpenClose.value) return;

    // Never stack on top of something already open — the permission screen, a
    // deep-linked order, another sheet or dialog.
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return;

    _promptShownAt = DateTime.now();
    // Routed through the SAME handleGoLiveTap the pill uses, so the sheet's
    // button is not a second way to go live with its own rules — it runs the
    // verification check, the deposit gate, the permission gate and the
    // scheduler opt-in identically, and flips the one `shopStatusOpenClose`
    // observable the pill and the offline banner both watch. That is what keeps
    // them in sync: there is only ever one piece of state, and only ever one
    // place that decides what blocks a rider.
    showRiderGoLiveSheet(onGoLive: handleGoLiveTap);
  }

  /// Fires twice per swipe (start + settle) — only act on the settle.
  ///
  /// A plain cache-first call, NOT a force: once the rider is approved and paid
  /// this costs nothing at all (the controller serves the cache and returns),
  /// and while they're still waiting it is exactly the re-check they want.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    controller.ridersOnboardingStatusRepoApi();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the UPI app after paying, or from the docs being
    // approved while the phone was in a pocket. Same cache-first call — free
    // once there is nothing left to change.
    if (state == AppLifecycleState.resumed) {
      controller.ridersOnboardingStatusRepoApi();
      // Coming back to the app is an arrival too. Direct rather than relying on
      // the status worker — that call is cache-first and may not change the
      // observable at all, in which case nothing would fire.
      _maybeShowGoLivePrompt();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _goLivePromptWorker?.dispose();
    _meTabWorker?.dispose();
    // We own the orders SSE stream while this screen is alive — tear it
    // down so the connection isn't leaked once the screen is gone.
    _ordersCtrl.stopStream();
    deleteIfRegistered<DeliveryPartnerController>();
    super.dispose();
  }

  /// WHEN THE ONBOARDING STATUS IS (RE)FETCHED
  ///
  ///   1. this screen opens                       → here
  ///   2. a tab is switched                       → _onTabChanged
  ///   3. app returns to the foreground           → didChangeAppLifecycleState
  ///   4. a document/vehicle/deposit is submitted → forceRefresh at the source
  ///   5. Go Live after paying a deposit          → handleGoLiveTap forceRefresh
  ///
  /// 1–3 are ordinary cache-first calls. They only reach the network while the
  /// status is still expected to change (not yet approved, or deposit unpaid);
  /// once the rider is approved AND paid, the controller serves the cache and
  /// they cost nothing — so these triggers can be as generous as they look.
  /// 4–5 force a refresh because the app just caused the change.
  void _checkRiderStatus() {
    controller.ridersOnboardingStatusRepoApi();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  // Scaffold mirrors self-employee v2: glassmorphic top bar, an
  // in-flow tab card, and a sticky tab overlay that engages once
  // the in-flow tabs scroll past the top bar.
  Widget _buildScaffold(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Tab labels are reactive (first label flips Order/Document with
            // the rider's verification status), so the scaffold is rebuilt
            // inside an Obx.
            Obx(() {
              final approved = controller
                      .riderOnboardingStatusData.value?.verificationStatus ==
                  "approved";
              final tabLabels = <String>[
                approved ? AppStrings.myOrder.tr : AppStrings.document.tr,
                AppStrings.overview.tr,
                // Store tab removed.
                // AppStrings.store.tr,
                AppStrings.post.tr,
                AppStrings.statics.tr,
              ];
              return HomeTabScaffold(
                controller: _tabController,
                tabLabels: tabLabels,
                topBar: ProfileTopBar(
                  onGoLiveTap: handleGoLiveTap,
                  showGoLivePill: Platform.isAndroid,
                ),
                topBarHeight: topBarHeight,
                // One widget per tab, each owning its own state and its own
                // file. This screen keeps only what is genuinely shared: the
                // tab controller, the onboarding-status refresh triggers, the
                // go-live prompt, and the orders stream's lifetime.
                tabViews: [
                  // "Add catalog" sits in the Order tab but lands on Overview,
                  // and only this screen knows which index that is.
                  RiderOrderTab(
                    onAddCatalog: () => _tabController.animateTo(1),
                  ),
                  const RiderOverviewTab(),
                  // Store tab removed — EarnStoreCards (and its API load) no
                  // longer built.
                  // const RiderStoreTab(),
                  const RiderPostTab(),
                  const RiderStaticsTab(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

}

Future<void> handleGoLiveTap() async {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();

  // Already online → going OFF.
  if (_viewCtrl.shopStatusOpenClose.value) {
    // ...unless a ride is still running. A rider who drops offline mid-trip
    // leaves a customer in a car with no live order behind it: dispatch stops
    // tracking them, and the ride has no other rider to fall back to. The
    // toggle is refused outright rather than warned about, because there is no
    // version of this that ends well for the customer.
    //
    // `onGoingOrders` is the orders stream's own accepted-and-unfinished
    // bucket, so it clears itself the moment the ride completes or cancels —
    // nothing here has to be reset by hand.
    final hasOngoingRide =
        Get.isRegistered<DeliverPartnerOrdersController>() &&
            Get.find<DeliverPartnerOrdersController>().onGoingOrders.isNotEmpty;
    if (hasOngoingRide) {
      showRiderRideInProgressDialog();
      return;
    }
    _viewCtrl.toggleShopStatus();
    // If they manually go offline inside the auto window, don't let the
    // scheduler re-open them for the rest of today.
    RiderAutoGoLiveScheduler().noteManualOffDuringWindow();
    return;
  }

  // Going live is allowed only for a rider whose onboarding is APPROVED —
  // riderVerificationState is `completed` exactly when the backend's
  // `verificationStatus` is "approved" (see DeliveryPartnerController).
  // Anything else (pending review, rejected, documents missing) is blocked.
  final riderCtrl = Get.find<DeliveryPartnerController>();
  if (riderCtrl.riderVerificationState != RiderVerificationState.completed) {
    commonSnackBar(
        message: 'Finish your onboarding and get verified before going live.');
    return;
  }

  // After document verification, payment is required before going online.
  //
  // No profession check: this screen is reached only by GIG_WORKER accounts
  // (via GigWorkOptionsScreen / the Me tab), so everyone who can tap Go Live
  // here pays. The old `BIKE_RIDER || CAR_TAXI_DRIVER` narrowing let every
  // other gig profession — mechanic, tailor, beautician — go live for free.
  //
  // FIRST ONE FREE: a gig worker whose free job is still unused goes online
  // without paying — the payment page only appears once it is done
  // (`freeRideUsed == true`). Fail-closed on an absent flag.
  final depositBlocked = !AccountPlanEntitlement.to.hasActivePlan.value &&
      !riderCtrl.isFirstRideFree &&
      !riderCtrl.isSecurityDepositPaid;

  if (depositBlocked) {
    // Straight to the payment page — no dialog on this path. Tapping Go Live is
    // already the rider asking to work, so the deposit prompt would just be a
    // gate in front of a gate. The DIALOG version of this lives on arrival at
    // the Me section (see _maybeShowGoLivePrompt), where nothing has been
    // tapped and the rider does need telling.
    commonSnackBar(
        message:
            'Your payment is incomplete. Please complete the payment process to go live.');
    // Await the deposit flow, then refresh so a freshly-paid deposit is picked
    // up (it's reconciled server-side by a Razorpay webhook with no in-app
    // trigger). This replaces the old RouteAware.didPopNext refresh — it targets
    // the one return that can actually change onboarding status.
    await openContributionScreen();
    await riderCtrl.ridersOnboardingStatusRepoApi(forceRefresh: true);
    await AccountPlanEntitlement.to.refresh();
    return;
  }

  // Battery optimization is excluded from the gate — see
  // GoLivePermissionService.areRequiredGranted. Gating on it looped the
  // permission screen forever on Android 13+/16.
  if (await GoLivePermissionService.areRequiredGranted()) {
    _viewCtrl.toggleShopStatus();
    // First successful manual go-live opts the rider into the daily
    // 8 AM–10 PM auto window from tomorrow on.
    RiderAutoGoLiveScheduler().enableAfterManualGoLive();
    return;
  }
  final granted = await Get.to(() => const GoLivePermissionScreen());
  if (granted == true) {
    _viewCtrl.toggleShopStatus();
    RiderAutoGoLiveScheduler().enableAfterManualGoLive();
  }
}



import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/service/self_work_auto_golive_scheduler.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/tabs/self_employee_overview_tab.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/tabs/self_employee_service_tab.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/tabs/self_employee_statics_tab.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfEmployeeScreen extends StatefulWidget {
  const SelfEmployeeScreen({
    super.key,
  });

  @override
  State<SelfEmployeeScreen> createState() => _SelfEmployeeScreenState();
}

class _SelfEmployeeScreenState extends State<SelfEmployeeScreen>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();

  late final TabController _tabController;

  // Service leads, Overview second. Overview MUST stay at index 1 —
  // [BottomBarController.meOverviewTabIndex] is a hard-coded 1 that deep links
  // (e.g. profile_completion_reminder) use to jump straight to this tab.
  //
  // The Inquiry and Store tabs used to sit here; both were removed along with
  // the requests that backed them (the business chat-list socket emit and the
  // lazy earn-profile fetch). Post is gone too — it embedded the same
  // `PostType.myPosts` feed the Social section's My Post tab now owns.
  //
  // Removing Post kept Overview at index 1, which the deep link above depends
  // on; anything added here must go after Overview, not before it.
  List<String> get _tabs => [
        AppStrings.service.tr,
        AppStrings.overview.tr,
        AppStrings.statics.tr,
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: 0,
      vsync: this,
    );
    registerMeTabBackHandler(_tabController);
    // Resume the best-effort daily auto go-live scheduler if the provider opted
    // in on a previous session (08:00–22:00 auto open/close while the app is
    // open — best-effort, foreground only).
    SelfWorkAutoGoLiveScheduler().ensureStartedIfEnabled();
    _viewCtrl.UserFollowersAndPostsCount(userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() == AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  // with a sticky tab overlay that engages once the in-flow tabs
  // have scrolled past the top bar (mirrors grocery v2).
  Widget _buildScaffold(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: ProfileTopBar(
                onGoLiveTap: _handleGoLiveTap,
                showGoLivePill: Platform.isAndroid,
              ),
              // Frosted rather than the default solid white, so the pinned tab
              // row continues the header's glass instead of cutting a white bar
              // across it — same treatment as the Connect tab strip.
              tabBarColor: Colors.white.withValues(alpha: 0.45),
              topBarHeight: topBarHeight,
              // Order must match [_tabs]. One widget per tab, each owning its
              // own file; this screen keeps only what is genuinely shared —
              // the tab controller, the go-live handler and the scaffold.
              tabViews: const [
                SelfEmployeeServiceTab(),
                SelfEmployeeOverviewTab(),
                SelfEmployeeStaticsTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Going live needs background location, battery-optimization, and
  // display-over-other-apps. If any are missing we route through
  // [GoLivePermissionScreen] and only flip the shop status once the
  // user finishes granting them. Turning the shop back off doesn't
  // need any of these checks.
  Future<void> _handleGoLiveTap() async {
    // Already online → allow toggling offline without re-checking.
    if (_viewCtrl.shopStatusOpenClose.value) {
      _viewCtrl.toggleShopStatus();
      // If they manually go offline inside the auto window, don't let the
      // scheduler re-open them for the rest of today.
      SelfWorkAutoGoLiveScheduler().noteManualOffDuringWindow();
      return;
    }

    // The security deposit must be paid before a selfWork provider can go live
    // and receive service enquiries. Source of truth is the individual
    // profile's `securityDeposit` (GET individual profile), exposed via
    // [ViewPersonalDetailsController.canGoLive] — same pattern as the business
    // gate. Fail-open: block ONLY when the backend explicitly reports
    // `required && !paid` (canGoLive == false); a missing / paid / not-required
    // deposit always allows go-live. The backend also enforces this server-side
    // (402 on the go-live PUT). See docs/backend/SELF_WORK_GO_LIVE_GUIDE.md.
    //
    // FIRST SERVICE FREE: the provider's first service is on the house, so a
    // provider whose `freeServiceUsed` is still `false` goes live without
    // paying — the payment screen only appears once that free service is spent.
    // Fail-closed on an absent flag; see
    // [ViewPersonalDetailsController.isGoLiveAllowed], which ORs plan + free
    // service + legacy deposit and is the same gate the professionals screen
    // and the auto-go-live scheduler read.
    final depositBlocked = !_viewCtrl.isGoLiveAllowed;
    if (depositBlocked) {
      // Tell the provider why go-live is blocked, then route them to the
      // security-deposit flow to complete payment — go-live stays blocked
      // until it's paid. On return, refresh the profile so a freshly-paid
      // deposit (reconciled server-side by the Razorpay webhook, with no in-app
      // trigger) and the updated `freeServiceUsed` are picked up.
      commonSnackBar(
        message:
            'Your payment is incomplete. Please choose a plan to go live and receive service enquiries.',
      );
      await openContributionScreen();
      await _viewCtrl.viewPersonalProfile(forceRefresh: true);
      await AccountPlanEntitlement.to.refresh();
      return;
    }

    // Battery optimization is excluded from the gate — see
    // GoLivePermissionService.areRequiredGranted. Gating on it looped the
    // permission screen forever on Android 13+/16.
    if (await GoLivePermissionService.areRequiredGranted()) {
      _viewCtrl.toggleShopStatus();
      // First successful manual go-live opts the provider into the daily
      // 8 AM–10 PM auto window from tomorrow on.
      SelfWorkAutoGoLiveScheduler().enableAfterManualGoLive();
      return;
    }
    final granted = await Get.to(() => const GoLivePermissionScreen());
    if (granted == true) {
      _viewCtrl.toggleShopStatus();
      SelfWorkAutoGoLiveScheduler().enableAfterManualGoLive();
    }
  }

}


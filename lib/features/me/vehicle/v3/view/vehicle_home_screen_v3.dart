import 'package:BlueEra/core/services/ads/admob_banner_ad_widget.dart';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
// import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/controller/profile_statistics_controller.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/tabs/vehicle_listings_tab_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/tabs/vehicle_overview_tab_v3.dart';
// import 'package:BlueEra/features/me/vehicle/v3/view/tabs/vehicle_post_tab_v3.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/go_live_product_gate.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Vehicle showroom dashboard (v3) — the owner's home for a **Vehicle Sales**
/// business, rebuilt against the four-tier catalog contract.
///
/// Structurally this IS [GroceryHomeScreenV2]: same shell (blurred top bar +
/// pill tabs), same four tabs (catalog / overview / posts / statistics), same
/// per-tab lazy fetch and per-tab pull-to-refresh. The only thing that
/// differs is what the first tab manages — vehicle listings instead of
/// grocery inventory — which is exactly the point of sharing the chrome.
///
/// It supersedes `VehicleHomeScreenV2`, which is wired to the removed
/// `/vehicles/*` API (facilities, gallery, testimonials and contact-us were
/// all dropped from this service — see §1 of the integration guide), so none
/// of its tabs are reused here.
class VehicleHomeScreenV3 extends StatefulWidget {
  final String businessId;

  const VehicleHomeScreenV3({super.key, required this.businessId});

  @override
  State<VehicleHomeScreenV3> createState() => _VehicleHomeScreenV3State();
}

class _VehicleHomeScreenV3State extends State<VehicleHomeScreenV3>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  int _selectedTab = 0;
  late final TabController _tabController;

  late final VehicleV3Controller _vehicleController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  /// Drives the order/enquiry chat list, the same way the grocery home
  /// hydrates it — shared with Connect, and socket-updated while open.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Post tab removed for business accounts — the merchant's own feed is no
  // longer surfaced here. Restore the label, the `VehiclePostTabV3` view and
  // the matching `case` in both switches below together, or indices desync.
  List<String> get _tabs => [
        AppStrings.vehiclesTab.tr,
        AppStrings.overviewTab.tr,
        // AppStrings.postTabLabel.tr,
        AppStrings.staticsTab.tr,
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_handleTabChange);
    registerMeTabBackHandler(_tabController);
    _vehicleController = getOrPut(() => VehicleV3Controller());
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    _fetchForTab(_selectedTab);

    // Once-a-day "list your vehicles" nudge. Lives here rather than in
    // VehicleScreenV3 because its CTA needs this screen's TabController.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      showAddProductPromptIfNeeded(
        context: context,
        spec: const AddProductPromptSpec(
          // Headline and CTA are different strings — the headline names what
          // the merchant sells, the button is the action. Both were
          // `addVehicleLabel`, so the sheet read "Add vehicle" twice.
          titleKey: AppStrings.addPromptTitleVehicle,
          ctaKey: AppStrings.addVehicleLabel,
          icon: Icons.directions_car_filled_outlined,
        ),
        // Tab 0 is Vehicles — the add surface, same as grocery's tab 0.
        onAddProduct: () => _tabController.animateTo(0),
        // No livePhotoGate: that exists to stop this prompt stacking on top of
        // the live-photo sheet when both fire on the SAME landing. Here they
        // can't — live photos are prompted from the Overview tab — and keeping
        // the gate would suppress the add prompt on the Vehicles tab for any
        // showroom without live photos, which is precisely the merchant who
        // most needs to be told to list a vehicle.
      );
    });
  }

  /// Per-tab API dispatcher — only the visible tab's data is fetched, and
  /// through the *IfNeeded* guard so swiping back and forth doesn't refire it.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        _vehicleController.loadDashboardIfNeeded(widget.businessId);
        break;
      case 1:
        // Overview reads the permanent business controller — no vehicle API.
        //
        // It IS where the live-photo nudge belongs: live photos are part of
        // the public profile this tab edits, so the sheet appears when the
        // merchant opens Overview rather than over the Vehicles tab they
        // landed on. The sheet self-skips once any photo exists.
        _maybePromptLivePhotos();
        break;
      // Post was case 2; Statistics moved up with it removed.
      case 2:
        // Statistics keeps itself alive, so its initState won't re-run on a
        // later tap; refresh here instead. On the first tap the controller
        // isn't registered yet (the screen fires its own init this frame), so
        // skip to avoid a double fetch.
        if (Get.isRegistered<ProfileStatisticsController>()) {
          Get.find<ProfileStatisticsController>().refresh();
        }
        break;
    }
  }

  void _handleTabChange() {
    if (_selectedTab != _tabController.index) {
      setState(() => _selectedTab = _tabController.index);
      _fetchForTab(_tabController.index);
    }
  }

  /// One-shot per mount. The sheet helper only guards on "photos already
  /// exist" and "a sheet is already open", so without this it would re-pop on
  /// every swipe back to Overview until a photo is added.
  bool _livePhotoPromptShown = false;

  void _maybePromptLivePhotos() {
    if (_livePhotoPromptShown) return;
    _livePhotoPromptShown = true;
    // After the frame: the tab body is still building when the dispatcher
    // runs, and the helper reads ModalRoute to decide whether something is
    // already on top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _businessController,
      );
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Pull-to-refresh fires only the API(s) behind the visible tab.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        await _vehicleController.loadDashboard(widget.businessId);
        break;
      case 1:
        await _businessController.viewBusinessProfile();
        break;
      // Post was case 2; Statistics moved up with it removed.
      case 2:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: HomeTabScaffold(
          controller: _tabController,
          tabLabels: _tabs,
          topBar: _buildTopBar(),
          topBarHeight: topBarHeight,
          tabViews: [
            _tabScroll(withBannerAdBelow(VehicleListingsTabV3(businessId: widget.businessId))),
            _tabScroll(const VehicleOverviewTabV3()),
            ProfileStatisticsScreen(userId: widget.businessId),
          ],
        ),
      ),
    );
  }

  /// The shared refreshable body. Tabs are content-only and build against the
  /// `left: 20 / nothing on the right` contract set here, which is what lets
  /// their rails bleed off the right edge.
  Widget _tabScroll(Widget tab) {
    return RefreshIndicator(
      onRefresh: _onRefreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20,
          top: SizeConfig.size10,
          bottom: kBottomNavigationBarHeight + 30,
        ),
        child: tab,
      ),
    );
  }

  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              topInset + SizeConfig.size8,
              SizeConfig.size12,
              SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: Row(
              children: [
                _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
                SizedBox(width: SizeConfig.size6),
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(
                    icon: Icons.notifications_none, onTap: _openNotifications),
                SizedBox(width: SizeConfig.size6),
                _goLivePill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
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

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: SizeConfig.size36,
              width: SizeConfig.size36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC9CDD5), width: 1),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        isUpdating: _businessController.isAvailabilityUpdating.value,
        onTap: _handleGoLiveTap,
        onScheduleTap: _businessController.openScheduleControl,
      ),
    );
  }

  /// The pill is a plain on/off switch over the schedule-driven state: with
  /// weekly hours saved it flips today's open/closed state, with none it shows
  /// the "Set visiting hours" prompt. Hours are set and edited from the clock
  /// button beside the pill. The security-deposit gate is enforced inside
  /// toggleLiveNow().
  ///
  /// An EMPTY showroom is checked first, ahead of that payment gate — see
  /// [ensureCatalogueBeforeGoLive]. Only when going live; going offline is
  /// never blocked.
  Future<void> _handleGoLiveTap() async {
    if (!_businessController.shopStatus.value.isOpenNow) {
      final ok = await ensureCatalogueBeforeGoLive(
        context: context,
        spec: const AddProductPromptSpec(
          titleKey: AppStrings.addPromptTitleVehicle,
          ctaKey: AppStrings.addVehicleLabel,
          icon: Icons.directions_car_filled_outlined,
        ),
        ensureLoaded: () =>
            _vehicleController.loadDashboardIfNeeded(widget.businessId),
        hasItems: () =>
            _vehicleController.myListings.isNotEmpty ||
            _vehicleController.myStockedCategories.isNotEmpty,
        isLoaded: () =>
            _vehicleController.listingsStatus.value == Status.COMPLETE,
        onAddItems: () => _tabController.animateTo(0),
      );
      if (!ok) return;
    }
    await _businessController.toggleLiveNow();
  }
}

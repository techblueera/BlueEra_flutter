import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/grocery/view/admin/shop_availability_screen.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/actions/vehicle_owner_actions.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_overview_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_posts_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_stats_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_vehicles_tab_v2.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Vehicle "me" profile home (v2) — owner-side dashboard for the
/// `vehicle-service` microservice.
///
/// Redesigned to match the architecture of `HospitalHomeScreenV2`: a thin
/// shell (gradient top bar + pill tab strip) that delegates each tab to a
/// dedicated file under `tabs/`, with shared building blocks in
/// `widgets/` and owner CRUD flows in `actions/`. Five tabs adapted to
/// vehicle ownership: Inquiry, Overview, Vehicles, Posts, Stats.
class VehicleHomeScreenV2 extends StatefulWidget {
  const VehicleHomeScreenV2({super.key});

  @override
  State<VehicleHomeScreenV2> createState() => _VehicleHomeScreenV2State();
}

class _VehicleHomeScreenV2State extends State<VehicleHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  int _selectedTab = 0; // default to first tab
  late final TabController _tabController;

  final List<String> _tabs = [
    AppStrings.inquiryTab.tr,
    AppStrings.overview.tr,
    AppStrings.vehiclesTab.tr,
    AppStrings.posts.tr,
    AppStrings.statsTab.tr,
  ];
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_handleTabChange);
    registerMeTabBackHandler(_tabController);
    // ProfileTopBar's Go-Live pill resolves ViewPersonalDetailsController via
    // Get.find during the header build, so make sure it's registered before
    // the first frame regardless of which tab body builds first.
    getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    _ctrl.fetchVehicleTypes();
    _ctrl.fetchMyVehicles();
    _ctrl.fetchMyContacts(showProgress: false);
    _ctrl.fetchMyGallery(showProgress: false);
    // Hydrate the business chat list for the Inquiry tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  /// Keep [_selectedTab] synced so the Vehicles-tab FAB shows/hides correctly.
  void _handleTabChange() {
    if (_selectedTab != _tabController.index) {
      setState(() => _selectedTab = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _ctrl.fetchMyVehicles(showProgress: false),
      _ctrl.fetchMyGallery(showProgress: false),
      _ctrl.fetchMyContacts(showProgress: false),
    ]);
  }

  /// Wraps a tab body in a refreshable scroll view for the [TabBarView].
  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.transparent,
      // backgroundColor: const Color(0xFFEAF2FB),

      body: SafeArea(
        top: false,
        child: HomeTabScaffold(
          controller: _tabController,
          tabLabels: _tabs,
          topBar: _buildTopBar(),

          // topBar: ProfileTopBar(
          //   onGoLiveTap: handleGoLiveTap,
          //   showGoLivePill: Platform.isAndroid,
          // ),
          topBarHeight: MediaQuery.of(context).padding.top + 56,
          tabViews: [
            _tabScroll(VehicleInquiryTabV2(
              onAddVehicles: () => _tabController.animateTo(2),
            )),
            _tabScroll(VehicleOverviewTabV2(controller: _ctrl)),
            _tabScroll(VehicleVehiclesTabV2(controller: _ctrl)),
            _tabScroll(const VehiclePostsTabV2()),
            _tabScroll(VehicleStatsTabV2(controller: _ctrl)),
          ],
        ),
      ),
      // floatingActionButton: _selectedTab == 2
      //     ? FloatingActionButton.extended(
      //         backgroundColor: AppColors.primaryColor,
      //         icon: const Icon(Icons.add, color: Colors.white),
      //         label: CustomText(
      //           AppStrings.addVehicleLabel.tr,
      //           color: Colors.white,
      //           fontSize: 13,
      //           fontWeight: FontWeight.w700,
      //         ),
      //         onPressed: () => VehicleOwnerActions.addVehicle(context, _ctrl),
      //       )
      //     : null,
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
              border: Border.all(
                color: Colors.white,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
                SizedBox(width: SizeConfig.size6),
                // Pills wrapped in Flexible so their inner text can ellipsize
                // instead of pushing the row past its width.
                SizedBox(width: SizeConfig.size6),
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(icon: Icons.notifications_none, onTap: _openNotifications),
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
          child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
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
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
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
        onTap: handleGoLiveTap_,
      ),
    );
  }

  Future<void> handleGoLiveTap_() async {
    // The pill reflects the schedule-driven auto open/close state; tapping
    // opens the shop-status control — first run routes to the weekly hours
    // editor, thereafter the status sheet (with the today-only override).
    await _businessController.openAvailabilityControl();
  }

}

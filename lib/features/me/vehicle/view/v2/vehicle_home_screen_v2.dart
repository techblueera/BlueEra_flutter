import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
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
    with SingleTickerProviderStateMixin {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  int _selectedTab = 1; // default to Overview
  late final TabController _tabController;

  final List<String> _tabs = [
    AppStrings.inquiryTab.tr,
    AppStrings.overview.tr,
    AppStrings.vehiclesTab.tr,
    AppStrings.posts.tr,
    AppStrings.statsTab.tr,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_handleTabChange);
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
          topBar: ProfileTopBar(
            onGoLiveTap: handleGoLiveTap,
            showGoLivePill: Platform.isAndroid,
          ),
          topBarHeight: MediaQuery.of(context).padding.top + 56,
          tabViews: [
            _tabScroll(const VehicleInquiryTabV2()),
            _tabScroll(VehicleOverviewTabV2(controller: _ctrl)),
            _tabScroll(VehicleVehiclesTabV2(controller: _ctrl)),
            _tabScroll(const VehiclePostsTabV2()),
            _tabScroll(VehicleStatsTabV2(controller: _ctrl)),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: CustomText(
                AppStrings.addVehicleLabel.tr,
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              onPressed: () => VehicleOwnerActions.addVehicle(context, _ctrl),
            )
          : null,
    );
  }

}

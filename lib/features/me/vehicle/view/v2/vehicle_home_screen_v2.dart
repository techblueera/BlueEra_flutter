import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_shop_availability_screen.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_overview_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_posts_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_stats_tab_v2.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/tabs/vehicle_vehicles_tab_v2.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Vehicle "me" profile home (v2) — owner-side dashboard for the
/// `vehicle-service` microservice.
///
/// UI scaffolding mirrors `SchoolHomeScreenV2` / `HospitalHomeScreenV2`:
/// a thin shell (gradient top bar + pill tab strip) that delegates each
/// tab to a dedicated file under `tabs/`. Five tabs adapted to vehicle
/// ownership: Inquiry, Overview, Vehicles, Posts, Stats.
class VehicleHomeScreenV2 extends StatefulWidget {
  const VehicleHomeScreenV2({super.key});

  @override
  State<VehicleHomeScreenV2> createState() => _VehicleHomeScreenV2State();
}

class _VehicleHomeScreenV2State extends State<VehicleHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  /// Local live state backing the Go-Live toggle/pill.
  bool isShopGoLive = false;

  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  late final TabController _tabController;

  List<String> get _tabs => [
        AppStrings.inquiryTab.tr,
        AppStrings.overview.tr,
        AppStrings.vehiclesTab.tr,
        AppStrings.posts.tr,
        AppStrings.statsTab.tr,
      ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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

  @override
  void dispose() {
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
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(
                  icon: Icons.notifications_none,
                  onTap: _openNotifications,
                ),
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

  /// Drive the Go-Live toggle. Turning ON opens the shop-availability
  /// (set-time) form directly — no permission gate. The form persists the
  /// hours and goes live via the backend, popping back `true` on success.
  /// Turning OFF just flips the local toggle.
  Future<void> handleGoLiveTap() async {
    if (isShopGoLive) {
      setState(() => isShopGoLive = false);
      return;
    }

    final result = await Get.to(() => const GroceryShopAvailabilityScreen());
    if (result == true && mounted) {
      setState(() => isShopGoLive = true);
    }
  }

  Widget _goLivePill() {
    return GestureDetector(
      onTap: handleGoLiveTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(AppStrings.goLive.tr,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor),
                  SizedBox(width: SizeConfig.size6),
                  Container(
                    width: 30,
                    height: 18,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                          isShopGoLive ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondaryTextColor
                            .withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      alignment: isShopGoLive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                            color: isShopGoLive
                                ? Colors.white
                                : AppColors.secondaryTextColor,
                            shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: MediaQuery.of(context).padding.top + 56,
              tabViews: [
                _tabScroll(const VehicleInquiryTabV2()),
                _tabScroll(VehicleOverviewTabV2(controller: _ctrl)),
                _tabScroll(VehicleVehiclesTabV2(controller: _ctrl)),
                _tabScroll(const VehiclePostsTabV2()),
                _tabScroll(VehicleStatsTabV2(controller: _ctrl)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

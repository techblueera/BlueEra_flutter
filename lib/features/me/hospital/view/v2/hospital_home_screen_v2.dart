import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_departments_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_facilities_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_overview_tab_v2.dart';
// import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_posts_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_stats_tab_v2.dart';
import 'package:BlueEra/features/me/medical/controller/hospital_appointment_controller.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hospital "me" profile home (v2) — redesigned to match the layout used by
/// `MedicalHomeScreenV2` while preserving every action surfaced by the
/// original `HospitalHomeScreen`.
class HospitalHomeScreenV2 extends StatefulWidget {
  const HospitalHomeScreenV2({super.key});

  @override
  State<HospitalHomeScreenV2> createState() => _HospitalHomeScreenV2State();
}

class _HospitalHomeScreenV2State extends State<HospitalHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  late final HospitalServiceAiController _hospitalController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  // Registered up-front so the Bookings tab's Obx has a live controller
  // to observe even if the user opens the tab before it hydrates. Kept even
  // though this screen no longer calls it directly (see the parked refresh in
  // [_tabScroll]) — the registration is the point.
  // ignore: unused_field
  final _appointmentController =
      getOrPut(() => HospitalAppointmentController());
  late final TabController _tabController;

  static final _tabs = [
    AppStrings.hospitalDepartments.tr,
    AppStrings.overview.tr,
    AppStrings.facilities.tr,
    // Post tab removed for business accounts. Restore the label together with
    // the `HospitalPostsTabV2` view below.
    // AppStrings.posts.tr,
    AppStrings.hospitalStats.tr,
  ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors `_chatViewController` in `professionals_main.dart`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches.
  // Mirrors `connect_main_page.dart`'s top-level `chatFlagController`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    registerMeTabBackHandler(_tabController);
    _hospitalController = getOrPut(() => HospitalServiceAiController());
    if (_hospitalController.hospitalDataResModel?.value.data == null) {
      _hospitalController.getHospitalFullDetailsController();
    }
    // Pull the business profile so the QR card (which reads
    // `businessProfileDetails.data.userId`) has data on first paint.
    if (_businessController.businessProfileDetails.value?.data == null) {
      _businessController.viewBusinessProfile();
    }
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what `professionals_main.dart`
    // does for its Order tab and `ConnectMainPage` does for its Inquiry tab.
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

  /// Wraps a tab body in a refreshable scroll view for the [TabBarView].
  /// Pull-to-refresh always refetches hospital details, and also refreshes
  /// the owner-inbox appointments when the Bookings tab is active so
  /// swiping down there feels responsive.
  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _hospitalController.getHospitalFullDetailsController(),
          // Index 3 was the Post tab, which is now removed — so this owner-
          // appointments refresh had nowhere left to fire from. It looks like
          // a stale index even before that (Post is not an appointments tab;
          // the list is Departments/Overview/Facilities/Post/Stats), so it is
          // parked here rather than silently re-pointed at Stats, which is
          // what index 3 means now. Point it at the right tab if this refresh
          // is still wanted.
          // if (_tabController.index == 3) _appointmentController.fetchOwnerAppointments(),
        ]);
      },
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
                _tabScroll(
                    HospitalDepartmentsTabV2(controller: _hospitalController)),
                _tabScroll(
                    HospitalOverviewTabV2(controller: _hospitalController)),
                _tabScroll(
                    HospitalFacilitiesTabV2(controller: _hospitalController)),
                // _tabScroll(const HospitalPostsTabV2()),
                _tabScroll(const HospitalStatsTabV2()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
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
          child: Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ProfileMenuDrawer()),
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

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        isUpdating: _businessController.isAvailabilityUpdating.value,
        onTap: handleGoLiveTap,
        onScheduleTap: _businessController.openScheduleControl,
      ),
    );
  }

  /// Drive the Go-Live toggle — a plain on/off switch. With weekly hours saved
  /// it flips today's open/closed state straight from the pill; with no hours
  /// yet it shows the "Set visiting hours" prompt. Hours are set and edited
  /// from the clock button beside the pill.
  Future<void> handleGoLiveTap() async {
    await _businessController.toggleLiveNow();
  }

  // ─────────────────────────────────────────────
  // PROFILE ROW
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // TABS CARD
  // ─────────────────────────────────────────────
}

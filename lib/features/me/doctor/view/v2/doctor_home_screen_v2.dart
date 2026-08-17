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
import 'package:BlueEra/features/me/doctor/controller/doctor_appointment_controller.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_profile_controller.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_stats_controller.dart';
import 'package:BlueEra/features/me/doctor/view/v2/doctor_required_details_form.dart';
import 'package:BlueEra/features/me/doctor/view/v2/tabs/doctor_about_me_tab.dart';
import 'package:BlueEra/features/me/doctor/view/v2/tabs/doctor_booking_tab.dart';
import 'package:BlueEra/features/me/doctor/view/v2/tabs/doctor_overview_tab.dart';
import 'package:BlueEra/features/me/doctor/view/v2/tabs/doctor_statics_tab.dart';
// import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_posts_tab_v2.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standalone-doctor "me" dashboard — the 5-tab host from the design:
/// Booking · Overview · About Me · Posts · Statics.
///
/// This is a NEW module sitting alongside `me/hospital/`, not a variant of it:
/// a standalone doctor owns their own business listing and their own
/// appointments, where a hospital OPD doctor is a row inside a hospital. The
/// hospital flow is untouched.
class DoctorHomeScreenV2 extends StatefulWidget {
  const DoctorHomeScreenV2({super.key});

  @override
  State<DoctorHomeScreenV2> createState() => _DoctorHomeScreenV2State();
}

class _DoctorHomeScreenV2State extends State<DoctorHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  late final TabController _tabController;

  /// The dashboard is the single source of truth for the doctor profile —
  /// every tab reads from this instance rather than re-calling
  /// `GET /doctors/me`.
  late final DoctorProfileController _profileController;
  late final DoctorAppointmentController _appointmentController;
  late final DoctorStatsController _statsController;

  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Registered up-front so the chat surfaces this shell can reach have live
  // controllers, matching what the hospital/professional dashboards do.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  static const int _bookingTabIndex = 0;

  static final _tabs = [
    AppStrings.doctorBooking.tr,
    AppStrings.overview.tr,
    // Tab reads "About"; the card inside it is titled "About Me".
    AppStrings.doctorAboutTab.tr,
    // Post tab removed for business accounts. Restoring it means putting back
    // the label, the `HospitalPostsTabV2` view, and moving the Statics index
    // in [_tabScroll] from 3 back to 4.
    // AppStrings.posts.tr,
    AppStrings.doctorStatics.tr,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    registerMeTabBackHandler(_tabController);

    _profileController = getOrPut(() => DoctorProfileController());
    _appointmentController = getOrPut(() => DoctorAppointmentController());
    _statsController = getOrPut(() => DoctorStatsController());

    // The business profile carries the identity, cover, gallery, contact and
    // availability the Overview and About tabs render. Fetch it only when it
    // hasn't been loaded already.
    if (_businessController.businessProfileDetails.value?.data == null) {
      _businessController.viewBusinessProfile();
    }
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

  /// Pull-to-refresh. Refreshes the doctor profile and business profile
  /// always, plus whichever tab-specific source is on screen.
  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _profileController.fetchProfile(),
          _businessController.viewBusinessProfile(),
          if (_tabController.index == _bookingTabIndex)
            _appointmentController.fetchAppointments(),
          // Statics: index 3 since the Post tab was removed (was 4).
          if (_tabController.index == 3)
            _statsController.fetchStats(force: true),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
        child: child,
      ),
    );
  }

  /// Statics tiles jump to the Booking tab pre-filtered to that status.
  void _openBookingFiltered(String status) {
    _appointmentController.setStatusFilter(status);
    _tabController.animateTo(_bookingTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        // The tabs are gated on the doctor card's mandatory fields — see
        // [_buildBody]. Reading the controller here (rather than inside each
        // tab) is what lets the whole dashboard swap between the gate form and
        // the tab shell.
        child: Obx(() => _buildBody()),
      ),
    );
  }

  /// Three states, in priority order:
  ///
  ///  1. first fetch still in flight → spinner under the top bar;
  ///  2. fetch failed outright → retry, NOT the gate. A network error is not
  ///     "no profile", and letting the gate POST a create over an existing
  ///     profile returns `400 "User already has a doctor profile"`;
  ///  3. card fields missing → the mandatory-details form in place of the tabs;
  ///  4. otherwise the normal Booking · Overview · About · Statics shell.
  Widget _buildBody() {
    if (!_profileController.isReady.value) {
      return _gateShell(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_profileController.hasLoadFailure) {
      return _gateShell(_loadErrorBody());
    }

    if (!_profileController.isCardProfileComplete) {
      return _gateShell(
        DoctorRequiredDetailsForm(controller: _profileController),
      );
    }

    return HomeTabScaffold(
      controller: _tabController,
      tabLabels: _tabs,
      topBar: _buildTopBar(),
      topBarHeight: MediaQuery.of(context).padding.top + 56,
      tabViews: [
        _tabScroll(DoctorBookingTab(controller: _appointmentController)),
        _tabScroll(DoctorOverviewTab(controller: _profileController)),
        _tabScroll(DoctorAboutMeTab(controller: _profileController)),
        // _tabScroll(const HospitalPostsTabV2()),
        _tabScroll(
          DoctorStaticsTab(
            controller: _statsController,
            onStatusTap: _openBookingFiltered,
          ),
        ),
      ],
    );
  }

  /// Keeps the dashboard's top bar above [child] while the tabs are hidden, so
  /// the drawer, notifications and Go-Live stay reachable — without it the
  /// gate would be a screen with no way out.
  Widget _gateShell(Widget child) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).padding.top + 56,
          child: _buildTopBar(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _profileController.fetchProfile(),
                _businessController.viewBusinessProfile(),
              ]);
            },
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _loadErrorBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size24,
          vertical: SizeConfig.size40,
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              _profileController.loadError.value,
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
            SizedBox(height: SizeConfig.size16),
            OutlinedButton(
              onPressed: _profileController.fetchProfile,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                ),
              ),
              child: CustomText(
                AppStrings.retry.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR — hamburger · Earn · bell · Go live
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
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: Row(
              children: [
                _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
                SizedBox(width: SizeConfig.size6),
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
            child: ProfileMenuDrawer(),
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  /// Same Go-Live behaviour as every other business dashboard: the pill shows
  /// the schedule-driven open/close state and toggles it directly, while the
  /// clock button beside it sets and edits the visiting hours.
  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        isUpdating: _businessController.isAvailabilityUpdating.value,
        onTap: _businessController.toggleLiveNow,
        onScheduleTap: _businessController.openScheduleControl,
      ),
    );
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
}

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
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/tabs/lab_facilities_tab_v2.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/tabs/lab_overview_tab_v2.dart';
// import 'package:BlueEra/features/me/laboratory/view/v2/tabs/lab_posts_tab_v2.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/tabs/lab_stats_tab_v2.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/tabs/lab_tests_tab_v2.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Laboratory "me" profile home (v2) — redesigned to mirror the layout
/// used by `HospitalHomeScreenV2` while preserving every action surfaced
/// by the legacy `LabFullDetailsScreen`. Standalone screen — does NOT
/// touch existing routes or `LaboratoryMain`.
class LabHomeScreenV2 extends StatefulWidget {
  const LabHomeScreenV2({super.key});

  @override
  State<LabHomeScreenV2> createState() => _LabHomeScreenV2State();
}

class _LabHomeScreenV2State extends State<LabHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  late final LabFullDetailsController _labController;
  final _businessController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  late final TabController _tabController;
  List<String> get _tabs => [
        AppStrings.tests.tr,
        AppStrings.overview.tr,
        AppStrings.facilities.tr,
        // Post tab removed for business accounts. Restore the label together
        // with the `LabPostsTabV2` view below.
        // AppStrings.posts.tr,
        AppStrings.stats.tr,
      ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2`, `SchoolHomeScreenV2`,
  // `MedicalHomeScreenV2` and the Order tab in `professionals_main.dart`.
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches. Mirrors the
  // top-level registration in `connect_main_page.dart`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController = getOrPut(() => ChatFlagController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    registerMeTabBackHandler(_tabController);
    if (!Get.isRegistered<LabFullDetailsController>()) {
      _labController = Get.put(LabFullDetailsController(), permanent: true);
    } else {
      _labController = Get.find<LabFullDetailsController>();
    }
    if (_labController.details.value == null) {
      _labController.fetchFullDetails();
    }
    if (_businessController.businessProfileDetails.value?.data == null) {
      _businessController.viewBusinessProfile();
    }
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what the other v2 screens
    // (Hospital, School, Medical) and `professionals_main.dart` do.
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
  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: _labController.fetchFullDetails,
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
      // No hardcoded background — inherit the themed scaffold background so the
      // app-wide themeable background (color via the theme, banner via
      // GetMaterialApp.builder; both driven by AppBackgroundController) shows
      // through, same as grocery_home_screen_v2. The frosted-glass top bar
      // lets it through at the header too.
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
                _tabScroll(LabTestsTabV2(controller: _labController)),
                _tabScroll(LabOverviewTabV2(controller: _labController)),
                _tabScroll(LabFacilitiesTabV2(controller: _labController)),
                // _tabScroll(const LabPostsTabV2()),
                _tabScroll(const LabStatsTabV2()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ───
  // Frosted-glass header (matches grocery / hospital) so the app-wide
  // themeable background shows through behind it, instead of a solid blue
  // gradient that would hide it.
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

  /// Drive the Go-Live toggle — a plain on/off switch. With weekly hours saved
  /// it flips today's open/closed state straight from the pill; with no hours
  /// yet it shows the "Set visiting hours" prompt. Hours are set and edited
  /// from the clock button beside the pill.
  Future<void> handleGoLiveTap() async {
    await _businessController.toggleLiveNow();
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

  // ─── Profile row ───
}

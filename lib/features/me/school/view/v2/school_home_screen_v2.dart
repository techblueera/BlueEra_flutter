import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/go_live/go_live_availability_mixin.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_academics_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_overview_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_posts_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_stats_tab_v2.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// School "me" profile home (v2) — redesigned to mirror the layout used
/// by `HospitalHomeScreenV2` while preserving every action surfaced by
/// the legacy `SchoolHomeScreen`. Standalone screen — does NOT touch
/// existing routes or `SchoolMain`.
class SchoolHomeScreenV2 extends StatefulWidget {
  const SchoolHomeScreenV2({super.key});

  @override
  State<SchoolHomeScreenV2> createState() => _SchoolHomeScreenV2State();
}

class _SchoolHomeScreenV2State extends State<SchoolHomeScreenV2>
    with SingleTickerProviderStateMixin, GoLiveAvailabilityMixin {
  late final SchoolAboutUsController _schoolController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  late final TabController _tabController;

  List<String> get _tabs => [
    AppStrings.inquiry.tr,
    AppStrings.overview.tr,
    AppStrings.academics.tr,
    AppStrings.posts.tr,
    AppStrings.stats.tr,
  ];


  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2` and the Order tab in
  // `professionals_main.dart`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches. Mirrors the
  // top-level registration in `connect_main_page.dart`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _schoolController = getOrPut(() => SchoolAboutUsController());
    if ((_schoolController.schoolDetailsData?.value.id ?? '').isEmpty) {
      _schoolController.getSchoolByIdController();
    }
    if (_businessController.businessProfileDetails.value?.data == null) {
      _businessController.viewBusinessProfile();
    }
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what `HospitalHomeScreenV2`
    // and `professionals_main.dart` do for their inquiry/order tabs.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // Remind business sellers to set shop availability if they never have.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      maybeShowAvailabilityReminder();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: _schoolController.getSchoolByIdController,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
        child: child,
      ),
    );
  }
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        topInset + SizeConfig.size8,
        SizeConfig.size12,
        SizeConfig.size10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E88FF), Color(0xFF0040A0)],
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
          _circleIconButton(icon: Icons.notifications_none, onTap: _openNotifications),
          SizedBox(width: SizeConfig.size6),
          _goLivePill(),
        ],
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
        height: SizeConfig.size36,
        width: SizeConfig.size36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.mainTextColor),
      ),
    );
  }

  Widget _goLivePill() {
    return GestureDetector(
      onTap: handleGoLiveTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(AppStrings.goLive.tr,
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isShopGoLive ? AppColors.primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: isShopGoLive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
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
              // topBar: _buildTopBar(),

                 topBar: ProfileTopBar(
                onGoLiveTap: handleGoLiveTap,
                showGoLivePill: Platform.isAndroid,
              ),
              topBarHeight: MediaQuery.of(context).padding.top + 56,
              tabViews: [
                _tabScroll(const SchoolInquiryTabV2()),
                _tabScroll(SchoolOverviewTabV2(controller: _schoolController)),
                _tabScroll(SchoolAcademicsTabV2(controller: _schoolController)),
                _tabScroll(const SchoolPostsTabV2()),
                _tabScroll(const SchoolStatsTabV2()),
              ],
            ),
          ],
        ),
      ),
    );
  }



}


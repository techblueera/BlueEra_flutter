import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_academics_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_overview_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_posts_tab_v2.dart';
import 'package:BlueEra/features/me/school/view/v2/tabs/school_stats_tab_v2.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_top_bar.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
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
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
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

  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }



}


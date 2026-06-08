import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_departments_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_facilities_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_overview_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_posts_tab_v2.dart';
import 'package:BlueEra/features/me/hospital/view/v2/tabs/hospital_stats_tab_v2.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Hospital "me" profile home (v2) — redesigned to match the layout used by
/// `MedicalHomeScreenV2` while preserving every action surfaced by the
/// original `HospitalHomeScreen`.
class HospitalHomeScreenV2 extends StatefulWidget {
  const HospitalHomeScreenV2({super.key});

  @override
  State<HospitalHomeScreenV2> createState() => _HospitalHomeScreenV2State();
}

class _HospitalHomeScreenV2State extends State<HospitalHomeScreenV2>
    with SingleTickerProviderStateMixin {
  late final HospitalServiceAiController _hospitalController;
  final _businessController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  late final TabController _tabController;

  bool _isGoLive = false;

  static final _tabs = [
    AppStrings.hospitalInquiry.tr,
    AppStrings.overview.tr,
    AppStrings.hospitalDepartments.tr,
    AppStrings.facilities.tr,
    AppStrings.posts.tr,
    AppStrings.hospitalStats.tr,
  ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors `_chatViewController` in `professionals_main.dart`.
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches.
  // Mirrors `connect_main_page.dart`'s top-level `chatFlagController`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController = getOrPut(() => ChatFlagController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
  Widget _tabScroll(Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        await _hospitalController.getHospitalFullDetailsController();
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
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: MediaQuery.of(context).padding.top + 56,
              tabViews: [
                _tabScroll(const HospitalInquiryTabV2()),
                _tabScroll(HospitalOverviewTabV2(controller: _hospitalController)),
                _tabScroll(
                    HospitalDepartmentsTabV2(controller: _hospitalController)),
                _tabScroll(
                    HospitalFacilitiesTabV2(controller: _hospitalController)),
                _tabScroll(const HospitalPostsTabV2()),
                _tabScroll(const HospitalStatsTabV2()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BACKGROUND PATTERN
  // ─────────────────────────────────────────────
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
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
          _circleIconButton(
            icon: Icons.notifications_none,
            onTap: _openNotifications,
          ),
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
      onTap: () => setState(() => _isGoLive = !_isGoLive),
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
            CustomText(
              AppStrings.goLive.tr,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _isGoLive ? AppColors.primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: _isGoLive ? Alignment.centerRight : Alignment.centerLeft,
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

  // ─────────────────────────────────────────────
  // PROFILE ROW
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // TABS CARD
  // ─────────────────────────────────────────────
}


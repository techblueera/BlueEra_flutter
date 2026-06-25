
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_overview_tab_v2.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_posts_tab_v2.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_services_tab_v2.dart';
import 'package:BlueEra/features/me/automotive_service/view/v2/tabs/other_stats_tab_v2.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Other-business "me" profile home (v2) — redesigned to mirror the
/// layout used by `HospitalHomeScreenV2` while preserving every action
/// surfaced by the legacy `BusinessProfileFullScreen`. Standalone
/// screen — does NOT touch existing routes or `OthersMain`.
class OtherHomeScreenV2 extends StatefulWidget {
  const OtherHomeScreenV2({super.key});

  @override
  State<OtherHomeScreenV2> createState() => _OtherHomeScreenV2State();
}

class _OtherHomeScreenV2State extends State<OtherHomeScreenV2> {
  late final BusinessProfileFullController _otherController;
  final _businessController   = getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  bool _isGoLive = false;
  int _selectedTab = 0;

  // Tab labels resolved against AppStrings via .tr so the row stays in sync
  // with the user's selected locale. Not const because translations are
  // looked up at runtime.
  List<String> get _tabs => [
        AppStrings.inquiry.tr,
        AppStrings.overview.tr,
        AppStrings.services.tr,
        AppStrings.posts.tr,
        AppStrings.stats.tr,
      ];

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2`, `SchoolHomeScreenV2`,
  // `MedicalHomeScreenV2`, `LabHomeScreenV2` and the Order tab in
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
    _otherController = getOrPut(() => BusinessProfileFullController());
    if (_otherController.businessProfile.value == null) {
      _otherController.getBusinessProfileFull();
    }
    if (_businessController.businessProfileDetails.value?.data == null) {
      _businessController.viewBusinessProfile();
    }
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what the other v2 screens
    // (Hospital, School, Medical, Lab) and `professionals_main.dart` do.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // Register a back-press interceptor so the system back button collapses
    // the internal tabs to the first (Inquiry) tab before the bottom-nav
    // back routing runs — mirrors `MeTabBackHandlerMixin`, but this screen
    // uses a custom setState-driven tab switch (no TabController).
    if (Get.isRegistered<BottomBarController>()) {
      Get.find<BottomBarController>().meTabBackHandler = _onMeTabBack;
    }
  }

  /// Hops back to the first (Inquiry) tab when on any other tab, consuming
  /// the back press. Returns false when already on the first tab so the
  /// press falls through to the normal bottom-nav handling.
  bool _onMeTabBack() {
    if (!mounted) return false;
    if (_selectedTab != 0) {
      setState(() => _selectedTab = 0);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    if (Get.isRegistered<BottomBarController>()) {
      final bbc = Get.find<BottomBarController>();
      if (bbc.meTabBackHandler == _onMeTabBack) bbc.meTabBackHandler = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _otherController.getBusinessProfileFull,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: kBottomNavigationBarHeight + 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: SizeConfig.size10),
                          _buildTabsCard(),
                          SizedBox(height: SizeConfig.size12),
                          _buildTabContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return const OtherInquiryTabV2();
      case 1:
        return OtherOverviewTabV2(controller: _otherController);
      case 2:
        return const OtherServicesTabV2();
      case 3:
        return const OtherPostsTabV2();
      case 4:
        return const OtherStatsTabV2();
      default:
        return const SizedBox.shrink();
    }
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
          _circleIconButton(
              icon: Icons.notifications_none, onTap: _openNotifications),
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

  Widget _circleIconButton(
      {required IconData icon, required VoidCallback onTap}) {
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
            CustomText(AppStrings.goLive.tr,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    _isGoLive ? AppColors.primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: _isGoLive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
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



  Widget _buildTabsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        // padding: EdgeInsets.symmetric(
        //   horizontal: SizeConfig.size8,
        //   vertical: SizeConfig.size8,
        // ),
        //
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == _selectedTab;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: CustomText(
                      _tabs[i],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.mainTextColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

}


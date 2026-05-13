import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
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
import 'package:flutter/material.dart';

/// Hospital "me" profile home (v2) — redesigned to match the layout used by
/// `MedicalHomeScreenV2` while preserving every action surfaced by the
/// original `HospitalHomeScreen`.
class HospitalHomeScreenV2 extends StatefulWidget {
  const HospitalHomeScreenV2({super.key});

  @override
  State<HospitalHomeScreenV2> createState() => _HospitalHomeScreenV2State();
}

class _HospitalHomeScreenV2State extends State<HospitalHomeScreenV2> {
  late final HospitalServiceAiController _hospitalController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  bool _isGoLive = false;
  int _selectedTab = 0;

  static const _tabs = [
    'Inquiry',

    'Overview',
    'Departments',
    'Facilities',
    'Posts',
    'Stats',
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            Column(
              children: [
                _buildTopBar(),
                // _buildProfileRow(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _hospitalController
                          .getHospitalFullDetailsController();
                    },
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

  // ─────────────────────────────────────────────
  // TAB CONTENT — switches body by _selectedTab
  // ─────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return const HospitalInquiryTabV2();
      case 1:
        return HospitalOverviewTabV2(controller: _hospitalController);
      case 2:
        return HospitalDepartmentsTabV2(controller: _hospitalController);
      case 3:
        return HospitalFacilitiesTabV2(controller: _hospitalController);
      case 4:
        return const HospitalPostsTabV2();
      case 5:
        return const HospitalStatsTabV2();

      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────
  // BACKGROUND PATTERN
  // ─────────────────────────────────────────────
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
          SizedBox(width: SizeConfig.size8),
          if (!isBusinessUser()) _earnPill(),
          const Spacer(),
          _circleIconButton(
            icon: Icons.notifications_none,
            onTap: _openNotifications,
          ),
          SizedBox(width: SizeConfig.size8),
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

  Widget _earnPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoinStackIcon(size: 20),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            'Earn',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ],
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
              'Go live',
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
                color:
                    _isGoLive ? AppColors.primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment:
                    _isGoLive ? Alignment.centerRight : Alignment.centerLeft,
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
  Widget _buildTabsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(

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

  // ─────────────────────────────────────────────
  // PREVIEW AS VISITOR — opens the public discover preview so the owner
  // can see what other users see for this hospital.
  // ─────────────────────────────────────────────
}

/// Stacked-coin glyph used by the "Earn" pill in the gradient header.
class _CoinStackIcon extends StatelessWidget {
  final double size;
  const _CoinStackIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    final coinDiameter = size * 0.78;
    return SizedBox(
      width: size + 4,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _coin(coinDiameter, const Color(0xFFC9892B)),
          ),
          Positioned(
            left: 3,
            bottom: 4,
            child: _coin(coinDiameter, const Color(0xFFE0A53A)),
          ),
          Positioned(
            left: 6,
            bottom: 8,
            child: _coin(
              coinDiameter,
              const Color(0xFFF4C13B),
              child: const Text(
                '₹',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7A4A0A),
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coin(double diameter, Color color, {Widget? child}) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

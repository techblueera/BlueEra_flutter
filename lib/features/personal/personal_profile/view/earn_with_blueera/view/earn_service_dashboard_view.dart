import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_product_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_dashboard_header.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_selector.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_website_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Earn-service dashboard (v2) — same shell as self_employee_screen.dart:
/// floating glassmorphic top bar, custom animated-underline tabs card
/// with a sticky overlay, and a CustomScrollView body. Only two tabs:
///   • Home — embeds the matching earn-profile page (food / product /
///     service) with the website card appended when one is linked
///   • Statics — chat-click analytics
class EarnServiceDashboardView extends StatefulWidget {
  final bool fromBottomNavBar;

  const EarnServiceDashboardView({
    super.key,
    this.fromBottomNavBar = false,
  });

  @override
  State<EarnServiceDashboardView> createState() =>
      _EarnServiceDashboardViewState();
}

class _EarnServiceDashboardViewState extends State<EarnServiceDashboardView> {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();
  final _earnCtrl = getOrPut(() => EarnServiceController());
  final _selfWorkCtrl = getOrPut(() => SelfWorkServiceController());
  final _earnProfileCtrl = getOrPut(() => EarnProfileController());

  int _selectedTab = 0;
  bool _showStickyTabs = false;

  static const _tabs = ['Home', 'Statics'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _earnProfileCtrl.fetchEarnProfile();
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() ==
              AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis != Axis.vertical) return false;
                final shouldShow = n.metrics.pixels > topBarHeight;
                if (shouldShow != _showStickyTabs) {
                  setState(() => _showStickyTabs = shouldShow);
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    primary: false,
                    pinned: false,
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    toolbarHeight: topBarHeight,
                    flexibleSpace: _buildTopBar(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: _buildTabsCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: SizeConfig.size10,
                        bottom: kBottomNavigationBarHeight + 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildTabContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showStickyTabs)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: EdgeInsets.only(top: topInset + 10, bottom: 10),
                      decoration: const BoxDecoration(
                        color: Color(0x66FFFFFF),
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x42001120),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                            blurStyle: BlurStyle.outer,
                          ),
                        ],
                      ),
                      child: _buildTabsCard(),
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
  // BACKGROUND
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
  // TOP BAR — glassmorphic strip:
  //   [drawer] [profile selector]   …   [bell] [Go Live]
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
                _circleIconButton(
                  icon: Icons.menu,
                  onTap: () => _openDrawer(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: _buildEarnSlot()),
                SizedBox(width: SizeConfig.size8),
                if (!isGuestUser()) ...[
                  _circleIconButton(
                    icon: Icons.notifications_none,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteHelper.getNotificationScreenRoute(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                ],
                _goLivePill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarnSlot() {
    return Obx(() {
      final earnType = _viewCtrl.earnProfileType.value;
      final hasEarnProfile = earnType != null && earnType.isNotEmpty;
      if (!hasEarnProfile) return const SizedBox.shrink();
      final image =
          _viewCtrl.personalProfileDetails.value.user?.profileImage ?? '';
      return EarnServiceProfileSelector(
        profileImages: [image, image],
        profileNames: [
          'Skill Work',
          _earnCtrl.earnProfileLabel(earnType),
        ],
        selectedIndex: _selfWorkCtrl.selectedProfileIndex.value,
        onProfileSelected: (index) => _selfWorkCtrl.switchProfile(index),
        onCoverOverlay: false,
      );
    });
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
    return Obx(() {
      final isOn = _viewCtrl.shopStatusOpenClose.value;
      final isUpdating = _viewCtrl.isShopStatusUpdating.value;
      return GestureDetector(
        onTap: isUpdating ? null : () => _viewCtrl.toggleShopStatus(),
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
                    horizontal: SizeConfig.size10,
                    vertical: SizeConfig.size6),
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
                    CustomText('Go live',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor),
                    SizedBox(width: SizeConfig.size6),
                    if (isUpdating)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor),
                        ),
                      )
                    else
                      Container(
                        width: 30,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              isOn ? AppColors.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.secondaryTextColor
                                .withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 180),
                          alignment: isOn
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            height: 14,
                            width: 14,
                            decoration: BoxDecoration(
                              color: isOn
                                  ? Colors.white
                                  : AppColors.secondaryTextColor,
                              shape: BoxShape.circle,
                            ),
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
    });
  }

  void _openDrawer(BuildContext context) {
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

  // ─────────────────────────────────────────────
  // TABS — solid white card with an animated underline that slides
  // beneath the selected tab. Same style as self_employee_screen.dart.
  // ─────────────────────────────────────────────
  Widget _buildTabsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A001120),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / _tabs.length;
            const indicatorWidth = 28.0;
            final indicatorLeft =
                tabWidth * _selectedTab + (tabWidth - indicatorWidth) / 2;
            return Stack(
              children: [
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _selectedTab == i;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedTab = i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                              color: selected
                                  ? AppColors.primaryColor
                                  : AppColors.mainTextColor,
                            ),
                            child: Text(_tabs[i]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  bottom: 6,
                  child: Container(
                    width: indicatorWidth,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT — switches body by _selectedTab.
  //   0 Home, 1 Statics
  // ─────────────────────────────────────────────
  List<Widget> _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildStaticsTab();
      default:
        return const [SizedBox.shrink()];
    }
  }

  // Home tab — dashboard header (cover/profile) + the matching earn-
  // profile page unchanged + website card when one is linked.
  List<Widget> _buildHomeTab() {
    return [
      Obx(() {
        final earnType = _viewCtrl.earnProfileType.value;
        final website = _earnProfileCtrl.earnProfile.value?.website ?? '';
        final hasWebsite = website.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EarnServiceDashboardHeader(
              controller: _earnProfileCtrl,
              headerOverlay: const SizedBox.shrink(),
            ),
            _earnHomeBody(earnType),
            if (hasWebsite)
              EarnServiceWebsiteCard(
                controller: _earnProfileCtrl,
                webViewHeight: MediaQuery.of(context).size.height * 0.7,
              ),
          ],
        );
      }),
    ];
  }

  Widget _earnHomeBody(String? earnType) {
    switch (earnType) {
      case 'homeMadeFood':
        return const HomeMadeFoodHomePage();
      case 'homeMadeProduct':
        return const HomeMadeProductHomePage();
      case 'homeService':
        return const HomeServiceHomePage();
      default:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
          child: Center(
            child: CustomText(
              AppStrings.comingSoon,
              fontSize: SizeConfig.large,
              color: AppColors.secondaryTextColor,
            ),
          ),
        );
    }
  }

  // Statics tab — chat-click analytics, same as grocery / medical /
  // self-employee dashboards' last tab.
  List<Widget> _buildStaticsTab() {
    return [
      MedicalStatisticsScreen(businessId: userId),
    ];
  }
}

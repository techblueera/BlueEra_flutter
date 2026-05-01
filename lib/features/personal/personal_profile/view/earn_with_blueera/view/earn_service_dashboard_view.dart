import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_product_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_dashboard_header.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_selector.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_website_card.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

class _EarnServiceDashboardViewState extends State<EarnServiceDashboardView>
    with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => EarnServiceController());
  final selfWorkController = getOrPut(() => SelfWorkServiceController());
  final earnProfileController = getOrPut(() => EarnProfileController());
  final viewPersonalDetailsController =   Get.find<ViewPersonalDetailsController>();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      earnProfileController.fetchEarnProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: EarnServiceDashboardHeader(
              controller: earnProfileController,
              headerOverlay: _buildGlassHeaderRow(context),
            ),
          ),
          SliverAppBar(
            pinned: true,
            floating: false,
            primary: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            collapsedHeight: 0,
            expandedHeight: 0,
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: AppStrings.home.tr),
                Tab(text: AppStrings.website.tr),
                Tab(text: AppStrings.statistics.tr),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHomeTab(),
            EarnServiceWebsiteCard(
              controller: earnProfileController,
              webViewHeight: MediaQuery.of(context).size.height,
            ),
            const SubscriptionStatusView(),
          ],
        ),
      ),
      ),
    );
  }

  // ─── Glassmorphic header row (drawer + selector + bell) ────────
  Widget _buildGlassHeaderRow(BuildContext context) {
    return Obx(() {
      final userImage = viewPersonalDetailsController
              .personalProfileDetails.value.user?.profileImage ??
          '';
      final earnType = viewPersonalDetailsController.earnProfileType.value;
      final hasEarnProfile = earnType != null && earnType.isNotEmpty;
      return Stack(
        children: [
          // Full-width dark glassmorphic backing strip — touches edges with
          // no border radius, mirrors the self-employee dashboard header.
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          // Individual dark glass pills sitting on top of the strip.
          // Right padding matches the trailing gap that Go Live has on the
          // self-employee strip (8px from the strip edge).
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _GlassPill(
                  onTap: () => _openDrawer(context),
                  padding: const EdgeInsets.all(8),
                  shape: BoxShape.circle,
                  child: LocalAssets(
                    imagePath: AppIconAssets.drawer_more,
                    width: 18,
                    height: 18,
                    imgColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasEarnProfile)
                  Flexible(
                    child: EarnServiceProfileSelector(
                      profileImages: [userImage, userImage],
                      profileNames: [
                        'Skill Work',
                        controller.earnProfileLabel(earnType),
                      ],
                      selectedIndex: 1,
                      onProfileSelected: (index) =>
                          selfWorkController.switchProfile(index),
                      onCoverOverlay: true,
                    ),
                  ),
                const Spacer(),
                if (!isGuestUser())
                  _GlassPill(
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteHelper.getNotificationScreenRoute(),
                    ),
                    padding: const EdgeInsets.all(8),
                    shape: BoxShape.circle,
                    child: LocalAssets(
                      imagePath: AppIconAssets.notificationOutlineIcon,
                      width: 18,
                      height: 18,
                      imgColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      context: context,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: Get.width * 0.85,
            height: double.infinity,
            child: Drawer(child: ProfileMenuDrawer()),
          ),
        );
      },
    );
  }

  // ─── Home Tab Body ─────────────────────────────────────────────
  Widget _buildHomeTab() {
    return Obx(() {
      final earnType = viewPersonalDetailsController.earnProfileType.value;
      switch (earnType) {
        case 'homeMadeFood':
          return const HomeMadeFoodHomePage();
        case 'homeMadeProduct':
          return const HomeMadeProductHomePage();
        case 'homeService':
          return const HomeServiceHomePage();
        default:
          return Center(
            child: CustomText(
              'Coming Soon',
              fontSize: SizeConfig.large,
              color: AppColors.secondaryTextColor,
            ),
          );
      }
    });
  }
}

/// Frosted-glass dark pill / circle used for cover-overlay buttons. Mirrors
/// the helper in self_employee_dashboard_view.dart so the two screens look
/// identical.
class _GlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final BoxShape shape;

  const _GlassPill({
    required this.child,
    required this.onTap,
    required this.padding,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        shape == BoxShape.circle ? null : BorderRadius.circular(100);
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: _GlassClipper(shape: shape, borderRadius: borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: borderRadius,
              shape: shape,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.6,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassClipper extends CustomClipper<Path> {
  final BoxShape shape;
  final BorderRadius? borderRadius;

  _GlassClipper({required this.shape, this.borderRadius});

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    if (shape == BoxShape.circle) {
      return Path()..addOval(rect);
    }
    return Path()
      ..addRRect((borderRadius ?? BorderRadius.circular(100)).toRRect(rect));
  }

  @override
  bool shouldReclip(covariant _GlassClipper oldClipper) =>
      oldClipper.shape != shape || oldClipper.borderRadius != borderRadius;
}

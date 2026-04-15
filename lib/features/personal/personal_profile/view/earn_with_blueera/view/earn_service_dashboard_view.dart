import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_product_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_home_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_selector.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_website_card.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
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
  final viewPersonalDetailsController =
      Get.find<ViewPersonalDetailsController>();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            _buildSliverHeader(),
            _buildSliverTabBar(),
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

  // ─── Sliver Header ─────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      expandedHeight: SizeConfig.size70,
      flexibleSpace: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
        child: Row(
          children: [
            if (!widget.fromBottomNavBar)
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                icon: LocalAssets(
                  imagePath: AppIconAssets.back_arrow,
                  height: SizeConfig.paddingL,
                  width: SizeConfig.paddingL,
                  imgColor: Colors.black,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: widget.fromBottomNavBar ? SizeConfig.size15 : 0,
              ),
              child: _buildProfileSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSelector() {
    return Obx(() {
      final userImage = viewPersonalDetailsController
              .personalProfileDetails.value.user?.profileImage ??
          '';
      final earnType = viewPersonalDetailsController.earnProfileType.value;
      final hasEarnProfile = earnType != null && earnType.isNotEmpty;

      if (!hasEarnProfile) {
        return CommonProfileAvatar();
      }

      return EarnServiceProfileSelector(
        profileImages: [userImage, userImage],
        profileNames: [
          'Skill Work',
          controller.earnProfileLabel(earnType),
        ],
        selectedIndex: 1,
        onProfileSelected: (index) =>
            selfWorkController.switchProfile(index),
        onAddTap: () => Get.to(() => const chooseEarnServiceScreen()),
      );
    });
  }

  // ─── Sliver Tab Bar (pinned) ───────────────────────────────────
  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: TabBarDelegate(
        TabBar(
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

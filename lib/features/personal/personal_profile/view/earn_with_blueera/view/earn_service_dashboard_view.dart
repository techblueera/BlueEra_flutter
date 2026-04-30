import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
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
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
      appBar: CommonBackAppBar(
        showElevation: 0,
        isDrawerMenu: true,
        isLeading: false,
        isProfile: false,
        isNotification: !isGuestUser(),
        bellIconNotEmpty: true,
        isGuestLogout: isGuestUser(),
        onNotificationTap: () {
          Navigator.pushNamed(
            context,
            RouteHelper.getNotificationScreenRoute(),
          );
        },
      ),
      body: SafeArea(
        child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: EarnServiceDashboardHeader(
              controller: earnProfileController,
              onBack: widget.fromBottomNavBar
                  ? null
                  : () => Navigator.of(context).pop(),
              profileSelector: _buildProfileSelector(),
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

  // ─── Profile Selector (Skill Work ⇄ Earn Service) ──────────────
  Widget _buildProfileSelector() {
    return Obx(() {
      final userImage = viewPersonalDetailsController
              .personalProfileDetails.value.user?.profileImage ??
          '';
      final earnType = viewPersonalDetailsController.earnProfileType.value;
      final hasEarnProfile = earnType != null && earnType.isNotEmpty;

      if (!hasEarnProfile) return const SizedBox.shrink();

      return EarnServiceProfileSelector(
        profileImages: [userImage, userImage],
        profileNames: [
          'Skill Work',
          controller.earnProfileLabel(earnType),
        ],
        selectedIndex: 1,
        onProfileSelected: (index) => selfWorkController.switchProfile(index),
        onCoverOverlay: true,
      );
    });
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

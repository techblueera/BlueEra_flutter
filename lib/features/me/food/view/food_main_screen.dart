import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_profile_header_view.dart';
import 'package:BlueEra/features/business/widgets/business_stats.dart';
import 'package:BlueEra/features/me/food/view/food_category_screen.dart';
import 'package:BlueEra/features/me/food/view/food_home_screen.dart';
import 'package:BlueEra/features/business/widgets/empty_website_tab.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodMainScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const FoodMainScreen({
    super.key, this.fromBottomNavBar
  });

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  List<Tab> get _tabs => [
        Tab(text: AppStrings.home.tr),
        Tab(text: AppStrings.website.tr),
        Tab(text: AppStrings.statistics.tr),
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    MeTabRegistry.register(_tabController);
  }

  @override
  void dispose() {
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Obx(() {
                final details = viewBusinessDetailsController
                    .businessProfileDetails.value?.data;
                return Stack(
                  children: [
                    BusinessProfileHeaderView(
                      details: details,
                      controller: viewBusinessDetailsController,
                    ),
                    Positioned(
                      left: SizeConfig.size10,
                      top: SizeConfig.size10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRiderButton(),
                          SizedBox(width: SizeConfig.size10),
                          _buildAddFoodButton(),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                final details = viewBusinessDetailsController
                    .businessProfileDetails.value?.data;
                return BusinessStats(details: details);
              }),
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
                unselectedLabelColor: AppColors.secondaryTextColor,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 2,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                tabs: _tabs,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              RestaurantHomeScreen(),
              const WebsiteTab(),
              const SubscriptionStatusView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderButton() {
    return InkWell(
      onTap: () {
        Get.toNamed(RouteHelper.getNearByRidersScreenRoute());
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: SizeConfig.size40,
            width: SizeConfig.size40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SizeConfig.size8),
              color: AppColors.white,
              border: Border.all(color: AppColors.greyE5),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(6.0),
            child: LocalAssets(
              imagePath: AppIconAssets.riderIcon,
              imgColor: AppColors.black,
            ),
          ),
          Positioned(
            top: -(SizeConfig.size6),
            right: -(SizeConfig.size6),
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size4),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 3.0,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.add,
                imgColor: AppColors.secondaryTextColor,
                width: SizeConfig.size12,
                height: SizeConfig.size12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFoodButton() {
    return InkWell(
      onTap: () => Get.to(() => FoodCategoryMenuScreen()),
      child: Container(
        height: SizeConfig.size40,
        width: SizeConfig.size40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SizeConfig.size8),
          color: AppColors.primaryColor,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(6.0),
        child: LocalAssets(imagePath: AppIconAssets.add),
      ),
    );
  }
}

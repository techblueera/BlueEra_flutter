import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/food/view/food_category_screen.dart';
import 'package:BlueEra/features/me/food/view/food_home_screen.dart';
import 'package:BlueEra/features/business/widgets/empty_website_tab.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
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
  final TextEditingController searchController = TextEditingController();

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
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      floating: true,
                      snap: true,
                      pinned: false,
                      automaticallyImplyLeading: false,
                      flexibleSpace: Padding(
                        padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                        child: _buildHeader(context),
                      ),
                      expandedHeight: SizeConfig.size70,
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primaryColor,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: Colors.blue,
                          indicatorWeight: 2,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                          tabs: _tabs,
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    RestaurantHomeScreen(),
                    const WebsiteTab(),
                    const SubscriptionStatusView(),
                  ],
                ),
              ),
        ));
  }

  Widget? _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (!(widget.fromBottomNavBar??false))
          IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: LocalAssets(
                imagePath: AppIconAssets.back_arrow,
                height: SizeConfig.paddingL,
                width: SizeConfig.paddingL,
                imgColor:  Colors.black,
              )),
        CommonProfileAvatar(),
        SizedBox(width: SizeConfig.size15),
        Expanded(
          child: CommonSearchBar(
            controller: searchController,
            onClearCallback: ()=> searchController.clear(),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.paddingXSL,
          ),
          child: InkWell(
            onTap:() {
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
                      border: Border.all(
                          color: AppColors.greyE5
                      ),
                      boxShadow: [AppShadows.textFieldShadow]
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
                              offset: Offset(0, 1.5)
                          )
                        ]
                    ),
                    child: LocalAssets(
                      imagePath: AppIconAssets.add,
                      imgColor: AppColors.secondaryTextColor,
                      width: SizeConfig.size12,
                      height: SizeConfig.size12,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.paddingXSL,
              right: SizeConfig.paddingL
          ),
          child: InkWell(
            onTap: ()=> Get.to(()=> FoodCategoryMenuScreen()),
            child: Container(
              height: SizeConfig.size40,
              width: SizeConfig.size40,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                  color: AppColors.primaryColor
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.all(6.0),
              child: LocalAssets(imagePath: AppIconAssets.add),
            ),
          ),
        ),
      ],
    );
  }

}

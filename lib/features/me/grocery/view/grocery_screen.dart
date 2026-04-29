import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_profile_header_view.dart';
import 'package:BlueEra/features/business/widgets/business_stats.dart';
import 'package:BlueEra/features/business/widgets/empty_website_tab.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/my_grocery_store_screen.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_orders/my_grocery_orders.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const GroceryScreen({super.key, this.fromBottomNavBar});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late List<Tab> _tabs;
  late List<Widget> _tabViews;

  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  void _initializeTabs() {
    _tabs = [
      // Tab(text: AppStrings.myOrder.tr),
      Tab(text: AppStrings.myStore.tr),
      Tab(text: AppStrings.website.tr),
      Tab(text: AppStrings.statistics.tr),
    ];

    _tabViews = [
      // MyGroceryOrders(),
      MyGroceryStoreScreen(),
      const WebsiteTab(),
      const SubscriptionStatusView(),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
    MeTabRegistry.register(_tabController!);
  }

  @override
  void dispose() {
    if (_tabController != null) MeTabRegistry.unregister(_tabController!);
    _tabController?.dispose();
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BottomNavHideOnScroll(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: SizedBox(
                height: kToolbarHeight,
                child: CommonBackAppBar(
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
                  buildCustomActionWidget: () => _AddActionPill(
                    label: AppStrings.addGrocery.tr,
                    onTap: () async {
                      final groceryController =
                          getOrPut(() => GroceryController());
                      await Get.toNamed(
                        RouteHelper.getGrocerySuperCategoryScreenRoute(),
                        arguments: {ApiKeys.argBulkUpload: true},
                      );
                      if (groceryController.groceryDataNeedsRefresh) {
                        groceryController.groceryDataNeedsRefresh = false;
                        groceryController.fetchAllGroceryData(userId,
                            otherStore: false);
                      }
                    },
                  ),
                ),
              ),
            ),
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
                      child: _buildRiderButton(),
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
            children: _tabViews,
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildRiderButton() {
    return _headerChip(
      onTap: () => Get.toNamed(RouteHelper.getNearByRidersScreenRoute()),
      leading: LocalAssets(
        imagePath: AppIconAssets.riderIcon,
        imgColor: AppColors.mainTextColor,
        width: SizeConfig.size16,
        height: SizeConfig.size16,
      ),
      label: 'Nearby Riders',
      isPrimary: false,
    );
  }

  Widget _headerChip({
    required VoidCallback onTap,
    required Widget leading,
    required String label,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size8,
          ),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primaryColor : AppColors.white,
            borderRadius: BorderRadius.circular(100),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.greyE5),
            boxShadow: [AppShadows.textFieldShadow],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              SizedBox(width: SizeConfig.size6),
              Text(
                label,
                style: TextStyle(
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? AppColors.white
                      : AppColors.mainTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddActionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

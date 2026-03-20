import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_orders.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/food_menu_management_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/tiffin_menu_management_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/self_profession_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/earn_service_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';

class EarnServiceDashboardView extends StatefulWidget {
  final bool fromBottomNavBar;
  const EarnServiceDashboardView({super.key, required this.fromBottomNavBar});

  @override
  State<EarnServiceDashboardView> createState() => _EarnServiceDashboardViewState();
}

class _EarnServiceDashboardViewState extends State<EarnServiceDashboardView>
    with SingleTickerProviderStateMixin {

  final controller = getOrPut(() => EarnServiceController());
  final viewPersonalDetailsController = Get.find<ViewPersonalDetailsController>();
  late TabController _tabController;

  final RxBool _isFabVisible = true.obs;
  final ScrollController _nestedScrollController = ScrollController();
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    // Initialize exactly 3 tabs here
    _tabController = TabController(length: 3, vsync: this);
    controller.fetchOwnProducts();
    _nestedScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_)=> syncShopStatus());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nestedScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _nestedScrollController.offset;

    if (currentOffset > _lastScrollOffset && currentOffset > 60) {
      // Scrolling DOWN — hide FAB
      if (_isFabVisible.value) _isFabVisible.value = false;
    } else if (currentOffset < _lastScrollOffset) {
      // Scrolling UP — show FAB
      if (!_isFabVisible.value) _isFabVisible.value = true;
    }

    _lastScrollOffset = currentOffset;
  }


  void _openEarnWithBlueEraSheet(){
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EarnServiceBottomSheet(),
    );
  }

  void syncShopStatus() {
    final statusData = serviceProviderStatusGlobal.toUpperCase();
    viewPersonalDetailsController.shopStatusOpenClose.value =
        statusData == AppConstants.OPEN.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFAB(), // Move your FAB method here
      body: SafeArea(
        child: NestedScrollView(
          controller: _nestedScrollController,
          headerSliverBuilder: (_, __) => [
            _buildFloatingHeader(context),
            _buildPinnedTabBar(),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              EarnServiceOrders(),
              _buildMyProductsStore(),
              RentalServiceScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Obx(() => AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: _isFabVisible.value ? Offset.zero : const Offset(0, 2.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isFabVisible.value ? 1.0 : 0.0,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.fromBottomNavBar
                ? kBottomNavigationBarHeight + SizeConfig.size20
                : 0,
          ),
          child: GestureDetector(
            onTap: _openEarnWithBlueEraSheet,
            child: Container(
              height: SizeConfig.size50,
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24, height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  const CustomText(
                    'Add Service',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildFloatingHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      expandedHeight: SizeConfig.size70,
      flexibleSpace: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
        child: _buildHeader(context),
      ),
    );
  }

  Widget _buildPinnedTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppStrings.myOrder.tr),
            Tab(text: AppStrings.myProducts.tr),
            Tab(text: AppStrings.rentalServices.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProductsStore() {
    return Obx(()=> Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size8,
              right: SizeConfig.size8,
              top: SizeConfig.size15,
          ),
          child: HorizontalTabSelector(
            tabs: controller.productsServicesTab,
            selectedIndex: controller.selectedProductsServicesTabIndex.value,
            horizontalMargin: 0.0,
            onTabSelected: (index, value) {
              onMyProductsTabChanged(index);
            },
            labelBuilder: (label) => label,
            unSelectedBackgroundColor: AppColors.white,
          ),
        ),
        Expanded(
            child: _buildMyProductsTab()
        )
      ],
    )
    );
  }

  void onMyProductsTabChanged(int index) async {
    controller.selectedProductsServicesTabIndex.value = index;

    switch (index) {
      case 0: // Tiffin
       // EarnTiffinScreen();
        break;

      case 1: // Food
        break;

      case 2: // Product
      // if (earnWithBlueEraController.ownProductDataList.isEmpty) {
        await controller.fetchOwnProducts();
        // }
        break;
    }
  }

  Widget _buildMyProductsTab() {
    return Obx(() {
      final selectedTab = controller.selectedProductsServicesTabIndex.value;

      Widget tabContent;

      switch (selectedTab) {
        case 0:
          tabContent = TiffinMenuManagementScreen();
          break;

      // case 1:
      //   tabContent = Center(
      //     child: CustomText(
      //         AppStrings.comingSoon
      //     ),
      //   );
      //   break;



        case 1:
          tabContent = FoodMenuManagementScreen();

          // tabContent = FoodAndGroceryScreen(
          //   providerType: ProviderType.user,
          //   serviceSubType: EarnServiceTypes.homeMadeFood,
          // );
          break;

        case 2:
          final productList = controller.ownProductDataList;

          if (controller.isOwnProductDataFirstLoading.value) {
            tabContent = const Center(
              child: CircularProgressIndicator(),
            );
            break;
          }

          if (productList.isEmpty) {
            tabContent = EmptyStateWidget(message: AppStrings.noProductFound);
            break;
          }

          tabContent = Column(
            children: [
              Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = 2;
                      final crossSpacing = 10.0;
                      final mainSpacing = 10.0;


                      final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
                      final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

                      final approximateItemHeight = SizeConfig.size240;

                      final childAspectRatio = itemWidth / approximateItemHeight;


                      return GridView.builder(
                        itemCount: productList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: crossSpacing,
                          mainAxisSpacing: mainSpacing,
                          childAspectRatio: childAspectRatio,
                        ),
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight + 40,
                          left: SizeConfig.size8,
                          right: SizeConfig.size8,
                          top: SizeConfig.size8,
                        ),
                        itemBuilder: (context, index) {
                          final productData = productList[index];
                          return OwnProductCard(
                              deleteProductApi: (){
                                // earnWithBlueEraController.deleteProduct();
                              },
                              width: itemWidth,
                              product: productData,
                              isGridShow: true
                          );
                        },
                      );
                    },
                  )

                // ListView.builder(
                //   physics: const AlwaysScrollableScrollPhysics(),
                //   shrinkWrap: true,
                //   itemCount: productList.length,
                //   padding: EdgeInsets.only(
                //     bottom: kBottomNavigationBarHeight + SizeConfig.paddingL
                //   ),
                //   itemBuilder: (context, index) {
                //     final productData = productList[index];
                //
                //     return Padding(
                //       padding: EdgeInsets.only(
                //           bottom: SizeConfig.size8,
                //           left: SizeConfig.size8,
                //           right: SizeConfig.size8
                //       ),
                //       child: OwnProductCard(
                //         product: productData,
                //         isGridShow: true,
                //         deleteProductApi: (){
                //           // earnWithBlueEraController.deleteProduct();
                //         },
                //       ),
                //     );
                //   },
                // ),
              ),

              if (controller.isOwnProductDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;


      // case 4:
      //   tabContent = ViewServiceList(
      //     providerType: ProductServiceProviderType.user,
      //     serviceSubType: EarnWithBlueEraServiceTypes.homeService,
      //   );
      //   break;
      //
      //
      // case 5:
      //   tabContent = RentalServiceScreen();
      //   break;
      //
      // // case 6:
      // //   tabContent = ViewServiceList(
      // //     providerType: ProductServiceProviderType.user,
      // //     serviceSubType: EarnWithBlueEraServiceTypes.consultingService,
      // //   );
      // //   break;
      // //
      // // case 7:
      // //   tabContent = ViewServiceList(
      // //     providerType: ProductServiceProviderType.user,
      // //     serviceSubType: EarnWithBlueEraServiceTypes.tuitionService,
      // //   );
      // //   break;

        default:
          tabContent = const SizedBox.shrink();
      }

      return tabContent;
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. leading (back-arrow) – only if NOT from bottom-nav
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

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              CommonProfileAvatar(),
              SizedBox(width: SizeConfig.size15),
              InkWell(
                onTap: ()=> Get.to(()=> ProfessionDetailsScreen()),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: SizeConfig.paddingXSL,
                    bottom: SizeConfig.paddingXSL,
                  ),
                  child: CustomText(
                    userDesignationGlobal,
                    fontSize: SizeConfig.large,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: EdgeInsets.only(
            left: SizeConfig.size10,
          ),
          height: SizeConfig.size40,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(width: SizeConfig.paddingXSL),
              CustomText(
                AppStrings.goLive,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              buildToggleSwitchChip(
                value: viewPersonalDetailsController.shopStatusOpenClose,
                onChanged: viewPersonalDetailsController.toggleShopStatus,
              ),
            ],
          ),
        ),

        // SizedBox(width: SizeConfig.paddingXSL),

        IconButton(
            onPressed: () async => await Get.toNamed(
                RouteHelper.getAvailabilityScreenRoute(),
                arguments: {
                  ApiKeys.argId: userId,
                }),
            icon: LocalAssets(imagePath: AppIconAssets.clockIcon)
        ),

        SizedBox(width: SizeConfig.paddingXSL),
      ],
    );
  }

}
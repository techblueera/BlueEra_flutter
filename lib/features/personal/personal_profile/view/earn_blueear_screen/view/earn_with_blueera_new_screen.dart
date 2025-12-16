import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/controller/earn_with_blueera_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_service_orders.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/common/food/view/food_and_grocery_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/earn_with_blue_era_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum EarnWithBlueEraServiceTypes {
  selfWork('selfWork'),
  homeService('homeService'),
  homeMadeFood('homeMadeFood');

  final String label;
  const EarnWithBlueEraServiceTypes(this.label);

  static EarnWithBlueEraServiceTypes? fromLabel(String value) {
    return EarnWithBlueEraServiceTypes.values.firstWhere(
          (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => EarnWithBlueEraServiceTypes.selfWork, // default if not matched
    );
  }

  static List<String> get labels =>
      EarnWithBlueEraServiceTypes.values.map((e) => e.label).toList();
}


class EarnWithBlueEraNewScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const EarnWithBlueEraNewScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<EarnWithBlueEraNewScreen> createState() => _EarnWithBlueEraNewScreenState();
}

class _EarnWithBlueEraNewScreenState extends State<EarnWithBlueEraNewScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  // final foodUploadController = Get.put(FoodUploadController());
  // final serviceController = Get.put(ServiceController());

  final earnWithBlueEraController = getOrPut(() => EarnWithBlueEraController());
  final inventoryController = getOrPut(() => InventoryController());
  final viewPersonalDetailsController = getOrPut(() => ViewPersonalDetailsController());
  late bool isLeading;

  @override
  void initState() {
    log('user designation global -- $userWorkTypeGlobal');
    isLeading = !widget.fromBottomNavBar;
    _tabController = TabController(length: 3, vsync: this);
    earnWithBlueEraController.fetchOwnProducts();
    _checkEarnServiceStatus();
    WidgetsBinding.instance.addPostFrameCallback((_)=> syncShopStatus());
    super.initState();
  }

  void syncShopStatus() {
    final statusData = serviceProviderStatusGlobal.toUpperCase();
    viewPersonalDetailsController.shopStatusOpenClose.value =
        statusData == AppConstants.OPEN.toUpperCase();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _checkEarnServiceStatus();
  }


  @override
  void dispose() {
    Get.delete<EarnWithBlueEraController>();
    _tabController.dispose();
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _checkEarnServiceStatus() async {
     await getEarnServiceOptData();
     earnWithBlueEraController.isEarnServiceOpt.value = isEarnServiceOpt;
     print('isEarnServiceOpt -- ${earnWithBlueEraController.isEarnServiceOpt.value}');
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if(earnWithBlueEraController.isEarnServiceOpt.value.toLowerCase() == 'true'){
         _openEarnWithBlueEraSheet();
       }
     });
  }

  void _openEarnWithBlueEraSheet(){
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => EarnWithBlueEraBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final earnValue = earnWithBlueEraController.isEarnServiceOpt.value;

      if (earnValue.isEmpty) {
        return _buildLoadingScaffold();
      }

      if (earnValue.toLowerCase() == 'true') {
        return _buildEarnEnabledScaffold(context);
      }

      return _buildEarnDisabledScaffold(context);
    });
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: isLeading,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEarnEnabledScaffold(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFAB(context),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            _buildFloatingHeader(context),
            _buildPinnedTabBar(),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              EarnServiceOrders(),
              _buildMyProductsStore(),
              RentalServiceScreen()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyProductsStore() {
    return Obx(()=> Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: HorizontalTabSelector(
            tabs: earnWithBlueEraController.productsServicesTab,
            selectedIndex: earnWithBlueEraController.selectedProductsServicesTabIndex.value,
            horizontalMargin: 0.0,
            onTabSelected: (index, value) {
              onMyProductsTabChanged(index);
            },
            labelBuilder: (label) => label,
            unSelectedBackgroundColor: AppColors.white,
          ),
        ),
        // SizedBox(height: SizeConfig.size8),
        Expanded(
            child: _buildMyProductsTab()
        )
      ],
     )
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.fromBottomNavBar
            ? kBottomNavigationBarHeight + SizeConfig.size20
            : 0,
      ),
      child: FloatingActionButton(
        onPressed: _openEarnWithBlueEraSheet,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.add, size: SizeConfig.size36),
      ),
    );
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
            Tab(text: AppStrings.myServices.tr),
            Tab(text: AppStrings.myProducts.tr),
            Tab(text: AppStrings.rentalServices.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnDisabledScaffold(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: isLeading,
        title: userProfessionGlobal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8,
          ),
          child: CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEarnHeader(),
                SizedBox(height: SizeConfig.size10),
                const HorizontalVideoPlayer(),
                SizedBox(height: SizeConfig.size20),
                _buildServiceGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarnHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(SizeConfig.size6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.primaryColor, width: 0.5),
          ),
          child: LocalAssets(
            width: SizeConfig.size22,
            height: SizeConfig.size22,
            imagePath: AppIconAssets.earnWithBlueEra,
            imgColor: AppColors.primaryColor,
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            AppStrings.earnWithBlueEra,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.6,
        crossAxisSpacing: 30,
        mainAxisSpacing: 20,
      ),
      itemCount: earnWithBlueEraServiceList.length,
      itemBuilder: (_, i) => CommonServiceCard(
        service: earnWithBlueEraServiceList[i],
        onTap: () => earnWithBlueEraController.handleServiceTap(
          context,
          earnWithBlueEraServiceList[i],
        ),
      ),
    );
  }

  void onMyProductsTabChanged(int index) async {
    earnWithBlueEraController.selectedProductsServicesTabIndex.value = index;

    switch (index) {
      case 0: // Tiffin

        break;

      case 1: // Product
        // if (earnWithBlueEraController.ownProductDataList.isEmpty) {
        await earnWithBlueEraController.fetchOwnProducts();
        // }
        break;

      case 2: // Food
        break;
    }
  }

  Widget _buildMyProductsTab() {
    return Obx(() {
      final selectedTab = earnWithBlueEraController.selectedProductsServicesTabIndex.value;

      Widget tabContent;

      switch (selectedTab) {
        case 0:
          tabContent = Center(
            child: CustomText(
                AppStrings.comingSoon
            ),
          );
          break;

        // case 1:
        //   tabContent = Center(
        //     child: CustomText(
        //         AppStrings.comingSoon
        //     ),
        //   );
        //   break;

        case 1:
          final productList = earnWithBlueEraController.ownProductDataList;

          if (earnWithBlueEraController.isOwnProductDataFirstLoading.value) {
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

              if (earnWithBlueEraController.isOwnProductDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;


        case 2:
          tabContent = FoodAndGroceryScreen(
             providerType: ProductServiceProviderType.user,
            serviceSubType: EarnWithBlueEraServiceTypes.homeMadeFood,
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
        if (isLeading)
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
          child: Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.paddingXSL,
              bottom: SizeConfig.paddingXSL,
              left: (isLeading == true) ? 0 : SizeConfig.size20,
            ),
            child: CustomText(
              userWorkTypeGlobal,
              fontSize: SizeConfig.large,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

           Container(
            margin: EdgeInsets.only(
              left: SizeConfig.size10,
              right: SizeConfig.size10,
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

        SizedBox(width: SizeConfig.paddingXSL),

        LocalAssets(imagePath: AppIconAssets.clockIcon),

        SizedBox(width: SizeConfig.paddingL),
      ],
    );
  }

}

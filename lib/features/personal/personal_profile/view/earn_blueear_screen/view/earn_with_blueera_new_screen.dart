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
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/controller/earn_with_blueera_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/common/food/view/food_and_grocery_screen.dart';
import 'package:BlueEra/features/common/service/view/view_service_list.dart';
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
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());
  final viewPersonalDetailsController = getOrPut(() => ViewPersonalDetailsController());

  @override
  void initState() {
    log('user designation global -- $userWorkTypeGlobal');
    _tabController = TabController(length: 3, vsync: this);
    earnWithBlueEraController.fetchOwnProducts();
    _checkRiderStatus();
    _checkRiderAndEarnServiceStatus();
    super.initState();
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
    _checkRiderStatus();
    _checkRiderAndEarnServiceStatus();
  }


  @override
  void dispose() {
    Get.delete<EarnWithBlueEraController>();
    _tabController.dispose();
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _checkRiderStatus(){
    /// check riding status
    if(userProfessionGlobal == SELF_EMPLOYED && userWorkTypeGlobal == DELIVERY_RIDER) {
      deliveryPartnerController.ridersOnboardingStatusRepoApi();
    }
  }

  Future<void> _checkRiderAndEarnServiceStatus() async {
     await getEarnServiceOptData();
     earnWithBlueEraController.isRiderServiceOpt.value = isRiderServiceOpt;
     earnWithBlueEraController.isEarnServiceOpt.value = isRiderServiceOpt;
     print('isRiderServiceUser -- ${earnWithBlueEraController.isRiderServiceOpt.value} '
         '|| isEarnServiceUser -- ${earnWithBlueEraController.isEarnServiceOpt.value}');
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if(earnWithBlueEraController.isRiderServiceOpt.value.toLowerCase() == 'true' ||
           earnWithBlueEraController.isEarnServiceOpt.value.toLowerCase() == 'true'){
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
    return Obx(()=> earnWithBlueEraController.isRiderServiceOpt.isEmpty &&
        earnWithBlueEraController.isEarnServiceOpt.isEmpty
          ? Scaffold(
        appBar: CommonBackAppBar(
          isLeading: !(widget.fromBottomNavBar),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      )
          : (earnWithBlueEraController.isRiderServiceOpt.value.toLowerCase() == 'true' ||
          earnWithBlueEraController.isEarnServiceOpt.value.toLowerCase() == 'true')
          ? Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + 50),
          child: CommonBackAppBar(
            isLeading: !(widget.fromBottomNavBar),
            isGoLive: true,
            isGoLiveWidget: () {
              if (accountTypeGlobal == AppConstants.individual) {
                final statusData = serviceProviderStatusGlobal.toUpperCase();
                if (statusData == AppConstants.OPEN.toUpperCase()) {
                  viewPersonalDetailsController.shopStatusOpenClose.value = true;
                } else {
                  viewPersonalDetailsController.shopStatusOpenClose.value = false;
                }
                return Container(
                  margin: EdgeInsets.only(left: SizeConfig.size10),
                  height: SizeConfig.size40,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: SizeConfig.size10,
                      ),
                      CustomText(
                        "Go Live",
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      buildToggleSwitchChip(
                        value: viewPersonalDetailsController.shopStatusOpenClose,
                        onChanged: viewPersonalDetailsController.toggleShopStatus,
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
            bottomWidget: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue,
              indicatorWeight: 2,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: AppStrings.myOrder.tr),
                Tab(text: AppStrings.myStore.tr),
                Tab(text: AppStrings.businessCards.tr),
              ],
            ),
          ),
        ),
        floatingActionButton: Builder(builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: widget.fromBottomNavBar
                    ? kBottomNavigationBarHeight + SizeConfig.size20
                    : 0.0
            ),
            child: FloatingActionButton(
              onPressed: () => _openEarnWithBlueEraSheet(),
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add,
                size: SizeConfig.size36,
              ),
            ),
          );
        }),
        body: SafeArea(
          child: TabBarView(
              controller: _tabController,
              children: [
                _buildOwnUserOrders(),
                _buildEarnWithBlueEraStore(),
                SizedBox(
                  child: CustomText(
                      AppStrings.comingSoon
                  ),
                ),
              ]),
        ),
      )
          : Scaffold(
        appBar: CommonBackAppBar(
          isLeading: !(widget.fromBottomNavBar),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size15,
                horizontal: SizeConfig.size8
            ),
            child: CustomFormCard(
             padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      Expanded(child:
                      CustomText(
                        AppStrings.earnWithBlueEra,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                       )
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),
                  HorizontalVideoPlayer(),
                  SizedBox(height: SizeConfig.size20),
                  GridView.builder(
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
                      onTap: () => earnWithBlueEraController.handleServiceTap(context, earnWithBlueEraServiceList[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
  }

  Widget _buildEarnWithBlueEraStore() {
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
              onEarnServiceTabChanged(index);
            },
            labelBuilder: (label) => label,
          ),
        ),
        // SizedBox(height: SizeConfig.size8),
        Expanded(
            child: _buildEarnWithBlueEraStoreTab()
        )
      ],
     )
    );
  }

  Widget _buildOwnUserOrders(){
    return DeliveryPartnerOrders();
  }

  void onEarnServiceTabChanged(int index) async {
    earnWithBlueEraController.selectedProductsServicesTabIndex.value = index;

    switch (index) {
      case 0: // Self Work

        break;

      case 1: // Delivery Partner
        break;

      case 2: // Product
        // if (earnWithBlueEraController.ownProductDataList.isEmpty) {
        await earnWithBlueEraController.fetchOwnProducts();
        // }
        break;

      case 3: // Food
        break;

      case 4: // Home Services
        break;

      case 5: // Rental Services
        break;

    }
  }

  Widget _buildEarnWithBlueEraStoreTab() {
    return Obx(() {
      final selectedTab = earnWithBlueEraController.selectedProductsServicesTabIndex.value;

      Widget tabContent;

      switch (selectedTab) {
        case 0:
          tabContent = ViewServiceList(
            providerType: ProductServiceProviderType.user,
            serviceSubType: EarnWithBlueEraServiceTypes.selfWork,
          );
          break;

        case 1:
          tabContent = Center(
            child: CustomText(
                AppStrings.comingSoon
            ),
          );
          break;

        case 2:
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
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final productData = productList[index];

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: SizeConfig.size8,
                          left: SizeConfig.size8,
                          right: SizeConfig.size8
                      ),
                      child: OwnProductCard(
                        product: productData,
                        isGridShow: false,
                        deleteProductApi: (){
                          // earnWithBlueEraController.deleteProduct();
                        },
                      ),
                    );
                  },
                ),
              ),

              if (earnWithBlueEraController.isOwnProductDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
          break;


        case 3:
          tabContent = FoodAndGroceryScreen(
             providerType: ProductServiceProviderType.user,
            serviceSubType: EarnWithBlueEraServiceTypes.homeMadeFood,
          );
          break;

        case 4:
          tabContent = ViewServiceList(
            providerType: ProductServiceProviderType.user,
            serviceSubType: EarnWithBlueEraServiceTypes.homeService,
          );
          break;


        case 5:
          tabContent = RentalServiceScreen();
          break;

        // case 6:
        //   tabContent = ViewServiceList(
        //     providerType: ProductServiceProviderType.user,
        //     serviceSubType: EarnWithBlueEraServiceTypes.consultingService,
        //   );
        //   break;
        //
        // case 7:
        //   tabContent = ViewServiceList(
        //     providerType: ProductServiceProviderType.user,
        //     serviceSubType: EarnWithBlueEraServiceTypes.tuitionService,
        //   );
        //   break;

        default:
          tabContent = const SizedBox.shrink();
      }

      return tabContent;
    });
  }

}

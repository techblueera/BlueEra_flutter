import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/controller/earn_with_blueera_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/foodandgrocery/food_and_grocery_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/view_service_list.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/earn_with_blue_era_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum EarnWithBlueEraServiceTypes {
  homeMadeFood('homeMadeFood'),
  businessFood('businessFood'),
  businessService('businessService'),
  tuitionService('tuitionService'),
  consultingService('consultingService'),
  selfWork('selfWork'),
  homeService('homeService');

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
  const EarnWithBlueEraNewScreen({super.key});

  @override
  State<EarnWithBlueEraNewScreen> createState() => _EarnWithBlueEraNewScreenState();
}

class _EarnWithBlueEraNewScreenState extends State<EarnWithBlueEraNewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final earnWithBlueEraController = Get.put(EarnWithBlueEraController());
  final inventoryController = Get.put(InventoryController());
  // final foodUploadController = Get.put(FoodUploadController());
  // final serviceController = Get.put(ServiceController());
  final deliveryPartnerController = Get.put(DeliveryPartnerController());

  @override
  void initState() {
    // if(Get.isRegistered<InventoryController>()){
    //   inventoryController = Get.find<InventoryController>();
    // } else {
    //   inventoryController = Get.put(InventoryController());
    // }
    _tabController = TabController(length: 3, vsync: this);
    earnWithBlueEraController.fetchOwnProducts();

    /// check riding status
    deliveryPartnerController.ridersOnboardingStatusRepoApi();
    WidgetsBinding.instance.addPostFrameCallback((_)=> _openEarnWithBlueEraSheet());
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<EarnWithBlueEraController>();
    _tabController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: CommonBackAppBar(
          showGoLiveWidget: Container(
            margin: EdgeInsets.only(right: SizeConfig.size20),
            padding: EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppColors.primaryColor
              )
            ),
            child: Row(
              children: [
                CustomText(
                  'Go Live',
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.large,
                  color: AppColors.primaryColor
                ),
                SizedBox(width: SizeConfig.size5),
                Obx(()=> CustomSwitch(
                  value: earnWithBlueEraController.showGoLiveEnabled.value,
                  onChanged: (val) {
                    earnWithBlueEraController.showGoLiveEnabled.value = !earnWithBlueEraController.showGoLiveEnabled.value;
                  },
                  containerHeight: SizeConfig.size24,
                  containerWidth: SizeConfig.size50,
                  circleSize: SizeConfig.size18,
                )),
              ],
            ),
          ),
          bottomWidget: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'My Order'),
              Tab(text: 'My Store'),
              Tab(text: 'Business Cards'),
            ],
          ),
        ),
      ),
      floatingActionButton: Builder(builder: (context) {
        return FloatingActionButton(
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
        );
      }),
     body: TabBarView(
         controller: _tabController,
         children: [
           _buildOwnUserOrders(),
           _buildEarnWithBlueEraStore(),
           SizedBox(
             child: CustomText(
                 'Coming soon.'
             ),
           ),
         ]),
    );
  }

  Widget _buildEarnWithBlueEraStore() {
    return Obx(()=> Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size15),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: HorizontalTabSelector(
            tabs: earnWithBlueEraController.productsServicesTab,
            selectedIndex: earnWithBlueEraController.selectedProductsServicesTabIndex.value,
            horizontalMargin: 0.0,
            onTabSelected: (index, value) {
              onProductsServicesTabChanged(index);
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

  void onProductsServicesTabChanged(int index) async {
    earnWithBlueEraController.selectedProductsServicesTabIndex.value = index;

    switch (index) {
      case 0: // Product
        // if (earnWithBlueEraController.ownProductDataList.isEmpty) {
          await earnWithBlueEraController.fetchOwnProducts();
        // }
        break;

      case 1: // Food
        break;

      case 2: // Service
        break;

      case 3: // rental Service
        // if (foodDataList.isEmpty) {
        //   await getAllFoodService();
        // }
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
                'Coming Soon..'
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
            tabContent = EmptyStateWidget(message: 'No product found');
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
          tabContent = Center(
            child: CustomText(
                'Coming Soon..'
            ),
          );
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

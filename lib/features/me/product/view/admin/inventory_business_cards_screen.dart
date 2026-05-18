import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/business_all_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart' show CommonBackAppBar;
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/common/service/view/business_all_service_card.dart';
import 'package:BlueEra/features/common/food/view/business_all_food_service_card.dart';

class InventoryBusinessCardsScreen extends StatefulWidget {
  final bool showBackAppBar;
  const InventoryBusinessCardsScreen({super.key, this.showBackAppBar = true});

  @override
  State<InventoryBusinessCardsScreen> createState() =>
      _InventoryBusinessCardsScreenState();
}

class _InventoryBusinessCardsScreenState extends State<InventoryBusinessCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final inventoryController = getOrPut(() => InventoryController());
  final serviceController = getOrPut(() => ServiceController());
  final foodUploadController = getOrPut(() => FoodUploadController());

  late List<Tab> _tabs = [];
  late List<String> _tabTypes = [];

  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  Future<void> _initializeTabs()  async {
    final business = businessTypeGlobal.toLowerCase();

    _tabs = [];
    _tabTypes = [];

    if (isShowProduct.contains(business)) {
      _tabs.add(Tab(text: AppStrings.myProducts.tr));
      _tabTypes.add(AppConstants.product);
    }
    if (isShowService.contains(business)) {
      _tabs.add(Tab(text: AppStrings.myServices.tr));
      _tabTypes.add(AppConstants.service);
    }
    if (isShowFood.contains(business)) {
      _tabs.add(Tab(text: AppStrings.foodAndGrocery.tr));
      _tabTypes.add(AppConstants.food);
    }

    if (_tabs.isEmpty) {
      debugPrint(" ${AppStrings.noMatchingTabsFound.tr} $business");
      setState(() => _isLoading = false);
      return;
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Fetch data for the first tab only
    await _fetchTabData(_tabTypes.first);

    if (mounted) setState(() => _isLoading = false);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    inventoryController.businessCardsSelectedIndex.value = _tabController.index;
    final currentType = _tabTypes[_tabController.index];
    _fetchTabData(currentType);
  }

  Future<void> _fetchTabData(String type) async {
    switch (type) {
      case AppConstants.product:
        if (inventoryController.allProducts.isEmpty) {
          inventoryController.fetchBusinessProducts();
        }
        break;

      case AppConstants.service:
        if (serviceController.serviceDataList.isEmpty) {
          final queryParams = {
            ApiKeys.all: false,
            ApiKeys.type: AppConstants.service,
            ApiKeys.providerType: ProviderType.business.title,
          };
          serviceController.getServices(queryParams);
        }
        break;

      case AppConstants.food:
        if (foodUploadController.foodDataList.isEmpty) {
          final queryParams = {
            ApiKeys.all: false,
            ApiKeys.type: AppConstants.food,
            ApiKeys.providerType: ProviderType.business.title,
          };
          foodUploadController.getFoodService(queryParams);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar:  widget.showBackAppBar ? PreferredSize(
        preferredSize: Size.fromHeight(widget.showBackAppBar
            ? kToolbarHeight + 50
            : 50
        ),
        child: CommonBackAppBar(
          isLeading: widget.showBackAppBar ? true : null,
          title: widget.showBackAppBar ? AppStrings.myBusinessCards : null,
          bottomWidget: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: _tabs,
          ),
        ),
      ) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(()=> Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              top: SizeConfig.size15,
            ),
            child: HorizontalTabSelector(
              tabs:  _tabs.map((t) => t.text ?? "").toList(),
              selectedIndex:   inventoryController.businessCardsSelectedIndex.value,
              horizontalMargin: 0.0,
              onTabSelected: (index, value) {
                inventoryController.businessCardsSelectedIndex.value = index;
                _tabController.animateTo(index);
              },
              labelBuilder: (label) => label,
            ),
          )),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) {
                final type = _tabTypes[index];
                switch (type) {
                  case AppConstants.product:
                    return Obx(() {
                      if (inventoryController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (inventoryController.allProducts.isEmpty) {
                        return const Center(child: CustomText(AppStrings.noProductsFound));
                      }
                      return BusinessAllProductCard(
                        allProducts: inventoryController.allProducts,
                      );
                    });

                  case AppConstants.service:
                    return Obx(() {
                      if (serviceController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (serviceController.serviceDataList.isEmpty) {
                        return const Center(child: CustomText(AppStrings.noServicesFound));
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                        child: BusinessAllServiceCard(
                            allServices: serviceController.serviceDataList),
                      );
                    });

                  case AppConstants.food:
                    return Obx(() {
                      if (foodUploadController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (foodUploadController.foodDataList.isEmpty) {
                        return const Center(child: CustomText(AppStrings.noFoodItemsFound));
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                        child: BusinessAllFoodServiceCard(
                            allFoodServices: foodUploadController.foodDataList),
                      );
                    });

                  default:
                    return const SizedBox.shrink();
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}

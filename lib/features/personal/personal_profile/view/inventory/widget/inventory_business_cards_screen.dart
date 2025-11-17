import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart' show CommonBackAppBar;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/business_service/controller/service_controller.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/business_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/business_service_card.dart';
import 'package:BlueEra/features/common/food/view/business_food_service_card.dart';

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
  final inventoryController = Get.put(InventoryController());
  final serviceController = Get.put(ServiceController());
  final foodUploadController = Get.put(FoodUploadController());

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
      _tabs.add(const Tab(text: 'My Products'));
      _tabTypes.add('product');
    }
    if (isShowService.contains(business)) {
      _tabs.add(const Tab(text: 'My Services'));
      _tabTypes.add('service');
    }
    if (isShowFood.contains(business)) {
      _tabs.add(const Tab(text: 'Food & Grocery'));
      _tabTypes.add('food');
    }

    if (_tabs.isEmpty) {
      debugPrint(" No matching tabs found for businessType: $business");
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
    final currentType = _tabTypes[_tabController.index];
    _fetchTabData(currentType);
  }

  Future<void> _fetchTabData(String type) async {
    switch (type) {
      case 'product':
        if (inventoryController.allProducts.isEmpty) {
          inventoryController.fetchProducts();
        }
        break;

      case 'service':
        if (serviceController.serviceDataList.isEmpty) {
          final queryParams = {
            ApiKeys.all: false,
            ApiKeys.type: "service",
            ApiKeys.providerType: ProductServiceProviderType.business.title,
          };
          serviceController.getServices(queryParams);
        }
        break;

      case 'food':
        if (foodUploadController.foodDataList.isEmpty) {
          final queryParams = {
            ApiKeys.all: false,
            ApiKeys.type: "food",
            ApiKeys.providerType: ProductServiceProviderType.business.title,
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
      backgroundColor: AppColors.whiteF3,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(widget.showBackAppBar
            ? kToolbarHeight + 50
            : 50
        ),
        child: CommonBackAppBar(
          isLeading: widget.showBackAppBar ? true : null,
          title: widget.showBackAppBar ? 'My Business Cards' : null,
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) {
          final type = _tabTypes[index];
          switch (type) {
            case 'product':
              return Obx(() {
                if (inventoryController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (inventoryController.allProducts.isEmpty) {
                  return const Center(child: Text('No products found'));
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                  child: BusinessProductCard(
                    allProducts: inventoryController.allProducts,
                    showHorizontal: false,
                  ),
                );
              });

            case 'service':
              return Obx(() {
                if (serviceController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (serviceController.serviceDataList.isEmpty) {
                  return const Center(child: Text('No services found'));
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                  child: BusinessServiceCard(
                      allServices: serviceController.serviceDataList),
                );
              });

            case 'food':
              return Obx(() {
                if (foodUploadController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (foodUploadController.foodDataList.isEmpty) {
                  return const Center(child: Text('No food items found'));
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                  child: BusinessFoodServiceCard(
                      allFoodServices: foodUploadController.foodDataList),
                );
              });

            default:
              return const SizedBox.shrink();
          }
        }),
      ),
    );
  }
}

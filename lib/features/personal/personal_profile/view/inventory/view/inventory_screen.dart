import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart' hide businessType;
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/business_service/controller/service_controller.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/view_service_list.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/inventory_controller.dart';
import 'foodandgrocery/food_and_grocery_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  String _businessType = BusinessType.Product.name;
  bool _isLoading = true;
  late List<Tab> _tabs;

  final inventoryController = Get.put(InventoryController());
  final serviceController = Get.put(ServiceController());
  final foodUploadController = Get.put(FoodUploadController());

  @override
  void initState() {
    _initializeData();
    super.initState();
  }

  Future<void> _initializeData() async {
    final type = await getBusinessType();
    final business = type.toLowerCase();

    _businessType = business;
    _tabs = [];

    if (isShowProduct.contains(business)) _tabs.add(const Tab(text: 'My Products'));
    if (isShowService.contains(business)) _tabs.add(const Tab(text: 'My Services'));
    if (isShowFood.contains(business)) _tabs.add(const Tab(text: 'Food & Grocery'));

    _tabController = TabController(length: _tabs.length, vsync: this);
    if (_tabs.isEmpty) {
      debugPrint("No tabs available for business type: $business");
      setState(() => _isLoading = false);
      return;
    }

    final firstTab = _tabs.first.text;
    if (firstTab == 'My Products') {
      inventoryController.callApi(forceRefresh: true);
    } else if (firstTab == 'My Services') {
      final queryParams = {
        ApiKeys.all: false,
        ApiKeys.type: "service",
        ApiKeys.providerType: ProductServiceProviderType.business.title,
      };
      serviceController.getServices(queryParams);
    } else if (firstTab == 'Food & Grocery') {
      final queryParams = {
        ApiKeys.all: false,
        ApiKeys.type: "food",
        ApiKeys.providerType: ProductServiceProviderType.business.title,
      };
      foodUploadController.getFoodService(queryParams);
    }
    setState(() => _isLoading = false);
  }


  @override
  void dispose() {
    Get.delete<ProductController>();
    Get.delete<InventoryController>();
    _tabController?.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: CommonBackAppBar(
          controller: searchController,
          searchHintText:
              'Search ...',
              // 'Search ${_tabController.index == 0 ? 'Product' : _tabController.index == 1 ? 'Service' : 'Food & Grocery'}...',
          onClearCallback: () => searchController.clear(),
          isSearch: true,
          isInventoryPopUpMenu: true,
          bottomWidget: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              if (isShowProduct.contains(_businessType))
                const Tab(text: 'My Products'),
              if (isShowService.contains(_businessType))
                const Tab(text: 'My Services'),
              if (isShowFood.contains(_businessType))
                const Tab(text: 'Food & Grocery'),
            ],
          ),
        ),
      ),
      floatingActionButton: Builder(builder: (context) {
        return FloatingActionButton(
          onPressed: () => showPopUpMenu(context, inventoryController),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedRotation(
            turns: inventoryController.isMenuOpen.value ? 0.25 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Obx(() => Icon(
                  inventoryController.isMenuOpen.value ? Icons.close : Icons.add,
                  key: ValueKey(inventoryController.isMenuOpen.value),
                  // important for AnimatedSwitcher
                  size: SizeConfig.size36,
                )),
          ),
        );
      }),
      body: TabBarView(
        controller: _tabController,
        children: [
          if ((isShowProduct.contains(_businessType)))
            ProductScreen(),
          if ((isShowService.contains(_businessType)))
            ViewServiceList(
              providerType: ProductServiceProviderType.business,
            ),
          if ((isShowFood.contains(_businessType)))
            FoodAndGroceryScreen(
              providerType: ProductServiceProviderType.business,
            ),

        ],
      ),
    );
  }

  // Widget _buildSelectedTabContent(InventoryController controller) {
  //   switch (selectedIndex) {
  //     case 0:
  //       return _buildProductsList(controller);
  //     case 1:
  //       return _buildCategoriesList(controller);
  //     default:
  //       return const SizedBox();
  //   }
  // }

  void showPopUpMenu(
      BuildContext context, InventoryController controller) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // FAB position & size
    final Offset fabPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size fabSize = button.size;

    // Menu height (approximate based on items * itemHeight)
    const double itemHeight = 36.0;
    const int itemCount = 3;
    const double menuHeight = itemHeight * (itemCount-1);

    final RelativeRect position = RelativeRect.fromLTRB(
      fabPosition.dx, // align with FAB left
      fabPosition.dy - menuHeight - 24, // just above FAB
      overlay.size.width - fabPosition.dx - fabSize.width,
      overlay.size.height - fabPosition.dy,
    );

    controller.isMenuOpen.value = true;
    final result = await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: popupMenuInventoryItems(_businessType),
    );
    controller.isMenuOpen.value = false;

    if (result != null) {
      if (result.toUpperCase() == "ADD PRODUCT") {
        await Get.toNamed(
            RouteHelper.getAddProductScreenRoute(),
            arguments: {
              ApiKeys.id: businessId,
              ApiKeys.providerType: ProductServiceProviderType.business
            }
        );
        controller.callApi(forceRefresh: true);
      } else if (result.toUpperCase() == "ADD SERVICE") {
        Get.toNamed(
            RouteHelper.getAddServicesScreenRoute(),
            arguments: {
              ApiKeys.providerType: ProductServiceProviderType.business,
            }
        );
      } else if (result.toUpperCase() == "ADD FOOD") {
        Get.to(() => FoodUploadScreen(
          providerType: ProductServiceProviderType.business,
        ));
        // Get.to(()=> FoodPage());
      }
    }
  }
}

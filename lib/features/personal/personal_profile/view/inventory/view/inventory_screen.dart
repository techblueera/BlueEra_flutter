import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart' hide businessType;
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
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
  late TabController _tabController;
  final controller = Get.put(InventoryController());

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    controller.callApi(forceRefresh: true);
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<ProductController>();
    Get.delete<InventoryController>();
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: CommonBackAppBar(
          controller: searchController,
          searchHintText:
              'Search ...',
              // 'Search ${_tabController.index == 0 ? 'Product' : _tabController.index == 1 ? 'Service' : 'Food & Grocery'}...',
          onClearCallback: () => searchController.clear(),
          isSearch: true,
          isProductPopUpMenu: true,
          bottomWidget: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              if ((isShowProduct.contains(businessType())))
                Tab(text: 'My Products'),
              if ((isShowService.contains(businessType())))
                Tab(text: 'My Services'),
              if ((isShowFood.contains(businessType())))
                Tab(text: 'Food & Grocery'),
            ],
          ),
        ),
      ),
      floatingActionButton: Builder(builder: (context) {
        return FloatingActionButton(
          onPressed: () => showPopUpMenu(context, controller),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedRotation(
            turns: controller.isMenuOpen.value ? 0.25 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Obx(() => Icon(
                  controller.isMenuOpen.value ? Icons.close : Icons.add,
                  key: ValueKey(controller.isMenuOpen.value),
                  // important for AnimatedSwitcher
                  size: SizeConfig.size36,
                )),
          ),
        );
      }),
      body: TabBarView(
        controller: _tabController,
        children: [
          if ((isShowProduct.contains(businessType())))
            ProductScreen(),
          if ((isShowService.contains(businessType())))
            ViewServiceList(
              providerType: ProductServiceProviderType.business,
            ),
          if ((isShowFood.contains(businessType())))
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
    const double menuHeight = itemHeight * itemCount;

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
      items: popupMenuInventoryItems(),
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

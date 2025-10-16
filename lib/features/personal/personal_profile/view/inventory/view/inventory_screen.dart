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
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/categoryinventory_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/view_service_list.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
            ViewServiceList(),
          if ((isShowFood.contains(businessType())))
            FoodAndGroceryScreen(),

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

  Widget _buildCategoryCard(
      CategoryInventoryModel category, InventoryController controller) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Get.to(()=>CategoryInventoryScreen(category: category));
          // Get.to(()=>CatalogWidget());
        },
        child: Container(
          // margin: EdgeInsets.only(bottom: SizeConfig.size8),
          padding: EdgeInsets.all(SizeConfig.size4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(SizeConfig.size8),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Image with Product Count Overlay
              Container(
                width: 120,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                  child: Stack(
                    children: [
                      // Category Image
                      Positioned.fill(
                        child: Image.asset(
                          category.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.size8),
                              ),
                              child: const Icon(
                                Icons.folder,
                                color: AppColors.grey9B,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      // Product Count Overlay - Bottom Left
                      Positioned(
                        bottom: 8,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            '+${category.productCount} Product',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: SizeConfig.size12),

              // Category Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Name and Three Dots
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            category.name,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Options Menu
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          offset: const Offset(-6, 36),
                          color: AppColors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onSelected: (value) => controller
                              .handleCategoryOption(value, category.id),
                          onCanceled: () {
                            // Prevent focus when popup is closed
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _searchFocusNode.unfocus();
                            });
                          },
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.grey9B,
                            size: 20,
                          ),
                          itemBuilder: (context) =>
                              popupInventoryCategoryItems(),
                        ),
                      ],
                    ),

                    // SizedBox(height: SizeConfig.size8),

                    // Category Description
                    CustomText(
                      category.description,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey9B,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      height: 1.4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              ApiKeys.providerType: 'Business',
            }
        );
      } else if (result.toUpperCase() == "ADD FOOD") {
        Get.to(() => FoodUploadScreen());
        // Get.to(()=> FoodPage());
      }
    }
  }
}

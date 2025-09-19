import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_category_folder_screen/add_category_folder_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_product_screen/add_product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/model/categoryinventory_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/model/product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'inventory_controller.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {

  final List<String> productTab = ["Products", "Category Folder"];
  int selectedIndex = 0;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        controller: searchController,
        searchHintText:  'Search ${selectedIndex == 0 ? 'Product' : 'Category'}...',
        onClearCallback: () => searchController.clear(),
        isSearch: true,
        isAddProduct: selectedIndex == 0,
        isAddProductCategory: selectedIndex == 1
      ),
      body: GestureDetector(
        onTap: (){
          FocusScope.of(context).unfocus();
          _searchFocusNode.unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: Column(
              children: [
                // Custom Header Container
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
                //   color: AppColors.white,
                //   child: Row(
                //     children: [
                //       // Back Button
                //         GestureDetector(
                //           onTap:(){
                //             Get.back();
                //           },
                //           child: Icon(
                //             Icons.arrow_back_ios,
                //             color: AppColors.black,
                //             size: 20,
                //           ),
                //         ),
                //         // onPressed: () => Get.back(),
                //         // padding: EdgeInsets.zero,
                //         // constraints: const BoxConstraints(),
                //
                //       // Search Container
                //       Expanded(
                //         child: Container(
                //           height: 40,
                //           margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                //           decoration: BoxDecoration(
                //             color: AppColors.fillColor,
                //             borderRadius: BorderRadius.circular(20),
                //             border: Border.all(color: AppColors.greyE5, width: 1),
                //           ),
                //           child: TextField(
                //             style: TextStyle(color: Colors.black),
                //             controller: controller.searchController,
                //             focusNode: _searchFocusNode,
                //             autofocus: false,
                //             onTap: () {
                //               // Only allow focus when user explicitly taps
                //             },
                //             decoration: InputDecoration(fillColor: Colors.grey.withOpacity(0.1),
                //               hintText: 'Search ${selectedIndex == 0 ? 'Product' : 'Category'}...',
                //               hintStyle: TextStyle(
                //                 color: AppColors.grey9B,
                //                 fontSize: 15,
                //               ),
                //               prefixIcon: Image.asset("assets/icons/search_icon.png"),
                //               border: InputBorder.none,
                //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //             ),
                //           ),
                //         ),
                //       ),
                //
                //       // Draft Text
                //       GestureDetector(
                //         onTap: () {
                //           Navigator.pushNamed(context, RouteConstant.DraftScreen);
                //         },
                //         child: const CustomText(
                //           'Draft',
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600,
                //           color: AppColors.primaryColor,
                //         ),
                //       ),
                //     ],
                //   ),
                //             ),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inventory Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HorizontalTabSelector(
                            tabs: productTab,
                            selectedIndex: selectedIndex,
                            onTabSelected: (index, value) {
                              if (mounted) {
                                setState(() => selectedIndex = index);
                              }
                            },
                            labelBuilder: (label) => label,
                          ),


                          GestureDetector(onTap: (){
                            if (selectedIndex == 0) {
                              // Add Product
                               Get.to(()=> AddProductScreen());
                            } else {
                              // Add Category
                              Get.to(()=>AddCategoryFolderScreen());
                            }
                          },
                            child: Container(
                              height: SizeConfig.size30,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primaryColor)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: AppColors.primaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  CustomText(
                                    selectedIndex == 0 ? 'Add Product' : 'Add Category',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: SizeConfig.size16),

                      // Content based on selected tab
                      Expanded(
                        child: _buildSelectedTabContent(controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(InventoryController controller) {
    switch (selectedIndex) {
      case 0:
        return _buildProductsList(controller);
      case 1:
        return _buildCategoriesList(controller);
      default:
        return const SizedBox();
    }
  }

  Widget _buildProductsList(InventoryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = controller.filteredProducts[index];
          return _buildProductCard(product, controller);
        },
      );
    });
  }

  Widget _buildCategoriesList(InventoryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.filteredCategories.length,
        itemBuilder: (context, index) {
          final category = controller.filteredCategories[index];
          return _buildCategoryCard(category, controller);
        },
      );
    });
  }

  Widget _buildCategoryCard(CategoryInventoryModel category, InventoryController controller) {
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
                color: AppColors.black.withOpacity(0.05),
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
                                borderRadius: BorderRadius.circular(SizeConfig.size8),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (value) => controller.handleCategoryOption(value, category.id),
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
                          itemBuilder: (context) => popupInventoryCategoryItems(),
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

  Widget _buildProductCard(ProductModel product, InventoryController controller) {
    return Container(
      // margin: EdgeInsets.only(bottom: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with Stock Status - Enhanced to match the image
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive height based on available space
                final containerHeight = constraints.maxHeight * 0.9; // Use 90% of available height
                final responsiveHeight = containerHeight.clamp(120.0, 180.0); // Clamp between min and max

                return Stack(
                  children: [
                    Container(
                      height: responsiveHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD), // Light blue background
                        borderRadius: BorderRadius.circular(SizeConfig.size8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(SizeConfig.size8),
                        child: Stack(
                          children: [
                            // Background image with blur effect
                            Positioned.fill(
                              child: Image.asset(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4FD),
                                      borderRadius: BorderRadius.circular(SizeConfig.size8),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      color: AppColors.grey9B,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Main product image
                            Positioned.fill(
                              child: Image.asset(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4FD),
                                      borderRadius: BorderRadius.circular(SizeConfig.size8),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      color: AppColors.grey9B,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Stock Status Tag - Positioned like in the image
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stockStatus == 'In stock'
                              ? AppColors.green39
                              : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          product.stockStatus,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Product Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name and Three Dots
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        product.name,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Options Menu - Positioned at top right
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(-6, 36),
                      color: AppColors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (value) => controller.handleProductOption(value, product.id),
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
                      itemBuilder: (context) => popupInventoryMenuItems(),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.size4),

                // Price Information - Enhanced to match the image
                Row(
                  children: [
                    CustomText(
                      'Rs: ${product.currentPrice.toInt()}/-',
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      '${product.originalPrice.toInt()}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey9B,
                      decoration: TextDecoration.lineThrough,
                    ),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      '${product.discountPercentage}% off',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green39,
                    ),
                  ],
                ),

                // Discount percentage on new line
                SizedBox(height: SizeConfig.size4),



                // Size Options
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Size',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey9B,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    Wrap(
                      spacing: SizeConfig.size8,
                      runSpacing: SizeConfig.size4,
                      children: product.sizes.map((size) {
                        final isSelected = product.sizes.indexOf(size) == product.selectedSizeIndex;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.fillColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
                              width: 1,
                            ),
                          ),
                          child: CustomText(
                            size,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.primaryColor : AppColors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.size12),

                // Color Options
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Colour',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey9B,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    Wrap(
                      spacing: SizeConfig.size8,
                      runSpacing: SizeConfig.size4,
                      children: product.colors.map((color) {
                        final isSelected = product.colors.indexOf(color) == product.selectedColorIndex;
                        return Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
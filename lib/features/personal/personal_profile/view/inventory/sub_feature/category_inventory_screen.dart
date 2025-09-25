import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/categoryinventory_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/sub_feature/category_inventory_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';


class CategoryInventoryScreen extends StatefulWidget {
  final CategoryInventoryModel category;
  const CategoryInventoryScreen({super.key, required this.category});

  @override
  State<CategoryInventoryScreen> createState() => _CategoryInventoryScreenState();
}

class _CategoryInventoryScreenState extends State<CategoryInventoryScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  late final  CategoryInventoryController controller;


 @override
void initState() {
  super.initState();
  controller = Get.isRegistered<CategoryInventoryController>()
      ? Get.find<CategoryInventoryController>()
      : Get.put(CategoryInventoryController());
  // controller.changeFilter('Draft'); // not needed for a draft-only screen
}

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
 

    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _searchFocusNode.unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header: Back + Search + Draft
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size12,
                ),
                color: AppColors.white,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.black,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
                        margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                        decoration: BoxDecoration(
                          color: AppColors.fillColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.greyE5, width: 1),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.black),
                          controller: controller.searchController,
                          focusNode: _searchFocusNode,
                          autofocus: false,
                          decoration: InputDecoration(
                            fillColor: Colors.grey.withOpacity(0.1),
                            hintText: 'Search Product...',
                            hintStyle: const TextStyle(
                              color: AppColors.grey9B,
                              fontSize: 15,
                            ),
                            prefixIcon: Image.asset('assets/icons/search_icon.png'),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  
                  ],
                ),
              ),

              // Body: Products list only
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                            'Category Products',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: AppColors.primaryColor),
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
                                  'Add Product',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.primaryColor),
                            );
                          }
                        
                          final items = controller.filteredProducts;
                          if (items.isEmpty) {
                            return const Center(
                              child: CustomText(
                                'No products found',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey9B,
                              ),
                            );
                          }
                        
                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final product = items[index];
                              return _buildProductCard(product, controller);
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, CategoryInventoryController controller) {
    return Container(
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
          // Image + stock tag
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(SizeConfig.size8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size8),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            product.imageUrl??'',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(SizeConfig.size8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: AppColors.grey9B,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Image.asset(
                            product.imageUrl??'',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(SizeConfig.size8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: AppColors.grey9B,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.stockStatus == 'In stock' ? AppColors.green39 : Colors.red,
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
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(-6, 36),
                      color: AppColors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (value) => controller.handleProductOption(value, product.id),
                      onCanceled: () {
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
                SizedBox(height: SizeConfig.size4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
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
                        final isSelected =
                            product.sizes.indexOf(size) == product.selectedSizeIndex;
                        return Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : AppColors.fillColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.greyE5,
                              width: 1,
                            ),
                          ),
                          child: CustomText(
                            size,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
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
                        final isSelected =
                            product.colors.indexOf(color) == product.selectedColorIndex;
                        return Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.greyE5,
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
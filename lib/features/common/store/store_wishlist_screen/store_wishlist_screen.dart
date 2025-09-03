import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_listview_builder.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'store_wishlist_screen_controller.dart';

class StoreWishlistScreen extends StatelessWidget {
  const StoreWishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreWishlistScreenController>(
      init: StoreWishlistScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Blue Header Section with Search Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size12,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.black,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),

                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 45,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.greyE5,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.grey9B,
                                size: 20,
                              ),
                              SizedBox(width: SizeConfig.size8),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 14,
                                  ),
                                  controller: controller.searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'iphone 16...',
                                    hintStyle: TextStyle(
                                      color: AppColors.grey9B,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: SizeConfig.size12),

                    ],
                  ),
                ),
                // Wishlist Title
                Padding(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  child: CustomText(
                    'Wishlist',
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),

                // Wishlist Items List
                Expanded(
                  child: Obx(() => controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : CustomStringListViewBuilder(
                          items: controller.filteredItems.map((item) => item['id'].toString()).toList(),
                          itemBuilder: (context, itemId, index) {
                            final item = controller.filteredItems[index];
                            return _buildWishlistItem(context, item, controller);
                          },
                          separator: SizedBox(height: SizeConfig.size12),
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                        )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWishlistItem(
    BuildContext context,
    Map<String, dynamic> item,
    StoreWishlistScreenController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: item['imageColor'] ?? Colors.grey[200],
              ),
              child: item['image'] != null
                  ? Image.asset(
                      item['image'],
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.phone_android,
                      size: 40,
                      color: Colors.grey[600],
                    ),
            ),
          ),
          
          SizedBox(width: SizeConfig.size12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                CustomText(
                  item['name'] ?? 'Product Name',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: SizeConfig.size4),
                
                // Current Price
                Row(
                  children: [
                    CustomText(
                      item['currentPrice'] ?? 'Rs: 0/-',
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    CustomText(
                      item['originalPrice'] ?? '0',
                      fontSize: SizeConfig.small,
                      color: AppColors.grey9B,
                      decoration: TextDecoration.lineThrough,
                    ),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      item['discount'] ?? '0% off',
                      fontSize: SizeConfig.small,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
                
                SizedBox(height: SizeConfig.size2),

                SizedBox(height: SizeConfig.size8),
                
                // Seller Info
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(
                      child: CustomText(
                        item['seller'] ?? 'Seller Name',
                        fontSize: SizeConfig.small,
                        color: AppColors.grey9B,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: SizeConfig.size4),
                
                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    SizedBox(width: SizeConfig.size2),
                    CustomText(
                      item['rating'] ?? '0.0',
                      fontSize: SizeConfig.small,
                      color: AppColors.grey9B,
                    ),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      '(${item['reviews'] ?? '0 Ratings'})',
                      fontSize: SizeConfig.small,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(width: SizeConfig.size8),
          
          // More Options Button for each item
          GestureDetector(
            onTap: () {
              _showItemOptions(context, item, controller);
            },
            child: const Icon(
              Icons.more_vert,
              color: AppColors.grey9B,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }


  void _showItemOptions(BuildContext context, Map<String, dynamic> item, StoreWishlistScreenController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const CustomText('View Details'),
              onTap: () {
                Get.back();
                controller.viewItemDetails(item['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const CustomText('Add to Cart'),
              onTap: () {
                Get.back();
                controller.addToCart(item['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const CustomText('Share'),
              onTap: () {
                Get.back();
                controller.shareItem(item['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const CustomText('Remove from Wishlist', color: Colors.red),
              onTap: () {
                Get.back();
                controller.removeFromWishlist(item['id']);
              },
            ),
          ],
        ),
      ),
    );
  }
}

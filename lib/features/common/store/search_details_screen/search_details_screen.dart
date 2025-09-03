import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../product_details_screen/product_details_screen.dart';
import 'search_details_screen_controller.dart';

class SearchDetailsScreen extends StatelessWidget {
  const SearchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SearchDetailsScreenController>(
      init: SearchDetailsScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Search Bar
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
                                  controller: controller.searchController,
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 14,
                                  ),
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

                // Product Title
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size8,
                  ),
                  child: CustomText(
                    'Product',
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),

                // Products Grid
                Expanded(
                  child: Obx(() => controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(SizeConfig.size16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: controller.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = controller.filteredProducts[index];
                            return GestureDetector(
                                onTap: (){
                                  Get.to(()=>ProductDetailsScreen());
                                },
                                child: _buildProductCard(context, product, controller));
                          },
                        )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> product,
    SearchDetailsScreenController controller,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: product['imageColor'] ?? Colors.grey[200],
                ),
                child: product['image'] != null
                    ? Image.asset(
                        product['image'],
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.phone_android,
                        size: 40,
                        color: Colors.grey[600],
                      ),
              ),
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomText(
                    product['name'] ?? 'Product Name',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: SizeConfig.size4),
                  
                  // Current Price
                  CustomText(
                    product['currentPrice'] ?? '₹0',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  
                  SizedBox(height: SizeConfig.size2),
                  
                  // Original Price and Discount
                  Row(
                    children: [
                      CustomText(
                        product['discount'] ?? '0% Off',
                        fontSize: SizeConfig.small,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        product['originalPrice'] ?? '₹0',
                        fontSize: SizeConfig.small,
                        color: AppColors.grey9B,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: SizeConfig.size4),
                  
                  // Seller Info
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size4),
                      Expanded(
                        child: CustomText(
                          product['seller'] ?? 'Seller Name',
                          fontSize: SizeConfig.small,
                          color: AppColors.grey9B,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: SizeConfig.size2),
                  
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      SizedBox(width: SizeConfig.size2),
                      CustomText(
                        '${product['rating'] ?? '0.0'} (${product['reviews'] ?? '0 reviews'})',
                        fontSize: SizeConfig.small,
                        color: AppColors.grey9B,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

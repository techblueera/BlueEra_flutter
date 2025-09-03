import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_horizontal_listview.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../search_details_screen/search_details_screen.dart';
import 'store_search_screen_controller.dart';

class StoreSearchScreen extends StatelessWidget {
  String? initialQuery;
   StoreSearchScreen({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreSearchScreenController>(
      init: StoreSearchScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
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

                // Content Sections
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Products Section
                        _buildSectionHeader('Products', () {
                          // Handle "See all" for Products
                        }),
                        SizedBox(height: SizeConfig.size12),
                        ProductHorizontalListView(
                          products: controller.products,
                          height: 280, // Fixed height for products
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                          ),
                          onProductTap: (product) {
                            // Handle product tap
                           Get.to(()=>SearchDetailsScreen());
                          },
                        ),
                        SizedBox(height: SizeConfig.size24),

                        // Stores Section
                        _buildSectionHeader('Stores', () {
                          // Handle "See all" for Stores
                        }),
                        SizedBox(height: SizeConfig.size12),
                        StoreHorizontalListView(
                          stores: controller.stores,
                          height: 280, // Increased height for stores
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                          ),
                          onStoreTap: (store) {
                           
                          },
                        ),
                        SizedBox(height: SizeConfig.size24),

                        // Services Section
                        _buildSectionHeader('Services', () {
                          // Handle "See all" for Services
                        }),
                        SizedBox(height: SizeConfig.size12),
                        ServiceHorizontalListView(
                          services: controller.services,
                          height: 240, // Increased height for services
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                          ),
                          onServiceTap: (service) {
                            // Handle service tap

                          },
                        ),
                        SizedBox(height: SizeConfig.size24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAllTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          GestureDetector(
            onTap: onSeeAllTap,
            child: CustomText(
              'See all',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

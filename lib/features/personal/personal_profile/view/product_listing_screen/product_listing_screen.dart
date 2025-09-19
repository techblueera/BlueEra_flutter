import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listing_form_screen/listing_form_screen.dart';
import 'product_listing_controller.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen>
    with WidgetsBindingObserver {
  late ProductListingController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize controller
    controller = Get.put(ProductListingController());

    // Ensure controller is properly initialized with arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeWithArguments();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header Container
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
              color: AppColors.white,
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
                  SizedBox(width: 7,),
                  // Title
                  Center(
                    child: Obx(() =>
                        CustomText(
                          controller.selectedListingType.value.isNotEmpty
                              ? controller.selectedListingType.value
                              : 'Product Listing',
                          fontSize: SizeConfig.medium15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        )),
                  ),

                  Spacer(),
                  // Listing Type Button
                  GestureDetector(
                    // onTap: () => controller.showListingTypeDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomText(
                            'Listing Type',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primaryColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

                         // Main Content
             Expanded(
               child: SingleChildScrollView(
                 child: Padding(
                   padding: EdgeInsets.all(SizeConfig.size16),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                    // Heading
                    CustomText(
                      'Enter Product Name here',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),

                    SizedBox(height: SizeConfig.size8),

                    // Subtitle
                    CustomText(
                      'Find product name to get autofill product details.',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey9B,
                    ),

                    SizedBox(height: SizeConfig.size24),

                    // Product Name Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyE5, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller.productNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Wireless Earbuds Boat Airdop....',
                          hintStyle: TextStyle(
                            color: AppColors.grey9B,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16,
                              vertical: 16),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                        maxLines: 3,
                        minLines: 3,
                      ),
                    ),

                    SizedBox(height: SizeConfig.size32),

                    // Action Buttons
                    Row(
                      children: [
                        // Save as Draft Button
                        Obx(() =>
                           Expanded(
                            child: GestureDetector(
                              onTap: () => controller.saveAsDraft(),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.primaryColor, width: 1),
                                ),
                                child: Center(
                                  child: CustomText(
                                    controller.selectedListingType.value ==
                                        "Single Product Listing"
                                        ?'Create New': 'Save as draft',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: SizeConfig.size16),

                                                 // Post Product Button
                         Obx(() =>
                            Expanded(
                             child: GestureDetector(
                               onTap: () {
                                 Get.toNamed(RouteHelper.getListingFormScreenRoute());
                                 // Get.to(() => ListingFormScreen(), arguments: {
                                 //   "listingType": controller.selectedListingType.value,
                                 // });
                               },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: CustomText(
                                    controller.selectedListingType.value ==
                                        "Single Product Listing"
                                        ?'Continue': 'Post Product',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  // Add bottom padding to prevent overflow
                  SizedBox(height: SizeConfig.size32),
                ],
                ),
              ),
            ),
             )

          ],
        ),
      ),
    );
  }
} 
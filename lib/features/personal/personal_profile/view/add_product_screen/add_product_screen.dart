import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_product_screen_controller.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(AddProductScreenController());

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "Add Product",
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
       InkWell(
         onTap: () {
           Get.to(() => ListingFormScreen());
         },
         child: CustomFormCard(child: LocalAssets(
                                imagePath: AppIconAssets.edit_pen_icon,
                                boxFix: BoxFit.cover,
                              ),),
       ),
     
            // Error Banner
            Obx(() => controller.showErrorBanner.value
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(SizeConfig.size16),
                    margin: EdgeInsets.all(SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.redLightOut,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: CustomText(
                            "You can't select more than 10 products at a time.",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w500,
                            color: AppColors.red,
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.dismissErrorBanner,
                          child: const Icon(
                            Icons.close,
                            color: AppColors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),

            // Form Content
            Expanded(
              child: CustomFormCard(
                margin: EdgeInsets.fromLTRB(SizeConfig.size16, 0, SizeConfig.size16, 0),
                 borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
    ),
                child: Column(
                  children: [
                    // Search Section
                    Padding(
                      padding: EdgeInsets.all(SizeConfig.size20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Enter Product Name here',
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          SizedBox(height: SizeConfig.size8),
                          CustomText(
                            'Find product name to get autofill product details.',
                            fontSize: SizeConfig.small,
                            color: AppColors.grey9B,
                          ),
                          SizedBox(height: SizeConfig.size16),
                          Container(
                            // padding: EdgeInsets.symmetric(
                            //     horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
                            decoration: BoxDecoration(
                              color: AppColors.fillColor,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.greyE5, width: 1),
                            ),
                            child: TextField(
                              style: TextStyle(color: Colors.black),
                              controller: controller.searchController,
                              onChanged: (value) {
                                print('Search text changed: $value');
                                controller.filterProducts();
                              },
                              decoration: const InputDecoration(
                                hintText:
                                    "e.g. Wireless Earbuds Boat Airdope....",
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

                    // Products List
                    Expanded(
                      child: Obx(() => controller.filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  // CustomText(
                                  //   'No products found',
                                  //   fontSize: SizeConfig.medium,
                                  //   color: AppColors.grey9B,
                                  // ),
                                  GestureDetector(
                                      onTap: () {
                                        // Navigate or show dialog using GetX
                                        Get.to(() => ListingFormScreen());
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        elevation: 1,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Image.asset("assets/icons/pencil_edit_icon.png"),// Pencil icon
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    CustomText(
                                                      "Create Own Product Manually",
                                                      fontSize: SizeConfig.size14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    SizedBox(height: 4),
                                                    CustomText(
                                                      "Open the full manual form\nto add detailed information section by section.",
                                                     color: AppColors.secondaryTextColor,
                                                       fontSize:SizeConfig.size12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size20),
                              itemCount: controller.filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product =
                                    controller.filteredProducts[index];
                                return _buildProductItem(controller, product);
                              },
                            )),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: EdgeInsets.all(SizeConfig.size16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Save as Draft Button
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.primaryColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.saveAsDraft,
                          borderRadius: BorderRadius.circular(8),
                          child: const Center(
                            child: CustomText(
                              'Save as draft',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: SizeConfig.size12),

                  // Post Product Button
                  Expanded(
                    child: Obx(() => CustomBtn(
                          title: controller.isLoading.value
                              ? 'Posting...'
                              : 'Post Product',
                          onTap: controller.isLoading.value
                              ? null
                              : controller.postProduct,
                          bgColor: AppColors.primaryColor,
                          textColor: AppColors.white,
                          height: 45,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
      AddProductScreenController controller, ProductItem product) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => controller.toggleProductSelection(product),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: product.isSelected
                    ? AppColors.primaryColor
                    : AppColors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: product.isSelected
                      ? AppColors.primaryColor
                      : AppColors.greyE5,
                  width: 1,
                ),
              ),
              child: product.isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.greyE5, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.fillColor,
                    child: const Icon(
                      Icons.image,
                      color: AppColors.grey9B,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Description
                CustomText(
                  product.description,
                  fontSize: SizeConfig.small,
                  color: AppColors.black,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: SizeConfig.size8),

                // Product Details Row
                Wrap(
                  spacing: SizeConfig.size16,
                  runSpacing: SizeConfig.size4,
                  children: [
                    // Colour
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          'Colour',
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.grey9B,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    // Price (only show if not selected)
                    if (!product.isSelected)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            'Price',
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.grey9B,
                          ),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            product.price,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),

                    // Size
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          'Size',
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.grey9B,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          product.size,
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ],
                ),

                // Selling Price Input (only shown when selected)
                if (product.showSellingPrice) ...[
                  SizedBox(height: SizeConfig.size12),
                  Row(
                    children: [
                      CustomText(
                        'Selling price',
                        fontSize: SizeConfig.small,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: Container(
                          // padding: EdgeInsets.symmetric(
                          //     horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: AppColors.greyE5, width: 1),
                          ),
                          child: TextField(
                            onChanged: (value) =>
                                controller.updateSellingPrice(product, value),
                            decoration: const InputDecoration(
                              hintText: "E.g. Text",
                              hintStyle: TextStyle(
                                color: AppColors.grey9B,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Action Icons
          Column(
            children: [
              // View Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ),

              SizedBox(height: SizeConfig.size8),

              // Remove Icon (only shown when selected)
              if (product.isSelected)
                GestureDetector(
                  onTap: () => controller.removeProduct(product),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.primaryColor,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}



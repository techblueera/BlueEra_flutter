import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
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

    return Obx(() =>
        Scaffold(
          backgroundColor: AppColors.appBackgroundColor,
          appBar: CommonBackAppBar(
              title: "Add Product",
              isCreateOwnProduct: controller.searchProduct.isNotEmpty
          ),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(SizeConfig.size15),
              child: Column(
                children: [
                  // Error Banner
                  controller.showErrorBanner.value
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
                      : const SizedBox.shrink(),

                  // Form Content
                  CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.size16),
                    borderRadius: BorderRadius.circular(10.0),
                    child: Column(
                      children: [
                        // Search Section
                        Column(
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
                            CommonTextField(
                                textEditController: controller.searchController,
                                onChange: (value) {
                                  controller.searchProduct.value = value;
                                  controller.filterProducts();
                                },
                                hintText: "e.g. Wireless Earbuds Boat Airdope....",
                                showClearIcon: controller.searchProduct
                                    .isNotEmpty,
                                onClearTap: () {
                                  controller.searchController.clear();
                                  controller.searchProduct.value = '';
                                },
                                isValidate: false
                            ),
                          ],
                        ),

                        if(controller.searchProduct.isNotEmpty)
                          ...[
                            // Products List
                            controller.filteredProducts.isEmpty
                                ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size20),
                              child: CustomText(
                                  "No product Here, don’t worry you can create product manually ",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor,
                                  textAlign: TextAlign.center
                              ),
                            )
                                : Column(
                              children: [
                                ListView.separated(
                                  itemCount: controller.filteredProducts.length,
                                  padding: EdgeInsets.symmetric(
                                      vertical: SizeConfig.size20),
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    final product =
                                    controller.filteredProducts[index];
                                    return _buildProductItem(
                                        controller, product);
                                  },
                                  separatorBuilder: (BuildContext context,
                                      int index) {
                                    return CommonHorizontalDivider(
                                      color: AppColors.whiteE5,
                                    );
                                  },
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PositiveCustomBtn(
                                        onTap: () {

                                        },
                                        title: 'Save as draft',
                                        bgColor: AppColors.white,
                                        borderColor: AppColors.primaryColor,
                                        textColor: AppColors.primaryColor,
                                        radius: 10.0,
                                      ),
                                    ),
                                    SizedBox(width: SizeConfig.size10),
                                    Expanded(
                                      child: PositiveCustomBtn(
                                        onTap: () {

                                        },
                                        title: 'Next',
                                        iconPath: AppIconAssets.shareIcon,
                                        bgColor: AppColors.primaryColor,
                                        borderColor: AppColors.primaryColor,
                                        radius: 10.0,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),


                          ]
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size10),

                  (controller.searchProduct.isEmpty)
                      ? GestureDetector(
                      onTap: () {
                        // Navigate or show dialog using GetX
                        Get.to(() => ListingFormScreen());
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size15,
                            vertical: SizeConfig.size25),
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: Row(
                          children: [
                            LocalAssets(imagePath: AppIconAssets
                                .pencilEditIcon), // Pencil icon
                            const SizedBox(width: 15.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "Create Own Product Manually",
                                    fontSize: SizeConfig.medium15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: 10.0),
                                  CustomText(
                                      "Open the full manual form\nto add detailed information section by section.",
                                      color: AppColors.secondaryTextColor,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w600
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                      : SizedBox(),

                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildProductItem(AddProductScreenController controller,
      ProductItem product) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size4),
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



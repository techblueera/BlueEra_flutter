import 'dart:math';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_preview_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddProductScreen extends StatefulWidget {
  final String id;
  final ProductServiceProviderType providerType;
  const AddProductScreen({super.key, required this.id, required this.providerType});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final scrollController = ScrollController();
  final controller = Get.put(InventoryController());

  @override
  void dispose() {
    Get.delete<InventoryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() =>
        Scaffold(
          backgroundColor: AppColors.appBackgroundColor,
          appBar: CommonBackAppBar(
              title: "Add Product",
              buildCustomWidget: (controller.searchProduct.isNotEmpty) ?
              ()=> GestureDetector(
                onTap: () =>
                    Get.toNamed(
                        RouteHelper.getAddProductViaAiStep1Route(),
                        arguments: {
                          ApiKeys.id: widget.id,
                          ApiKeys.providerType: widget.providerType
                        }
                    ),
                child: Container(
                  height: SizeConfig.size30,
                  margin: EdgeInsets.only(right: SizeConfig.size20),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryColor)),
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
                        'Create Own',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ) : null,
          ),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  if (controller.hasMoreData && !controller.isLoadingMore) {
                    controller.fetchListOfSearchProductApi(
                        controller.searchProduct.value,
                        isLoadMore: true
                    );
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: scrollController,
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
                                  onChange: (value) =>
                                      controller.onSearchChanged(value),
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
                              controller.ProductSearchLoading.isTrue ?
                              Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: CircularProgressIndicator(),
                              )
                                : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Products Variants
                                  controller.searchProductVariantsList.isEmpty
                                      ? SizedBox.shrink()
                                      : Padding(
                                    padding: EdgeInsets.only(top: SizeConfig.size10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        CustomText(
                                          "Product Variants",
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                        ListView.separated(
                                          itemCount: controller
                                              .searchProductVariantsList.length,
                                          padding: EdgeInsets.symmetric(
                                              vertical: SizeConfig.size10),
                                          physics: NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            final productVariants =
                                            controller
                                                .searchProductVariantsList[index];
                                            return _buildProductVariantItem(
                                                controller,
                                                productVariants
                                            );
                                          },
                                          separatorBuilder: (BuildContext context,
                                              int index) {
                                            return CommonHorizontalDivider(
                                              color: AppColors.whiteE5,
                                            );
                                          },
                                        ),
                                        CustomBtn(
                                            onTap: controller.hasAnySelected()
                                                ? () async {
                                              final missingPriceIds = controller.validateSelectedVariants(
                                                controller.searchProductVariantsList,
                                              );

                                              if (missingPriceIds.isNotEmpty) {
                                                // Ask confirmation
                                                final proceed = await showDialog<bool>(
                                                  context: Get.context!,
                                                  barrierDismissible: false,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      title: const CustomText(
                                                        "Use Listed Prices?",
                                                        fontWeight: FontWeight.bold
                                                      ),
                                                      content: const Text(
                                                        "Some selected variants don’t have a selling price entered.\n\n"
                                                            "Would you like to use their listed prices instead?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(false),
                                                          child: const Text("Cancel"),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: AppColors.primaryColor,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          onPressed: () => Navigator.of(context).pop(true),
                                                          child: const Text("Continue", style: TextStyle(color: AppColors.white)),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                if (proceed != true) return;

                                                // Fill missing prices with default (listed) ones
                                                controller.fillMissingSellingPricesWithDefaults(
                                                  controller.searchProductVariantsList,
                                                  missingPriceIds,
                                                );
                                              }

                                              // Now all variants have prices, safe to proceed
                                              controller.cloneProductVariantApi();
                                            }
                                                : null,
                                          title: controller.cloneProductVariantLoading.value
                                              ? null // hide text
                                              : 'Publish',
                                          height: SizeConfig.size35,
                                          bgColor: controller.hasAnySelected()
                                              ? AppColors.primaryColor
                                              : Colors.grey,
                                          borderColor: controller.hasAnySelected()
                                              ? AppColors.primaryColor
                                              : Colors.grey,
                                          radius: 10.0,
                                            isLoading: controller.cloneProductVariantLoading.value
                                        )
                                      ],
                                    ),
                                  ),
              
                                  // Products
                                  // controller.searchProductsList.isEmpty
                                  //     ? Padding(
                                  //   padding: EdgeInsets.symmetric(
                                  //       vertical: SizeConfig.size20),
                                  //   child: CustomText(
                                  //       "No product Here, don’t worry you can create product manually ",
                                  //       fontSize: SizeConfig.small,
                                  //       fontWeight: FontWeight.w400,
                                  //       color: AppColors.secondaryTextColor,
                                  //       textAlign: TextAlign.center
                                  //   ),
                                  // )
                                  //     : Padding(
                                  //   padding: EdgeInsets.symmetric(
                                  //       vertical: SizeConfig.size20),
                                  //   child: Column(
                                  //     crossAxisAlignment: CrossAxisAlignment
                                  //         .start,
                                  //     children: [
                                  //       CustomText(
                                  //         "Products",
                                  //         fontSize: SizeConfig.small,
                                  //         fontWeight: FontWeight.w600,
                                  //         color: AppColors.secondaryTextColor,
                                  //       ),
                                  //       ListView.separated(
                                  //         itemCount: controller.searchProductsList
                                  //             .length,
                                  //         padding: EdgeInsets.symmetric(
                                  //             vertical: SizeConfig.size10),
                                  //         physics: NeverScrollableScrollPhysics(),
                                  //         shrinkWrap: true,
                                  //         itemBuilder: (context, index) {
                                  //           final products =
                                  //           controller.searchProductsList[index];
                                  //           return _buildProductItem(
                                  //               controller,
                                  //               products
                                  //           );
                                  //         },
                                  //         separatorBuilder: (BuildContext context,
                                  //             int index) {
                                  //           return CommonHorizontalDivider(
                                  //             color: AppColors.whiteE5,
                                  //           );
                                  //         },
                                  //       ),
                                  //       // PositiveCustomBtn(
                                  //       //   onTap: () {
                                  //       //
                                  //       //   },
                                  //       //   title: 'Next',
                                  //       //   iconPath: AppIconAssets.shareIcon,
                                  //       //   bgColor: AppColors.primaryColor,
                                  //       //   borderColor: AppColors.primaryColor,
                                  //       //   radius: 10.0,
                                  //       // )
                                  //     ],
                                  //   ),
                                  // ),

                                  controller.searchProductsList.isEmpty
                                      ? Padding(
                                    padding: EdgeInsets.only(
                                        top: SizeConfig.size20),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: CustomText(
                                                  "No product Here, don’t worry you can create product manually ",
                                                  fontSize: SizeConfig.small,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.secondaryTextColor,
                                                  textAlign: TextAlign.center
                                              ),
                                            ),
                                            Transform.rotate(
                                                angle: pi/2*3,
                                                child: Icon(Icons.keyboard_backspace_sharp, color: AppColors.primaryColor))
                                          ],
                                        ),
                                        SizedBox(height: SizeConfig.size15),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.primaryColor), // White background
                                            boxShadow: [AppShadows.textFieldShadow],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: GestureDetector(
                                              onTap: () {
                                                Get.toNamed(
                                                    RouteHelper.getAddProductViaAiStep1Route(),
                                                    arguments: {
                                                      ApiKeys.id: widget.id,
                                                      ApiKeys.providerType: widget.providerType
                                                    }
                                                );
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
                                                            "Generate Product With AI Within 1 Min. ",
                                                            fontSize: SizeConfig.medium15,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.mainTextColor,
                                                          ),
                                                          SizedBox(height: 10.0),
                                                          CustomText(
                                                            "Open the full manual form\nto add detailed information section by section.",
                                                            color: AppColors.secondaryTextColor,
                                                            fontSize: SizeConfig.medium,
                                                            fontWeight: FontWeight.w600,
                                                            fontFamily: AppConstants.OpenSans,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        )
                                      ],
                                    ),
                                  )
                                      : Padding(
                                    padding: EdgeInsets.only(
                                        top: SizeConfig.size20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        CustomText(
                                          "Products",
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                        ListView.separated(
                                          itemCount: controller.searchProductsList
                                              .length,
                                          padding: EdgeInsets.symmetric(
                                              vertical: SizeConfig.size10),
                                          physics: NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            final products =
                                            controller.searchProductsList[index];
                                            return _buildProductItem(
                                                controller,
                                                products
                                            );
                                          },
                                          separatorBuilder: (BuildContext context,
                                              int index) {
                                            return CommonHorizontalDivider(
                                              color: AppColors.whiteE5,
                                            );
                                          },
                                        ),
                                        // PositiveCustomBtn(
                                        //   onTap: () {
                                        //
                                        //   },
                                        //   title: 'Next',
                                        //   iconPath: AppIconAssets.shareIcon,
                                        //   bgColor: AppColors.primaryColor,
                                        //   borderColor: AppColors.primaryColor,
                                        //   radius: 10.0,
                                        // )
                                      ],
                                    ),
                                  ),



                                  controller.isLoadingMore ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ) : SizedBox.shrink()

                                ],
                              )

                            ]

                        ],
                      ),
                    ),
              
                    // SizedBox(height: SizeConfig.size10),
                    //
                    // (controller.searchProduct.isEmpty)
                    //     ? GestureDetector(
                    //     onTap: () {
                    //       Get.toNamed(
                    //         RouteHelper.getAddProductViaAiStep1Route(),
                    //         arguments: {
                    //           ApiKeys.id: widget.id,
                    //           ApiKeys.providerType: widget.providerType
                    //         }
                    //       );
                    //     },
                    //     child: Container(
                    //       padding: EdgeInsets.symmetric(
                    //           horizontal: SizeConfig.size15,
                    //           vertical: SizeConfig.size25),
                    //       decoration: BoxDecoration(
                    //           color: AppColors.white,
                    //           borderRadius: BorderRadius.circular(10)
                    //       ),
                    //       child: Row(
                    //         children: [
                    //           LocalAssets(imagePath: AppIconAssets
                    //               .pencilEditIcon), // Pencil icon
                    //           const SizedBox(width: 15.0),
                    //           Expanded(
                    //             child: Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 CustomText(
                    //                   "Generate Product With AI Within 1 Min. ",
                    //                   fontSize: SizeConfig.medium15,
                    //                   fontWeight: FontWeight.bold,
                    //                   color: AppColors.mainTextColor,
                    //                 ),
                    //                 SizedBox(height: 10.0),
                    //                 CustomText(
                    //                   "Open the full manual form\nto add detailed information section by section.",
                    //                   color: AppColors.secondaryTextColor,
                    //                   fontSize: SizeConfig.medium,
                    //                   fontWeight: FontWeight.w600,
                    //                   fontFamily: AppConstants.OpenSans,
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ))
                    //     : SizedBox(),
              
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildProductVariantItem(InventoryController controller,
      VariantData productVariants,) {
    return Obx(() {
      final isSelected = controller.isVariantSelected(
          productVariants.finalVariant.id);
      final sellingPrice = controller.getUpdatedPrice(
          productVariants.finalVariant.id);

      final productFullNameWithVariants = '${productVariants.productInformation
          .name} ${productVariants.finalVariant.attributes.entries.map((entry) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        if (key == 'color' && value is Map<String, dynamic>) {
          return value['color_name'] ?? '';
        } else if (value != null) {
          return value.toString();
        } else {
          return '';
        }
      }).where((attr) => attr.isNotEmpty).join(', ')}';

      return Container(
        margin: EdgeInsets.symmetric(vertical: SizeConfig.size16),
        padding: EdgeInsets.all(SizeConfig.size4),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => controller.toggleVariant(
                      productVariants.finalVariant.id
                    ),
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: EdgeInsets.only(top: 3.0),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryColor : AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryColor : AppColors
                            .greyE5,
                        width: 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: AppColors.white, size: 14)
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
                      child: CachedNetworkImage(
                        imageUrl: productVariants.finalVariant.mediaRelatedToVarient
                            .isNotEmpty ? productVariants.finalVariant
                            .mediaRelatedToVarient[0] : '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                        errorWidget: (context, url, error) =>
                            Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image),
                            ),
                      )
                  ),
                ),

                SizedBox(width: SizeConfig.size12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        productFullNameWithVariants,
                        fontSize: SizeConfig.small,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w400,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                    ],
                  ),
                ),

                SizedBox(width: SizeConfig.size12),

                // Action Icons
                InkWell(
                  onTap: () {
                    ProductPreviewArgs productPreviewArgs = mapProductDataToPreviewArgs(
                        productVariants);
                    Get.toNamed(
                      RouteHelper.getProductPreviewScreenRoute(),
                      arguments: {
                        ApiKeys.argProductData: productPreviewArgs,
                        ApiKeys.id: widget.id,
                        ApiKeys.providerType: widget.providerType
                      },
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: SizeConfig.size8),

            // Selling Price Input (only shown when selected)
            if (isSelected) ...[
              SizedBox(height: SizeConfig.size12),
              Row(
                children: [
                  CustomText(
                    'Selling price',
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CommonTextField(
                      onChange: (value) {
                        controller.updateSellingPrice(
                              productVariants.finalVariant.id,
                              value);
                      },
                      hintText: sellingPrice ??
                          productVariants.finalVariant.sellingPrice
                              .toString(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  if (isSelected)
                    GestureDetector(
                      onTap: () => controller.toggleVariant(
                          productVariants.finalVariant.id
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
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
          ],
        ),
      );
    });
  }

  Widget _buildProductItem(InventoryController controller,
      UnUsedProduct products) {
    final variants = products.variants;

    final Map<String, List<dynamic>> uniqueAttributes = {};

    final firstTwoKeys = <String>[];
    for (var v in variants) {
      for (var key in v.attributes.keys) {
        if (!firstTwoKeys.contains(key)) {
          firstTwoKeys.add(key);
        }
        if (firstTwoKeys.length == 2) break;
      }
      if (firstTwoKeys.length == 2) break;
    }

    for (var key in firstTwoKeys) {
      uniqueAttributes[key] = [];
      for (var v in variants) {
        final value = v.attributes[key];
        if (value != null) {
          if (key == 'color' && value is Map<String, dynamic>) {
            final colorMap = {
              "color_name": value["color_name"] ?? "",
              "color_code": value["color_code"] ?? ""
            };
            if (!uniqueAttributes[key]!.any((e) =>
            e is Map &&
                e["color_name"] == colorMap["color_name"] &&
                e["color_code"] == colorMap["color_code"])) {
              uniqueAttributes[key]!.add(colorMap);
            }
          } else {
            if (!uniqueAttributes[key]!.contains(value)) {
              uniqueAttributes[key]!.add(value);
            }
          }
        }
      }
    }


    return Container(
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child:
                CachedNetworkImage(
                  imageUrl: products.media.isNotEmpty ? products.media[0] : '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget: (context, url, error) =>
                      Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                )
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  products.name,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: SizeConfig.size2),

                CustomText(
                  products.brand,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: SizeConfig.size2),

                CustomText(
                  products.tags.map((tag) => tag.trim()).join(', '),
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w400,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: SizeConfig.size6),

                CustomBtn(
                  onTap: (){
                    final attributes = extractAttributes(products);
                    ProductController? productController;

                    if(Get.isRegistered<ProductController>()){
                      productController = Get.find();
                    }else{
                      productController = Get.put(ProductController());
                    }
                    productController?.selectedColors.value = attributes.selectedColors;
                    productController?.dynamicAttributes.value = attributes.dynamicAttributes.map(
                          (key, value) => MapEntry(key, value.obs),
                    );
                  },
                  height: 30,
                  title: 'Create Own Variants',
                  bgColor: AppColors.primaryColor,
                  borderColor: AppColors.primaryColor,
                  radius: 10.0,
                )

              ],
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Action Icons
          Column(
            children: [
              InkWell(
                onTap: () {
                  ProductPreviewArgs productPreviewArgs = mapUnUsedProductToPreviewArgs(
                      products);
                  Get.toNamed(
                    RouteHelper.getProductPreviewScreenRoute(),
                    arguments: {
                      ApiKeys.argProductData: productPreviewArgs,
                      ApiKeys.id: widget.id,
                      ApiKeys.providerType: widget.providerType
                    },
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ProductPreviewArgs mapProductDataToPreviewArgs(VariantData variantData) {
    ProductInformation productInformation = variantData.productInformation;
    FinalVariant finalVariant = variantData.finalVariant;

    final List<SelectedColor>? selectedColors = [];
    final Map<String, List<String>>? dynamicAttributes = {};

    if (productInformation.options != null &&
        productInformation.options!.asMap != null) {
      final optionMap = productInformation.options!.asMap!;

      optionMap.forEach((key, valueList) {
        if (valueList == null || (valueList is List && valueList.isEmpty))
          return;

        // Ensure valueList is List<dynamic>
        final values = (valueList is List) ? valueList : [valueList];

        if (key.toLowerCase() == 'color') {
          for (final colorItem in values) {
            if (colorItem is Map<String, dynamic>) {
              final colorCode = colorItem['color_code'] as String? ?? '#000000';
              final colorName = colorItem['name'] as String? ?? 'Unknown';
              final color = hexToColor(colorCode);

              selectedColors?.add(SelectedColor(color, colorName));
            }
          }
        } else {
          dynamicAttributes?.putIfAbsent(key, () => []);
          for (final val in values) {
            dynamicAttributes?[key]!.add(val.toString());
          }
        }
      });
    }

    String variantName = '${productInformation.name} ' +
        finalVariant.attributes.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          if (key.toLowerCase() == 'color' && value is Map<String, dynamic>) {
            return value['color_name'] ?? '';
          } else {
            return value.toString();
          }
        }).join(', ');

    return ProductPreviewArgs(
      productId: productInformation.id,
      media: finalVariant.mediaRelatedToVarient,
      name: variantName,
      description: productInformation.description,
      tags: productInformation.tags,
      features: productInformation.addProductFeatures.map((f) => f.title)
          .toList(),
      details: productInformation.addMoreDetails
          .map((d) => DetailPair(d.title, d.details))
          .toList(),
      sellingPrice: finalVariant.sellingPrice.toString(),
      MRPPrice: finalVariant.mrp.toString(),
      warranty: productInformation.productWarrenty,
      expiry: '',
      // set if available
      userGuide: productInformation.guideLine,
      selectedColors: selectedColors,
      dynamicAttributes: dynamicAttributes,
    );
  }

  ProductPreviewArgs mapUnUsedProductToPreviewArgs(UnUsedProduct product) {

    final attributes = extractAttributes(product);

    return ProductPreviewArgs(
      productId: product.id,
      media: product.media,
      name: product.name,
      description: product.description,
      tags: product.tags,
      features: product.addProductFeatures.map((f) => f.title).toList(),
      details: product.addMoreDetails.map((d) => DetailPair(d.title, d.details))
          .toList(),
      MRPPrice: product.mrpPerUnit.toString(),
      warranty: product.productWarrenty,
      expiry: '',
      userGuide: product.guideLine,
      selectedColors: attributes.selectedColors,
      dynamicAttributes: attributes.dynamicAttributes,
    );
  }

  ({
  List<SelectedColor> selectedColors,
  Map<String, List<String>> dynamicAttributes,
  }) extractAttributes(UnUsedProduct product) {
    final List<SelectedColor> selectedColors = [];
    final Map<String, List<String>> dynamicAttributes = {};

    if (product.options != null && product.options!.asMap != null) {
      final optionMap = product.options!.asMap!;
      optionMap.forEach((key, valueList) {
        if (valueList == null || (valueList is List && valueList.isEmpty)) {
          return;
        }

        final values = (valueList is List) ? valueList : [valueList];

        if (key.toLowerCase() == 'color') {
          for (final colorItem in values) {
            if (colorItem is Map<String, dynamic>) {
              final colorCode = colorItem['color_code'] as String? ?? '#000000';
              final colorName = colorItem['color_name'] as String? ?? 'Unknown';
              selectedColors.add(
                SelectedColor(hexToColor(colorCode), colorName),
              );
            }
          }
        } else {
          dynamicAttributes.putIfAbsent(key, () => []);
          for (final val in values) {
            if (val is Map<String, dynamic>) {
              final propertyValue = val['properties']?.toString() ?? val.toString();
              dynamicAttributes[key]!.add(propertyValue);
            }
          }
        }
      });
    }

    return (
    selectedColors: selectedColors,
    dynamicAttributes: dynamicAttributes,
    );
  }


}



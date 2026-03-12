import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/add_or_update_variant_bottom_sheet.dart';
import 'package:BlueEra/features/me/food/view/widget/edit_variant_price_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductVariantBottomSheet extends StatelessWidget {
  final CategoryFoodProductData product;
  final FoodServiceController controller;
  final bool isSnapSearch;

  final RxList<FoodVariants> tempSelectedVariants = <FoodVariants>[].obs;

  ProductVariantBottomSheet({
    super.key,
    required this.product,
    required this.controller,
    required this.isSnapSearch,
  }){
    // 2. Initialize with currently saved variants if any exist
    final saved = controller.selectedVariantsMap[product.id] ?? [];
    tempSelectedVariants.assignAll(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Obx(() {
          final String pId = product.id ?? "";
          debugPrint("BottomSheet Obx Rebuilding for Product: $pId"); // ADD THIS LOG

          final liveProduct = controller.categoryFoodProductDataList
              .firstWhereOrNull((p) => p.id == pId) ?? product;

          debugPrint("Live Product Price: ${liveProduct.variants?.firstOrNull?.baseSellingPrice}"); // LOG CHECK

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildProductInfo(liveProduct),
              const Divider(),
              _buildVariantList(liveProduct),
              _buildAddVariantButton(liveProduct),
              const SizedBox(height: 20),
              _buildPostButton(liveProduct),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText("All Variant", fontSize: 18, fontWeight: FontWeight.bold),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _buildProductInfo(CategoryFoodProductData liveProduct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: liveProduct.images?.firstOrNull ?? "",
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Center(
              child: LocalAssets(imagePath: AppIconAssets.foodIcon),
            ),
            placeholder: (context, url) => Container(color: Colors.grey[200]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                liveProduct.name,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ExpandableText(
                text: liveProduct.description ?? AppStrings.na,
                trimLines: 2,
                isReadMoreNewLine: false,
                expandMode: ExpandMode.dialog,
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppConstants.OpenSans,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.food_category,
                    imgColor: liveProduct.dietaryType?.toLowerCase() == "veg"
                        ? const Color(0xff008000)
                        : AppColors.red00,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: _tagWidget(
                      (liveProduct.cookingMethod ?? []).join(', '),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildVariantList(CategoryFoodProductData liveProduct) {
    final String pId = liveProduct.id ?? "";
    final displayVariants = liveProduct.variants ?? [];

    return Column(
      children: displayVariants.map((item) {
        bool isSelected = tempSelectedVariants.any((v) => v.id == item.id);

        return InkWell(
          onTap: () => _toggleTempSelection(item),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  activeColor: AppColors.primaryColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => _toggleTempSelection(item),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "${item.variantName} - ${item.quantityLabel}",
                        fontSize: 16,
                        color: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              "Selling-₹${item.baseSellingPrice}",
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriceDivider(),
                          const SizedBox(width: 8),
                          CustomText(
                            "₹${item.mrp}",
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildEditButton(item, isSelected, pId),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditButton(FoodVariants item, bool isSelected, String pId) {
    return IconButton(
      onPressed: () {
        if (isSelected) {
          controller.clearAllField();
          // No callback needed here anymore because Obx watches the controller list
          showEditVariantPriceSheet(
            vData: item,
            productId: pId,
            onUpdate: (newPrice, newMrp) {
              controller.updateLocalVariantPrice(
                pId,
                item.id ?? "",
                newPrice,
                newMrp,
              );
            },
          );
        } else {
          commonSnackBar(
            message: "Please select this variant first before editing.",
          );
        }
      },
      icon: LocalAssets(
          imagePath: AppIconAssets.editIcon,
          imgColor: AppColors.secondaryTextColor,
          height: 20.0,
          width: 20.0),
    );
  }

  Widget _buildAddVariantButton(CategoryFoodProductData liveProduct) {
    return InkWell(
      onTap: () {
        Get.back();
        controller.clearAllField();
        addOrVariantBottomSheet(
            // foodID: liveProduct.id ?? "",
            onAdd: (foodVariants){

            }
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.add, color: AppColors.primaryColor),
          CustomText("Add More Variant", color: AppColors.primaryColor),
        ],
      ),
    );
  }

  // 4. Local toggle logic
  void _toggleTempSelection(FoodVariants variant) {
    int index = tempSelectedVariants.indexWhere((v) => v.id == variant.id);
    if (index != -1) {
      tempSelectedVariants.removeAt(index);
    } else {
      tempSelectedVariants.add(variant);
    }
  }

  Widget _buildPostButton(CategoryFoodProductData liveProduct) {
    return PositiveCustomBtn(
      onTap: () {
        // if (tempSelectedVariants.isEmpty) {
        //   commonSnackBar(message: "Please select at least one variant.");
        //   return;
        // }

        // 5. COMMIT: Save the temporary selection to the Global Controller Map
        controller.selectedVariantsMap[liveProduct.id!] = List.from(tempSelectedVariants);
        controller.selectedVariantsMap.refresh();

        Get.back();
        commonSnackBar(message: "Variants saved to selection.");
      },
      title: "Save Selection", // Changed for clarity
    );
  }

  Widget _buildPriceDivider() {
    return Container(height: 15, width: 1.5, color: Colors.grey.shade300);
  }

  Widget _tagWidget(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteE5),
        borderRadius: BorderRadius.circular(4),
      ),
      child:
      CustomText(label, fontSize: 10, color: AppColors.secondaryTextColor),
    );
  }
}
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/add_or_update_variant_bottom_sheet.dart';
import 'package:BlueEra/features/me/food/view/widget/edit_variant_price_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddSingleFoodProductScreen extends StatefulWidget {
  final String foodProductId;
  final int? createMissingProductIndex;

  AddSingleFoodProductScreen({
    super.key,
    required this.foodProductId,
    this.createMissingProductIndex,
  });

  @override
  State<AddSingleFoodProductScreen> createState() => _AddSingleFoodProductScreenState();
}

class _AddSingleFoodProductScreenState extends State<AddSingleFoodProductScreen> {
  var vc = Get.find<FoodServiceController>();
  final RxList<FoodVariants> selectedVariants = <FoodVariants>[].obs;

  @override
  initState(){
    super.initState();
    vc.getSingleFoodProductApi(FoodId: widget.foodProductId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Add Product",
      ),
      bottomNavigationBar: Obx((){
        if(vc.getSingleFoodProductResponse.value.status == Status.COMPLETE){
          return _buildBottomActionSection();
        }
        return const SizedBox.shrink();
      }),
      body: SafeArea(
        child: Obx(() {
          if(vc.getSingleFoodProductResponse.value.status == Status.INITIAL){
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if(vc.getSingleFoodProductResponse.value.status == Status.ERROR){
            return Center(
              child: CustomText(
                'Something went wrong. unable to fetch data'
              ),
            );
          }

          final liveProduct = vc.singleFoodProductData.value;

          if(liveProduct == null)
            return Center(
            child: CustomText(
                'Something went wrong. unable to fetch data'
            ),
          );;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
            ),
            child: CustomFormCard(
              padding: EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(liveProduct),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                  CustomText("Select Variants", fontSize: 16, fontWeight: FontWeight.bold),
                  const SizedBox(height: 15),
                  _buildVariantList(liveProduct),
                  _buildAddVariantButton(liveProduct),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- UI Build Methods ---
  Widget _buildProductInfo(CategoryFoodProductData liveProduct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: liveProduct.images?.firstOrNull ?? "",
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[100],
              child: LocalAssets(imagePath: AppIconAssets.foodIcon),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(liveProduct.name, fontSize: 16, fontWeight: FontWeight.bold),
              const SizedBox(height: 5),
              ExpandableText(
                text: liveProduct.description ?? "No description available",
                trimLines: 2,
                style: TextStyle(color: AppColors.secondaryTextColor, fontSize: 13),
              ),
              const SizedBox(height: 10),
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
    final displayVariants = liveProduct.variants ?? [];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayVariants.length,
      itemBuilder: (context, index) {
        final item = displayVariants[index];
        return Obx(() {
          bool isSelected = selectedVariants.any((v) => v.id == item.id);
          return _variantItemCard(item, isSelected, liveProduct.id ?? "");
        });
      },
    );
  }

  Widget _variantItemCard(FoodVariants item, bool isSelected, String pId) {
    return InkWell(
      onTap: () => _toggleSelection(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
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
              onChanged: (_) => _toggleSelection(item),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText("${item.variantName} (${item.quantityLabel})", fontWeight: FontWeight.w500),
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
                      Container(height: 15, width: 1.5, color: Colors.grey.shade300),
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
  }

  Widget _buildEditButton(FoodVariants item, bool isSelected, String pId) {
    return IconButton(
      onPressed: () {
        if (isSelected) {
          showEditVariantPriceSheet(
            vData: item,
            productId: pId,
            onUpdate: (newPrice, newMrp) {
              // 1. Update the local variant data in the liveProduct
              item.baseSellingPrice = newPrice;
              item.mrp = newMrp;

              // 2. Refresh the selectedVariants list
              // This forces the Obx to redraw the prices in the UI
              vc.singleFoodProductData.refresh();

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


  Widget _buildBottomActionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: PositiveCustomBtn(
          title: "Post Now",
          onTap: () => vc.addSingleProductToInventory(
              productId: widget.foodProductId,
              selectedVariants: selectedVariants,
              createMissingProductIndex: widget.createMissingProductIndex
          ),
        ),
      ),
    );
  }

  // --- Logic Methods ---
  void _toggleSelection(FoodVariants variant) {
    int index = selectedVariants.indexWhere((v) => v.id == variant.id);
    if (index != -1) {
      selectedVariants.removeAt(index);
    } else {
      selectedVariants.add(variant);
    }
  }

  Widget _buildAddVariantButton(CategoryFoodProductData liveProduct) {
    return InkWell(
      onTap: () {
        vc.clearAllField();
        addOrVariantBottomSheet(
            foodID: liveProduct.id ?? '',
            onAdd: (foodVariants){
              vc.singleFoodProductData.value?.variants?.add(foodVariants);
              vc.singleFoodProductData.refresh();

              // 3. Optional: Automatically select the new variant
              selectedVariants.add(foodVariants);
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

  Widget _tagWidget(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      child: CustomText(label, fontSize: 11, color: AppColors.secondaryTextColor),
    );
  }
}
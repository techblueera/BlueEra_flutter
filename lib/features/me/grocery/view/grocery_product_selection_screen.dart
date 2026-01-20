import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/grocery/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_variant_controller.dart';
import 'package:BlueEra/features/me/grocery/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/model/dummy_category_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/view/food_entry_ai_screen.dart';
import 'package:BlueEra/features/me/grocery/view/widget/add_variant_bottom_sheet.dart';
import 'package:BlueEra/features/me/grocery/view/widget/custom_add_button_widget.dart';
import 'package:BlueEra/features/me/grocery/view/widget/edit_variant_price_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../common/food/model/food_category_res_model.dart';

import '../controller/product_controller.dart';

class ProductSelectionScreen extends StatefulWidget {
  final FoodCategoryData foodCategoryData;

  ProductSelectionScreen({super.key, required this.foodCategoryData});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final controller = Get.find<FoodServiceController>();

  @override
  void initState() {
    controller.selectedCategoryId.value=widget.foodCategoryData.children?.firstOrNull?.id ?? "";
    // TODO: implement initState...
    controller.getFoodByCategoryIDController(
        categoryId: widget.foodCategoryData.children?.firstOrNull?.id ?? "");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.arrow_back_ios, color: Colors.black)),
        actions: [
          InkWell(
            onTap: () {
              Get.to(FoodEntryScreen(foodCategoryData: widget.foodCategoryData,));
            },
            child: Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.add,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  CustomText(
                    "Add Own Food Items ",
                    color: AppColors.white,
                  )
                ],
              ),
            ),
          )
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // 1. Left Side: Category List
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListView.builder(
              itemCount: widget.foodCategoryData.children?.length,
              itemBuilder: (context, index) {
                final cat = widget.foodCategoryData.children?[index];
                bool isSelected =
                    controller.selectedCategoryId.value == cat?.id;
                return GestureDetector(
                  onTap: () {
                    controller.changeCategory(cat?.id ?? "");
                    controller.getFoodByCategoryIDController(
                        categoryId: cat?.id ?? "");
                    setState(() {});
                  },
                  child: Container(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: CachedNetworkImageProvider(""),
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          cat?.name,
                          fontSize: 12,
                          textAlign: TextAlign.center,
                          color: isSelected
                              ? Colors.blue
                              : AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Right Side: Product List
          Expanded(
            child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.categoryFoodProductDataList.length,
                  itemBuilder: (context, index) {
                    final product =
                        controller.categoryFoodProductDataList[index];
                    return _buildProductCard(context, product);
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, CategoryFoodProductData product) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.images?.firstOrNull ?? "",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Center(
                      child: LocalAssets(imagePath: AppIconAssets.foodIcon),
                    ),
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        product.name,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CustomText(
                        product.dietaryType,
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.food_category,
                            imgColor:
                                product.dietaryType?.toLowerCase() == "non-veg"
                                    ? AppColors.red00
                                    : Color(0xff008000),
                          ),
                          const SizedBox(width: 5),
                          _tagWidget(
                              (product.cookingMethod ?? ""), Colors.grey),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
            // const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showVariantSheet(context, product),
                  child: CustomText(
                    "0 Variants",
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CustomAddButton(
                  onTap: () {
                    _showVariantSheet(context, product);
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _tagWidget(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.whiteE5),
          borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          LocalAssets(imagePath: AppIconAssets.boiled),
          SizedBox(
            width: 5,
          ),
          CustomText(label, color: AppColors.secondaryTextColor, fontSize: 10),
        ],
      ),
    );
  }

  // 3. Bottom Sheet Implementation
  void _showVariantSheet(
      BuildContext context, CategoryFoodProductData product) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText("All Variant",
                      fontSize: 18, fontWeight: FontWeight.bold),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back()),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.images?.first ?? "",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          product.name,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        CustomText(
                          product.dietaryType,
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            LocalAssets(
                              imagePath: AppIconAssets.food_category,
                              imgColor:
                                  (false) ? Color(0xff008000) : AppColors.red00,
                            ),
                            const SizedBox(width: 5),
                            _tagWidget((""), Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),

              const Divider(),
              /*  ...product.variants
                      ?.map((v) => ListTile(
                            title: CustomText(v.name, fontSize: 15),
                            subtitle: CustomText("${v.weight} | ₹${v.price}"),
                            trailing: InkWell(
                                onTap: () {
                                  Get.back();
                                  final vc =
                                      Get.put(GroceryVariantController());
                                  vc.clearAllField();
                                  showEditVariantPriceSheet(v);
                                },
                                child:
                                    const Icon(Icons.edit_outlined, size: 20)),
                          ))
                      .toList() ??
                  [],*/
              // const SizedBox(height: 20),
              InkWell(
                  onTap: () {
                    Get.back();

                    final vc = Get.find<FoodServiceController>();
                    vc.clearAllField();

                    showVariantBottomSheet();
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.primaryColor,
                      ),
                      CustomText(
                        "Add More Variant",
                        color: AppColors.primaryColor,
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
              PositiveCustomBtn(onTap: () {}, title: "Post Product"),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

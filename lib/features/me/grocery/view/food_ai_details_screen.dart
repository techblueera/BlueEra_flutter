import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/grocery/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_variant_controller.dart';
import 'package:BlueEra/features/me/grocery/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/grocery/view/widget/add_variant_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodGenAiResModel foodData;

  const FoodDetailScreen({
    super.key,
    required this.foodData,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  FoodGenAiData product = FoodGenAiData();
  final vc = Get.find<FoodServiceController>();

  @override
  void initState() {
    // TODO: implement initState

    product = widget.foodData.data ?? FoodGenAiData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Food Via AI',
      ),
      bottomNavigationBar: Obx(() {
        return SafeArea(
            child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0, right: 20, left: 20),
          child: CustomBtn(
              isValidate: vc.variantList.isNotEmpty,
              onTap: vc.variantList.isNotEmpty?() {
                vc.createFoodProductViaAiApi(foodData: product);
              }:null,
              title: AppStrings.postNow),
        ));
      }),
      body: CommonCardWidget(
        padding: 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive horizontal padding
            double horizontalPadding = constraints.maxWidth > 600 ? 100 : 16;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Add Food Within 1 Min Via Al",
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  _buildImageSection(),
                  _buildSection(
                      "Upload Food Images", vc.foodImages,context),

                  const SizedBox(height: 20),
                  _buildInfoCard("Product Name", product.name ?? ""),
                  const SizedBox(height: 12),
                  _buildInfoCard("Food Description", product.description ?? "",
                      isExpandable: true),
                  const SizedBox(height: 12),
                  _buildCategorySection(),
                  const SizedBox(height: 12),
                  _buildIngredientsSection(),
                  const SizedBox(height: 12),
                  _buildInfoCard("Shelf Life", product.shelfLife ?? ""),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        "Add Food Variant",
                        fontWeight: FontWeight.bold,
                      ),
                      InkWell(
                          onTap: () {
                            // Get.back();
                            vc.clearAllField();

                            showVariantBottomSheet();
                            // showAddVariantSheet();
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
                                "Add Variant",
                                color: AppColors.primaryColor,
                              ),
                            ],
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Obx(() => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vc.variantList.length,
                        itemBuilder: (context, index) {
                          final item = vc.variantList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title: Name - Quantity
                                      CustomText(
                                        "${item['variantName']} - ${item['quantityLabel']} ",
                                        fontSize: 16,
                                        color: AppColors.secondaryTextColor,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Prices: Selling | MRP
                                      Row(
                                        children: [
                                          Flexible(
                                            child: CustomText(
                                              "Selling-₹${item['baseSellingPrice']}",
                                              fontSize: 15,
                                              color:
                                                  AppColors.secondaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            height: 15,
                                            width: 1.5,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(width: 8),
                                          CustomText(
                                            "₹${item['mrp']}",
                                            fontSize: 15,
                                            color: AppColors.secondaryTextColor,
                                            decoration: TextDecoration
                                                .lineThrough, // Strikethrough
                                            decorationColor: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Actions Column
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        vc.prepareEdit(index);
                                        showVariantBottomSheet();
                                      },
                                      child: LocalAssets(
                                        imagePath: AppIconAssets.editIcon,
                                        imgColor: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () => vc.deleteVariant(index),
                                      child: const Icon(Icons.delete_outline,
                                          size: 22, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ))
                ],
              ),
            );
          },
        ),
      ),
    );

  }
  Widget _buildSection(String title, RxList<XFile> imageList, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
              Text("Min-2 Images",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          SizedBox(height: 12),
          Obx(() =>
              Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final path = await CommonImageUploadTile.pickImage(context: context);
                        if (path != null) imageList.add(XFile(path));
                      },
                      // onTap: () => _showPickerOptions(imageList),
                      child: Container(
                        height: 80,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: index < imageList.length
                            ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(imageList[index].path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 80,

                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    vc.removeImage(
                                        index, imageList),
                                child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 12, color: Colors.white)),
                              ),
                            )
                          ],
                        )
                            : Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
                  );
                }),
              )),
        ],
      ),
    );
  }


  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const CustomText("Food Image", fontWeight: FontWeight.normal),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: "https://example.com/idli_image.jpg",
            // Replace with real URL
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) =>
                const Icon(Icons.fastfood, size: 50),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content,
      {bool isExpandable = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title,
                  fontWeight: FontWeight.bold, color: AppColors.mainTextColor),
              // const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          CustomText(
            content,
            color: AppColors.secondaryTextColor,
            maxLines: isExpandable ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText("Selected Category",
                  fontWeight: FontWeight.bold),
              // const Icon(Icons.edit_outlined, size: 18, color: se),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _buildRadioPlaceholder("Food Item", true)),
              Expanded(
                  child:
                      _buildRadioPlaceholder(product.dietaryType ?? "", true)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _buildRadioPlaceholder(
                      product.cookingMethod ?? "", true)),
              Expanded(child: _buildRadioPlaceholder("Breakfast", true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Key Ingredients", fontWeight: FontWeight.bold),
          const SizedBox(height: 12),
          CustomText(product.ingredients!.join(", "),
              color: AppColors.secondaryTextColor, height: 1.5),
        ],
      ),
    );
  }

  Widget _buildRadioPlaceholder(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: AppColors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          CustomText(label, fontSize: 12),
        ],
      ),
    );
  }
}

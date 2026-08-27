import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_entry_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/add_or_update_variant_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

class FoodAiDetailScreen extends StatefulWidget {
  final FoodGenAiResModel foodData;
  final int? createMissingProductIndex;

  const FoodAiDetailScreen({
    super.key,
    required this.foodData,
    this.createMissingProductIndex,
  });

  @override
  State<FoodAiDetailScreen> createState() => _FoodAiDetailScreenState();
}

class _FoodAiDetailScreenState extends State<FoodAiDetailScreen> {
  FoodGenAiData product = FoodGenAiData();
  final vc = Get.find<FoodServiceController>();
  final foodEntryController = Get.find<FoodEntryController>();

  @override
  void initState() {
    super.initState();
    product = widget.foodData.data ?? FoodGenAiData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vc.variantList.clear();
      vc.variantList.addAll(product.variants ?? []);
      syncImagesToUploadList();
    });

  }

  void syncImagesToUploadList() {
    vc.foodImages.clear();

    // Add the mandatory first image if it exists
    if (foodEntryController.foodSearchImages[0] != null) {
      vc.foodImages.add(XFile(foodEntryController.foodSearchImages[0]!.path));
    }

    // You can also manage additional images directly in foodImages
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.foodAddFoodViaAi.tr,
      ),
      bottomNavigationBar: Obx(() {
        return SafeArea(
            child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0, right: 20, left: 20),
          child: CustomBtn(
              isValidate: vc.variantList.isNotEmpty,
              isLoading: vc.isPosting.value,
              onTap: vc.variantList.isNotEmpty?() {
                vc.createFoodProductViaAiApi(
                    foodData: product,
                    createMissingProductIndex: widget.createMissingProductIndex
                );
              }:null,
              title: AppStrings.postNow),
        ));
      }),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive horizontal padding

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 15),
            child: CustomFormCard(
              padding: EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.foodAddFoodWithinMinViaAi.tr,
                    fontWeight: FontWeight.bold,
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor
                  ),
                  _buildImageSection(context),
                  const SizedBox(height: 16),
                  _buildInfoCard(AppStrings.foodProductNameLabel.tr, product.name ?? ""),
                  const SizedBox(height: 12),
                  _buildInfoCard(AppStrings.foodDescriptionLabel.tr, product.description ?? "",
                      isExpandable: true),
                  const SizedBox(height: 12),
                  _buildCategorySection(),
                  const SizedBox(height: 12),
                  _buildIngredientsSection(),
                  const SizedBox(height: 12),
                  _buildInfoCard(AppStrings.foodShelfLifeLabel.tr, product.shelfLife ?? ""),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.foodAddVariantLabel.tr,
                        fontWeight: FontWeight.bold,
                      ),
                      InkWell(
                          onTap: () {
                            vc.clearAllField();

                            addOrVariantBottomSheet(
                                onAdd: (foodVariants){
                                  vc.variantList.add(foodVariants);
                                }
                            );
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
                                vc.variantList.isNotEmpty ? AppStrings.foodAddMoreVariant.tr : AppStrings.foodAddVariantLabel.tr,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildVariantsList()
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        CustomText(AppStrings.foodUploadProductImages.tr, fontWeight: FontWeight.normal),
        const SizedBox(height: 8),
        Row(
          children: [
            // Box 1: Mandatory (Index 0)
            Expanded(
              child: Obx(() {
                final XFile? xFile = vc.foodImages[0];
                final File? file = xFile != null ? File(xFile.path) : null;

                return _buildBaseImageBox(
                  file: file,
                  onTap: null, // Passing null disables the tap interaction
                  showRemove: false,
                );
              }),
            ),

            const SizedBox(width: 12),

            // Box 2: Optional (Index 1)
            Expanded(
              child: Obx(() {
                final XFile? xFile = vc.foodImages.length > 1 ? vc.foodImages[1] : null;
                final File? file = xFile != null ? File(xFile.path) : null;

                return _buildBaseImageBox(
                  file: file,
                  onTap: () => vc.pickSecondImage(context),
                  showRemove: file != null,
                  onRemove: () => vc.removeSecondImage(),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBaseImageBox({
    File? file,
    VoidCallback? onTap, // Nullable to disable interaction
    bool showRemove = false,
    VoidCallback? onRemove,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : Image.asset(AppImageAssets.foodDummyImage, fit: BoxFit.cover),
                  ),
                ),
                // Only show camera icon if interaction is allowed (onTap != null)
                Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: file == null ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: file == null
                              ? Icon(Icons.camera_alt_outlined, color: Colors.white, size: 30)
                              : null
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showRemove)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVariantsList(){
    return Obx(() => ListView.builder(
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
                      "${item.variantName} - ${item.quantityLabel} ",
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
                            "Selling: ₹${item.baseSellingPrice}",
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
                        // Label upright, figure struck through.
                        CustomText(
                          "MRP: ",
                          fontSize: 15,
                          color: AppColors.secondaryTextColor,
                        ),
                        CustomText(
                          "₹${item.mrp}",
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
                      addOrVariantBottomSheet(
                          editingIndex: index,
                          onAdd: (foodVariants){
                            vc.variantList[index] = foodVariants;
                          }
                      );
                    },
                    child: LocalAssets(
                      imagePath: AppIconAssets.editIcon,
                      imgColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => vc.variantList.removeAt(index),
                    child: const Icon(Icons.delete_outline,
                        size: 22, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ));
  }

  Widget _buildInfoCard(String title, String content,
      {bool isExpandable = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
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
          CommonHorizontalDivider(
              height: 0.5,
              color: AppColors.greyE5
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
              CustomText(AppStrings.foodSelectedCategoryLabel.tr,
                  fontWeight: FontWeight.bold),
              // const Icon(Icons.edit_outlined, size: 18, color: se),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _buildRadioPlaceholder(AppStrings.foodItemLabel.tr, true)),
              Expanded(
                  child:
                      _buildRadioPlaceholder(product.dietaryType ?? "", true)),
            ],
          ),

          // Row(
          //   children: [
          //     Expanded(
          //         child: _buildRadioPlaceholder(
          //             product.cookingMethod ?? "", true)),
          //     Expanded(child: _buildRadioPlaceholder("Breakfast", true)),
          //   ],
          // ),

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
          CustomText(AppStrings.foodKeyIngredientsLabel.tr, fontWeight: FontWeight.bold),
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


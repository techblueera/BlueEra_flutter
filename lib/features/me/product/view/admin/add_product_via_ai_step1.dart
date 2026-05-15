import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddProductViaAiStep1 extends StatefulWidget {
  final String id;
  final ProviderType providerType;
  AddProductViaAiStep1({super.key, required this.id, required this.providerType});

  @override
  State<AddProductViaAiStep1> createState() => _AddProductViaAiStep1State();
}

class _AddProductViaAiStep1State extends State<AddProductViaAiStep1> {
  final ProductController controller = getOrPut(() => ProductController());

  final List<CollapsibleGridModel> _homeMadeCategories =
      homeMadeProductsCategories;

  bool get _isBusiness => widget.providerType == ProviderType.business;

  @override
  void initState() {
    super.initState();
    if (_isBusiness) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.productsNestedCategoryList.isEmpty) {
          controller.fetchProductsNestedCategory();
        }
      });
    }
  }

  @override
  void dispose() {
    deleteIfRegistered<ProductController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
          title: AppStrings.addProductViaAI,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: CustomFormCard(
            child: Form(
              key: this.controller.formKey,
              child: Obx(()=> AbsorbPointer(
                absorbing: this.controller.isLoading.value,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.addProductWithin1Min,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CustomText(
                        AppStrings.uploadProductImages,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black28,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      SizedBox(
                        height: SizeConfig.size80,
                        child: GetBuilder<ProductController>(
                          builder: (controller) {
                            return GridView.builder(
                              scrollDirection: Axis.horizontal,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: controller.maxStep1Images.value,
                              itemBuilder: (context, index) {
                                final hasImage = index < controller.step1Images.length;

                                return GestureDetector(
                                  onTap: () {
                                    if (!hasImage) controller.pickImagesStep1(context);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.whiteFE,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.greyE5),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (hasImage)
                                          Image.file(File(controller.step1Images[index]), fit: BoxFit.cover)
                                        else
                                          const Center(
                                            child: Icon(Icons.photo_outlined, color: Colors.grey, size: 28),
                                          ),
                                        if (hasImage)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => controller.removeImageStep1(index),
                                              child: Container(
                                                width: 22,
                                                height: 22,
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      SizedBox(height: SizeConfig.paddingXSL),

                      /// Product Name
                      CommonTextField(
                          textEditController: this.controller.productNameStep1Controller,
                          title: AppStrings.productNameBrand,
                          hintText: AppStrings.egTShirtMobile,
                          validator: ValidationMethod().validateProductName,
                          showLabel: true,
                          maxLength: 30,
                          isCounterVisible: true
                      ),

                      SizedBox(height: SizeConfig.paddingXSL),

                      /// Product Category (Nested)
                      CustomText(
                        AppStrings.category.tr,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      _buildCategorySection(),

                      SizedBox(height: SizeConfig.paddingXSL),

                      /// Product Description
                      CommonTextField(
                          textEditController: this.controller.productDescriptionStep1Controller,
                          title: AppStrings.productDescSpec,
                          hintText: AppStrings.hintProductDesc,
                          maxLine: 4,
                          validator: ValidationMethod().validateProductDescription,
                          maxLength: 100,
                          isCounterVisible: true
                      ),

                      SizedBox(height: SizeConfig.paddingL),

                      CustomBtn(
                        title: this.controller.isLoading.value
                          ? null // hide text
                          : AppStrings.generate,
                        onTap: ()=> this.controller.onGenerate(
                            this.controller,
                            widget.id,
                            widget.providerType,

                        ),
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                        height: SizeConfig.size40,
                        radius: 10.0,
                        isLoading: this.controller.isLoading.value
                      ),

                    ]
                ),
              )),
            )
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return _isBusiness
        ? _buildNestedCategorySection()
        : _buildUserCategoryGrid();
  }

  Widget _buildUserCategoryGrid() {
    return Obx(() {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: _homeMadeCategories.length,
        itemBuilder: (_, i) {
          final category = _homeMadeCategories[i];
          final isSelected =
              controller.selectedHomeMadeCategory.value?.slugId == category.slugId;
          return CommonServiceCard<CollapsibleGridModel>(
            service: category,
            getName: (item) => item.name,
            getIcon: (item) => item.icon ?? '',
            isSelected: isSelected,
            onTap: (item) {
              if (isSelected) {
                controller.selectedHomeMadeCategory.value = null;
              } else {
                controller.selectedHomeMadeCategory.value = item;
              }
            },
          );
        },
      );
    });
  }

  Widget _buildNestedCategorySection() {
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Obx(() {
          bool hasSelection = controller.selectedProductLevel0.value != null;

          return Row(
            children: [
              Expanded(
                child: hasSelection
                    ? _buildSelectionPath()
                    : CustomText("Choose Category", color: Colors.grey[400]),
              ),
              const Icon(
                Icons.keyboard_arrow_down_outlined,
                size: 18,
                color: AppColors.secondaryTextColor,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSelectionPath() {
    List<String> path = [
      if (controller.selectedProductLevel0.value != null) controller.selectedProductLevel0.value!.name!,
      if (controller.selectedProductLevel1.value != null) controller.selectedProductLevel1.value!.name!,
      if (controller.selectedProductLevel2.value != null) controller.selectedProductLevel2.value!.name!,
      if (controller.selectedProductLevel3.value != null) controller.selectedProductLevel3.value!.name!,
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: path.asMap().entries.map((entry) {
        bool isLast = entry.key == path.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLast ? AppColors.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomText(
                entry.value,
                fontSize: 11,
                color: isLast ? AppColors.primaryColor : AppColors.secondaryTextColor,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isLast)
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        );
      }).toList(),
    );
  }

  void _showCategoryPicker() {
    RxList<dynamic> currentDisplayList = <dynamic>[].obs;
    currentDisplayList.assignAll(controller.productsNestedCategoryList);

    Get.bottomSheet(
      isScrollControlled: true,
      Obx(() => Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInteractiveSheetHeader(currentDisplayList),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: currentDisplayList.length,
                itemBuilder: (context, index) {
                  final ProductNestedCategoryResponse item = currentDisplayList[index];
                  final bool hasChildren = (item.children != null && item.children!.isNotEmpty);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                    title: CustomText(item.name ?? ""),
                    trailing: hasChildren ? const Icon(Icons.chevron_right, size: 18) : null,
                    onTap: () {
                      if (item.level == 0) {
                        controller.selectedProductLevel0.value = item;
                        controller.selectedProductLevel1.value = null;
                        controller.selectedProductLevel2.value = null;
                        controller.selectedProductLevel3.value = null;
                        if (hasChildren) {
                          currentDisplayList.assignAll(item.children!);
                        } else {
                          Get.back();
                        }
                      } else if (item.level == 1) {
                        controller.selectedProductLevel1.value = item;
                        controller.selectedProductLevel2.value = null;
                        controller.selectedProductLevel3.value = null;
                        if (hasChildren) {
                          currentDisplayList.assignAll(item.children!);
                        } else {
                          Get.back();
                        }
                      } else if (item.level == 2) {
                        controller.selectedProductLevel2.value = item;
                        controller.selectedProductLevel3.value = null;
                        if (hasChildren) {
                          currentDisplayList.assignAll(item.children!);
                        } else {
                          Get.back();
                        }
                      } else {
                        controller.selectedProductLevel3.value = item;
                        Get.back();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildInteractiveSheetHeader(RxList<dynamic> currentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText("Select Category", fontWeight: FontWeight.bold, fontSize: 16),
            IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
          ],
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _pathStep("All", () {
              controller.selectedProductLevel0.value = null;
              controller.selectedProductLevel1.value = null;
              controller.selectedProductLevel2.value = null;
              controller.selectedProductLevel3.value = null;
              currentList.assignAll(controller.productsNestedCategoryList);
            }, controller.selectedProductLevel0.value == null),

            if (controller.selectedProductLevel0.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel0.value!.name!, () {
                controller.selectedProductLevel1.value = null;
                controller.selectedProductLevel2.value = null;
                controller.selectedProductLevel3.value = null;
                currentList.assignAll(controller.selectedProductLevel0.value!.children!);
              }, controller.selectedProductLevel1.value == null),
            ],

            if (controller.selectedProductLevel1.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel1.value!.name!, () {
                controller.selectedProductLevel2.value = null;
                controller.selectedProductLevel3.value = null;
                currentList.assignAll(controller.selectedProductLevel1.value!.children!);
              }, controller.selectedProductLevel2.value == null),
            ],

            if (controller.selectedProductLevel2.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel2.value!.name!, () {
                controller.selectedProductLevel3.value = null;
                currentList.assignAll(controller.selectedProductLevel2.value!.children!);
              }, controller.selectedProductLevel3.value == null),
            ],

            if (controller.selectedProductLevel3.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedProductLevel3.value!.name!, () {}, true),
            ],
          ],
        ),
        const SizedBox(height: 5),
        CommonHorizontalDivider(
          color: AppColors.greyE5,
          height: 0.5,
        ),
      ],
    );
  }

  Widget _pathStep(String label, VoidCallback onTap, bool isCurrent) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: CustomText(
          label,
          fontSize: 12,
          color: isCurrent ? AppColors.primaryColor : AppColors.secondaryTextColor,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

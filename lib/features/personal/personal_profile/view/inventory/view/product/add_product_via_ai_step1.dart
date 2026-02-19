import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/category_bottom_sheet.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
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
  final ProductController controller = Get.put(ProductController());

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

                      /// category 1
                      CustomText(
                        '${AppStrings.category.tr} 1',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Obx(() => CommonDropdownDialog<Map<String, String>>(
                        title: '${AppStrings.category.tr} 1',
                        hintText: "Eg. Home Appliances",
                        items: controller.categoryDropdownList,
                        selectedValue: controller.selectedProductCategory.value,
                        displayValue: (value) => (value['display']??'').replaceAll('\n', ' '),
                        onChanged: (value) {
                          if(controller.selectedProductCategory.value == value) return;

                          controller.selectedProductCategory.value = value;
                          print('product category-- ${controller.selectedProductCategory.value}');

                        },
                      )),

                      SizedBox(height: SizeConfig.paddingXSL),

                      /// category 2
                      CustomText(
                        '${AppStrings.category.tr} 2',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Obx(() => InkWell(
                        onTap: () async {
                          await showCategoryBottomSheet(context);
                        },
                        child: Container(
                          width: SizeConfig.screenWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                            vertical: SizeConfig.size10,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              boxShadow: [AppShadows.textFieldShadow],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.greyE5,
                              )),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              controller.selectedCategory.value!=null
                                  ? CustomText(
                                  controller.selectedCategory.value,
                                  fontSize: SizeConfig.large,
                                  color: AppColors.black
                              ) : CustomText(
                                AppStrings.selectCategory,
                                color: AppColors.grey9A,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.large,
                              ),
                              const Icon(Icons.keyboard_arrow_down_outlined,
                                  color: AppColors.grey9A)
                            ],
                          )
                        ),
                      )),

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
}

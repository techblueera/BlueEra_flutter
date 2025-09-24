import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddProductViaAiStep1 extends StatefulWidget {

  AddProductViaAiStep1({super.key});

  @override
  State<AddProductViaAiStep1> createState() => _AddProductViaAiStep1State();
}

class _AddProductViaAiStep1State extends State<AddProductViaAiStep1> {
  final AddProductViaAiController addProductViaAiController = Get.put(AddProductViaAiController());


  @override
  void dispose() {
    Get.delete<AddProductViaAiController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
          title: "Add Product Via AI",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: CustomFormCard(
            child: Form(
              key: addProductViaAiController.formKey,
              child: Obx(()=> AbsorbPointer(
                absorbing: addProductViaAiController.isLoading.value,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'add product within 1 min via aI',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size20),
                      CustomText(
                        'Upload product Images',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black28,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      SizedBox(
                        height: SizeConfig.size80,
                        child: GetBuilder<AddProductViaAiController>(
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

                      SizedBox(height: SizeConfig.size10),

                      /// Product Name
                      CommonTextField(
                          textEditController: addProductViaAiController.productNameController,
                          hintText: 'e.g. t-shirt/mobile',
                          title: "Product Name & Brand",
                          validator: ValidationMethod().validateProductName,
                          showLabel: true,
                          maxLength: 30,
                          isCounterVisible: true
                      ),

                      SizedBox(height: SizeConfig.size10),

                      /// Product Description
                      CommonTextField(
                          textEditController: addProductViaAiController.productDescriptionController,
                          hintText:
                          "e.g. t-shirt/mens wear/shirt/cotton mix silk/casual wear",
                          maxLine: 5,
                          title: 'Product Description / Specification',
                          validator: ValidationMethod().validateProductDescription,
                          maxLength: 360,
                          isCounterVisible: true
                      ),

                      SizedBox(height: SizeConfig.size20),

                      CustomBtn(
                        title: addProductViaAiController.isLoading.value
                          ? null // hide text
                          : 'Generate',
                        onTap: addProductViaAiController.onGenerate,
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                        height: SizeConfig.size40,
                        radius: 10.0,
                        isLoading: addProductViaAiController.isLoading.value
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

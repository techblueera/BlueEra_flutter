import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void addOrVariantBottomSheet({
  String? foodID,
  required Function(FoodVariants) onAdd, // Add this callback
  int? editingIndex
}) {
  final vc = Get.find<FoodServiceController>();

  Get.bottomSheet(
    isScrollControlled: true,
    GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CustomText(
                      editingIndex != null ? AppStrings.foodUpdateVariantLabel.tr : AppStrings.foodAddVariantLabel.tr,
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor
                  ),
                  Spacer(),
                  IconButton(
                      onPressed: ()=> Get.back(),
                      icon: Icon(Icons.close, color: AppColors.mainTextColor)
                  )
                ],
              ),
              const SizedBox(height: 8),
              CommonTextField(
                textEditController: vc.nameController,
                hintText: AppStrings.foodHintHalfPlate.tr,
                title: AppStrings.foodVariantNameLabel.tr,
                textInputAction: TextInputAction.next,
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.quantityController,
                hintText: AppStrings.foodHint100GM.tr,
                title: AppStrings.foodQuantityLabel.tr,
                textInputAction: TextInputAction.next,
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.mrpController,
                hintText: AppStrings.foodHint200.tr,
                title: AppStrings.foodMrpLabel.tr,
                keyBoardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.priceController,
                hintText: AppStrings.foodHint180.tr,
                title: AppStrings.foodSellingPriceLabel.tr,
                keyBoardType: TextInputType.number,
                // Last field — dismiss the keyboard instead of advancing.
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChange: (val) => vc.validate(),
              ),
              // Inline reason the form is invalid (e.g. selling price > MRP).
              Obx(() {
                final error = vc.variantFormError.value;
                if (error == null || error.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(
                      error,
                      color: AppColors.red,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() => PositiveCustomBtn(
                  onTap: vc.isFormValid.value
                      ? () async {

                    // Create the model locally from text controllers
                    final newVariant = FoodVariants(
                      variantName: vc.nameController.text.trim(),
                      quantityLabel: vc.quantityController.text.trim(),
                      mrp: int.tryParse(vc.mrpController.text) ?? 0,
                      baseSellingPrice: int.tryParse(vc.priceController.text) ?? 0,
                      isDefault: vc.variantList.isEmpty, // First one is default
                    );

                    // APi call cause , adding variants in existing product
                    log('food id -- $foodID');
                    if(foodID!=null){
                      String? vId = await vc.addOrUpdateVariant(
                          foodId: foodID,
                          newVariant: newVariant
                      ); // Logic to save/update

                      if(vId==null) return;
                      newVariant.id = vId;
                      // Push the new variant into the Source-of-Truth list so
                      // the product card count and variant sheet update live.
                      vc.addLocalVariant(foodID, newVariant);
                      onAdd(newVariant); // Trigger the callback
                    }

                    vc.clearAllField();
                    Get.back(); // Close sheet

                  }
                      : null,
                  // Grey out the button while the form is invalid so the
                  // disabled state is visible, not just non-tappable.
                  bgColor: vc.isFormValid.value
                      ? AppColors.primaryColor
                      : AppColors.greyB4,
                  borderColor: vc.isFormValid.value
                      ? AppColors.primaryColor
                      : AppColors.greyB4,
                  title: (editingIndex!=null) ? AppStrings.update.tr : AppStrings.submit.tr,
                )),
              ),
              SizedBox(height: MediaQuery.of(Get.context!).viewInsets.bottom + 20),
            ],
          ),
        ),
      ),
    ),
  );
}


// void addVariantBottomSheet({String? foodID}) {
//   final vc = Get.find<FoodServiceController>();
//
//   Get.bottomSheet(
//     isScrollControlled: true,
//     GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ... keep your title row and CommonTextFields here ...
//               const SizedBox(height: 15),
//               CommonTextField(
//                 textEditController: vc.nameController,
//                 hintText: "E.g. Half Plate",
//                 title: "Variant Name",
//                 inputFormatters: [LengthLimitingTextInputFormatter(20)],
//                 // Manually trigger validation on change
//                 onChange: (val) => vc.validate(),
//               ),
//               const SizedBox(height: 12),
//               CommonTextField(
//                 textEditController: vc.quantityController,
//                 hintText: "E.g. 100GM",
//                 title: "Quantity",
//                 inputFormatters: [LengthLimitingTextInputFormatter(30)],
//                 onChange: (val) => vc.validate(),
//               ),
//               const SizedBox(height: 12),
//               CommonTextField(
//                 textEditController: vc.mrpController,
//                 hintText: "E.g. ₹1,999",
//                 title: "MRP",
//                 keyBoardType: TextInputType.number,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(10)
//                 ],
//                 onChange: (val) => vc.validate(),
//               ),
//               const SizedBox(height: 12),
//               CommonTextField(
//                 textEditController: vc.priceController,
//                 hintText: "E.g. ₹1,999",
//                 title: "Selling Price",
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(10)
//                 ],
//                 keyBoardType: TextInputType.number,
//                 onChange: (val) => vc.validate(),
//               ),
//               const SizedBox(height: 20),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Obx(() => TextButton(
//                       onPressed: vc.isFormValid.value
//                           ? () {
//                               vc.addOrUpdateVariant(
//                                 foodId: foodID ?? "",
//                               ); // Logic to save/update
//                               Get.back(); // Close sheet
//                             }
//                           : null,
//                       child:
//                           CustomText(vc.editingIndex != null ? "Update" : "Submit"),
//                     )),
//               ),
//               SizedBox(height: MediaQuery.of(Get.context!).viewInsets.bottom),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

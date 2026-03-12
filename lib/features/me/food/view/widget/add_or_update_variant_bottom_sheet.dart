import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void addOrVariantBottomSheet({
  // String? foodID,
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
                      editingIndex != null ? "Update Variant" : "Add Variant",
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
                hintText: "E.g. Half Plate",
                title: "Variant Name",
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.quantityController,
                hintText: "E.g. 100GM",
                title: "Quantity",
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.mrpController,
                hintText: "E.g. 200",
                title: "MRP",
                keyBoardType: TextInputType.number,
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.priceController,
                hintText: "E.g. 180",
                title: "Selling Price",
                keyBoardType: TextInputType.number,
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() => PositiveCustomBtn(
                  onTap: vc.isFormValid.value
                      ? () {
                    // Create the model locally from text controllers
                    final newVariant = FoodVariants(
                      variantName: vc.nameController.text,
                      quantityLabel: vc.quantityController.text,
                      mrp: int.tryParse(vc.mrpController.text) ?? 0,
                      baseSellingPrice: int.tryParse(vc.priceController.text) ?? 0,
                      isDefault: vc.variantList.isEmpty, // First one is default
                    );

                    onAdd(newVariant); // Trigger the callback

                    // vc.clearAllField();

                    Get.back(); // Close sheet
                  }
                      : null,
                  title: (editingIndex!=null) ? "Update" : "Submit",
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

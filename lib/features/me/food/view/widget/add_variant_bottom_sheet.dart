import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';


void showVariantBottomSheet({String? foodID}) {
  final vc = Get.find<FoodServiceController>();

  Get.bottomSheet(
    isScrollControlled: true,
    GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ... keep your title row and CommonTextFields here ...
              const SizedBox(height: 15),
              CommonTextField(
                textEditController: vc.nameController,
                hintText: "E.g. Half Plate",
                title: "Variant Name",
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                // Manually trigger validation on change
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.quantityController,
                hintText: "E.g. 100GM",
                title: "Quantity",
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.mrpController,
                hintText: "E.g. ₹1,999",
                title: "MRP",
                keyBoardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)
                ],
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.priceController,
                hintText: "E.g. ₹1,999",
                title: "Selling Price",
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)
                ],
                keyBoardType: TextInputType.number,
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() => TextButton(
                      onPressed: vc.isFormValid.value
                          ? () {
                              vc.addOrUpdateVariant(
                                foodId: foodID ?? "",
                              ); // Logic to save/update
                              Get.back(); // Close sheet
                            }
                          : null,
                      child:
                          CustomText(vc.editingIndex != null ? "Update" : "Submit"),
                    )),
              ),
              SizedBox(height: MediaQuery.of(Get.context!).viewInsets.bottom),
            ],
          ),
        ),
      ),
    ),
  );
}

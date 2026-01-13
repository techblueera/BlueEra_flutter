import 'package:BlueEra/features/me/grocery/controller/grocery_variant_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void showAddVariantSheet() {
  // Use Get.put but don't delete it manually in a .then() block
  final vc = Get.find<GroceryVariantController>();

  Get.bottomSheet(
    isScrollControlled: true,
    // Wrap in a GestureDetector to dismiss keyboard when tapping outside
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText("Add More Variant",
                      fontSize: 18, fontWeight: FontWeight.bold),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Get.back();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              CommonTextField(
                textEditController: vc.nameController,
                hintText: "E.g. Half Plate",
                title: "Variant Name",
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20)
                ],
                // Manually trigger validation on change
                onChange: (val) => vc.validate(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: vc.quantityController,
                hintText: "E.g. 100GM",
                title: "Quantity",
                inputFormatters: [
                  LengthLimitingTextInputFormatter(30)
                ],
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
                              // IMPORTANT: Unfocus keyboard before closing
                              FocusManager.instance.primaryFocus?.unfocus();

                              // Small delay ensures keyboard starts closing
                              // before controller is destroyed
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                print("Data: ${vc.nameController.text}");
                                Get.back();
                              });
                            }
                          : null,
                      child: CustomText(
                        "Submit",
                        fontSize: 16,
                        color: vc.isFormValid.value ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
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

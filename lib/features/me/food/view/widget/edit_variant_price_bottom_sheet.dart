import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void showEditVariantPriceSheet({
  required FoodVariants vData,
  required String productId,
  required Function(int newPrice, int newMrp) onUpdate,
}) {
  final vc = Get.find<FoodServiceController>();
  vc.mrpController.text = vData.mrp.toString();
  vc.priceController.text = vData.baseSellingPrice.toString();
  vc.validateVariantPrice();
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(vData.variantName,
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
                const SizedBox(height: 10),
                CommonTextField(
                  textEditController: vc.mrpController,
                  hintText: AppStrings.foodHintRupees.tr,
                  title: AppStrings.foodMrpLabel.tr,
                  keyBoardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10)
                  ],
                  onChange: (val) => vc.validateVariantPrice(),
                ),
                const SizedBox(height: 10),
                CommonTextField(
                  textEditController: vc.priceController,
                  hintText: AppStrings.foodHintRupees.tr,
                  title: AppStrings.foodSellingPriceLabel.tr,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10)
                  ],
                  keyBoardType: TextInputType.number,
                  onChange: (val) => vc.validateVariantPrice(),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => TextButton(
                        onPressed: vc.isFormValid.value
                            ? () {
                                // IMPORTANT: Unfocus keyboard before closing
                                FocusManager.instance.primaryFocus?.unfocus();
          
                                // before controller is destroyed
                                Future.delayed(const Duration(milliseconds: 100),
                                    () {

                                      int parsedPrice = int.tryParse(vc.priceController.text) ?? 0;
                                      int parsedMrp = int.tryParse(vc.mrpController.text) ?? 0;

                                      onUpdate(parsedPrice, parsedMrp);

                                  Get.back();
                                });
                              }
                            : null,
                        child: CustomText(
                          AppStrings.submit.tr,
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
    ),
  );
}

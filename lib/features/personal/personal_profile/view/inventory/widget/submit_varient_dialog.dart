import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class SubmitVariantDialog extends StatefulWidget {
  final AddProductViaAiController controller;

  const SubmitVariantDialog({
    super.key,
    required this.controller,
  });

  @override
  State<SubmitVariantDialog> createState() => _SubmitVariantDialogState();
}

class _SubmitVariantDialogState extends State<SubmitVariantDialog> {

  final productMrpController = TextEditingController();
  final productPriceController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Discount percentage
  RxDouble discountPercent = 0.0.obs;
  late String productFullName;

  // Method to calculate discount dynamically
  void calculateDiscount() {
    final mrp = num.tryParse(
        productMrpController.text.replaceAll('₹', '').trim());
    final price = num.tryParse(
        productPriceController.text.replaceAll('₹', '').trim());

    if (mrp != null && mrp > 0 && price != null) {
      discountPercent.value = ((mrp - price) / mrp) * 100;
    } else {
      discountPercent.value = 0;
    }
  }

  @override
  void initState() {
    productFullName = '${widget.controller.productNameController.text} ${widget.controller.selectedVariantValues.values.join(', ')}';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
        ),
        child: Form(
          key: formKey,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                     Expanded(
                       child: CustomText(
                         productFullName,
                        fontWeight: FontWeight.w600,
                         fontSize: SizeConfig.medium,
                         color: AppColors.mainTextColor,
                         ),
                     ),
                     SizedBox(width: SizeConfig.size5),
                     IconButton(
                       onPressed: () => Get.back(),
                       icon: const Icon(
                         Icons.close_rounded,
                         color: AppColors.mainTextColor,
                       ),
                     ),
                   ],
                 ),
                SizedBox(height: SizeConfig.size5),
                CommonTextField(
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  title: 'Product MRP',
                  hintText: "E.g. - ₹1500",
                  textEditController: productMrpController,
                  keyBoardType: TextInputType.number,
                  validator: (value) => ValidationMethod().validatePrice(
                      productPriceController.text, productMrpController.text),
                  onChange: (_) => calculateDiscount(),
                ),
                SizedBox(height: SizeConfig.size10),
                CommonTextField(
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  title: 'Product Price',
                  hintText: 'E.g. - ₹800',
                  textEditController: productPriceController,
                  keyBoardType: TextInputType.number,
                  validator: (value) => ValidationMethod().validatePrice(
                      productPriceController.text, productMrpController.text),
                   onChange: (_) => calculateDiscount(),
                ),
                SizedBox(height: SizeConfig.size10),
                Obx(() =>
                     CustomText(
                  discountPercent.value > 0
                      ? "Discount: ${discountPercent.value.toStringAsFixed(2)}%"
                      : "Discount: 0%",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                 )
                ),
                SizedBox(height: SizeConfig.size16),
                CustomBtn(
                  title: 'Publish',
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      widget.controller.addProductsInListing(
                          productListing: ProductListing(
                              image: widget.controller.step2Images,
                              name: productFullName,
                              price: productPriceController.text.trim(),
                              mrp: productMrpController.text.trim(),
                              discount: discountPercent.value.toStringAsFixed(2)
                          )
                      );
                      Get.back();
                    }
                  },
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                  height: 45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


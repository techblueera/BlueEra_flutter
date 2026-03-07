import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryVariantDialog extends StatefulWidget {
  final String title;
  final Function(String, String, String, String) onSubmit;
  final bool isAddGroceryProductNewVariantLoading;

  const GroceryVariantDialog({
    super.key,
    required this.title,
    required this.onSubmit,
    required this.isAddGroceryProductNewVariantLoading,
  });

  @override
  State<GroceryVariantDialog> createState() => _GroceryVariantDialogState();
}

class _GroceryVariantDialogState extends State<GroceryVariantDialog> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController sellingController = TextEditingController();

  bool isFormValid = false;

  @override
  void initState() {
    super.initState();
    quantityController.addListener(_validateForm);
    unitController.addListener(_validateForm);
    mrpController.addListener(_validateForm);
    sellingController.addListener(_validateForm);
  }

  void _validateForm() {
    final valid = quantityController.text.isNotEmpty &&
        unitController.text.isNotEmpty &&
        mrpController.text.isNotEmpty &&
        sellingController.text.isNotEmpty;

    setState(() {
      isFormValid = valid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isAddGroceryProductNewVariantLoading;

    return WillPopScope(
      onWillPop: () async => !isLoading, // disable back button
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: AbsorbPointer(
          absorbing: isLoading, // disable whole UI when loading
          child: Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                bottom: SizeConfig.size15,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        size: SizeConfig.size20,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(child: _input("Quantity", "E.g. 100GM", quantityController, isNumber: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _input("Unit", "GM / KG / PCS", unitController, isCapitalize: true)),
                  ],
                ),

                const SizedBox(height: 12),

                _input("MRP", "E.g. ₹1,999", mrpController, isNumber: true),
                const SizedBox(height: 12),

                _input("Selling Price", "E.g. ₹1,999", sellingController, isNumber: true),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: (isFormValid && !isLoading)
                        ? () {
                      widget.onSubmit(
                        quantityController.text,
                        unitController.text,
                        mrpController.text,
                        sellingController.text,
                      );
                    }
                        : null,
                    child: CustomText(
                      "Submit",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: (isFormValid && !isLoading)
                          ? AppColors.primaryColor
                          : Colors.grey,
                    ),
                  ),
                ),

                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController controller,
      {bool isNumber = false, bool isCapitalize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 6),
        CommonTextField(
          textEditController: controller,
          keyBoardType: isNumber ? TextInputType.number : TextInputType.text,
          hintText: hint,
          isCapitalize: isCapitalize,
        ),
      ],
    );
  }
}

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditGroceryVarientDialog extends StatefulWidget {
  final String title;
  final String mrp;
  final String selling;
  final Function(String, String) onSubmit;
  const EditGroceryVarientDialog({
    super.key,
    required this.title,
    required this.mrp,
    required this.selling,
    required this.onSubmit,
  });

  @override
  State<EditGroceryVarientDialog> createState() => _EditGroceryVarientDialogState();
}

class _EditGroceryVarientDialogState extends State<EditGroceryVarientDialog> {
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController sellingController = TextEditingController();

  bool isFormValid = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    mrpController.text = widget.mrp;
    sellingController.text = widget.selling;
    mrpController.addListener(_validateForm);
    sellingController.addListener(_validateForm);
    _validateForm();
  }

  void _validateForm() {
    final mrpText = mrpController.text.trim();
    final sellingText = sellingController.text.trim();

    // 1. Basic Empty Check
    if (mrpText.isEmpty || sellingText.isEmpty) {
      _updateValidity(false, null);
      return;
    }

    final mrp = double.tryParse(mrpText);
    final selling = double.tryParse(sellingText);

    if (mrp == null || selling == null) {
      _updateValidity(false, AppStrings.groceryViewEnterValidNumbers.tr);
    } else if (mrp <= 0) {
      _updateValidity(false, AppStrings.groceryViewMrpMustBeGtZero.tr);
    } else if (selling > mrp) {
      _updateValidity(false, AppStrings.groceryViewSellingCannotExceedMrp.tr);
    } else {
      _updateValidity(true, null);
    }
  }

  void _updateValidity(bool valid, String? message) {
    if (isFormValid != valid || errorMessage != message) {
      setState(() {
        isFormValid = valid;
        errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

            _input(AppStrings.groceryViewMrp.tr, AppStrings.groceryViewPriceHint.tr, mrpController, isNumber: true),
            const SizedBox(height: 12),

            _input(AppStrings.groceryViewSellingPrice.tr, AppStrings.groceryViewPriceHint.tr, sellingController, isNumber: true),
            const SizedBox(height: 20),

            // Error Message Display
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: CustomText(
                  errorMessage!,
                  fontSize: SizeConfig.extraSmall,
                  color: Colors.red,
                ),
              ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap:  () {
                  widget.onSubmit(
                    mrpController.text,
                    sellingController.text
                  );
                },
                child: CustomText(
                  AppStrings.groceryViewSubmit.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: (isFormValid)
                      ? AppColors.primaryColor
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
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

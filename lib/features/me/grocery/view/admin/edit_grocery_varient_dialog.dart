import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
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

  @override
  void dispose() {
    mrpController.dispose();
    sellingController.dispose();
    super.dispose();
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
    return Container(
      padding: EdgeInsets.only(
        left: SizeConfig.size20,
        right: SizeConfig.size20,
        top: SizeConfig.size10,
        // Both fields are numeric, so the keyboard is up the whole time this is
        // open — viewInsets lifts the sheet clear of it.
        bottom: MediaQuery.of(context).viewInsets.bottom + SizeConfig.size20,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle replaces the old ✕ — a modal sheet already dismisses
            // on swipe-down and on barrier tap.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: SizeConfig.size12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            CustomText(
              widget.title,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size15),

            _input(AppStrings.groceryViewMrp.tr, AppStrings.groceryViewPriceHint.tr, mrpController, isNumber: true),
            SizedBox(height: SizeConfig.size12),

            _input(AppStrings.groceryViewSellingPrice.tr, AppStrings.groceryViewPriceHint.tr, sellingController, isNumber: true),

            if (errorMessage != null) ...[
              SizedBox(height: SizeConfig.size8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomText(
                        errorMessage!,
                        fontSize: SizeConfig.extraSmall,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: SizeConfig.size20),

            // Gated on isFormValid. The old Submit was a GestureDetector that
            // greyed its label but still fired onTap, so an invalid price
            // (selling > MRP) went through despite the validator.
            CustomBtn(
              onTap: isFormValid
                  ? () => widget.onSubmit(
                        mrpController.text.trim(),
                        sellingController.text.trim(),
                      )
                  : null,
              isValidate: isFormValid,
              radius: SizeConfig.size10,
              title: AppStrings.groceryViewSubmit.tr,
            ),
            SizedBox(height: SizeConfig.size10),
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

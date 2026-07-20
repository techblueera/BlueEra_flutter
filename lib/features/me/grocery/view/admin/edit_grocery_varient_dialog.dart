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
  State<EditGroceryVarientDialog> createState() =>
      _EditGroceryVarientDialogState();
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
    // Own the Material ancestor rather than relying on the presenter to supply
    // one. showModalBottomSheet provides it, showDialog does not, and the
    // TextFields below assert without it — so make the widget self-sufficient
    // for any call site. `transparency` keeps the Container's own white
    // surface and rounded corners intact.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        // Slide the whole sheet up above the keyboard. Previously viewInsets
        // was added to the Container's bottom *padding*, which grew the sheet
        // by the keyboard's height instead of moving it — with the numeric
        // keyboard always up, that swelled a short form to near-full-screen.
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          // Content-sized (Column is mainAxisSize.min); the cap only matters
          // on very small screens, where the form scrolls instead of clipping.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: EdgeInsets.only(
            left: SizeConfig.size20,
            right: SizeConfig.size20,
            top: SizeConfig.size10,
            // Clear of the gesture bar when no keyboard is up.
            bottom: MediaQuery.of(context).padding.bottom + SizeConfig.size20,
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
                // Drag handle plus an explicit ✕ — swipe-down and barrier tap
                // both dismiss, but the close affordance shouldn't be implicit.
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: SizeConfig.size8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.close,
                        size: SizeConfig.size20,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size15),

                _input(AppStrings.groceryViewMrp.tr,
                    AppStrings.groceryViewPriceHint.tr, mrpController,
                    isNumber: true),
                SizedBox(height: SizeConfig.size12),

                _input(AppStrings.groceryViewSellingPrice.tr,
                    AppStrings.groceryViewPriceHint.tr, sellingController,
                    isNumber: true),

                if (errorMessage != null) ...[
                  SizedBox(height: SizeConfig.size8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: Colors.red),
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

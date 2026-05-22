import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class EditMedicalVarientDialog extends StatefulWidget {
  final String title;
  final String mrp;
  final String selling;
  final Function(String, String) onSubmit;
  const EditMedicalVarientDialog({
    super.key,
    required this.title,
    required this.mrp,
    required this.selling,
    required this.onSubmit,
  });

  @override
  State<EditMedicalVarientDialog> createState() => _EditMedicalVarientDialogState();
}

class _EditMedicalVarientDialogState extends State<EditMedicalVarientDialog> {
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

    if (mrpText.isEmpty || sellingText.isEmpty) {
      _updateValidity(false, null);
      return;
    }

    final mrp = double.tryParse(mrpText);
    final selling = double.tryParse(sellingText);

    if (mrp == null || selling == null) {
      _updateValidity(false, AppStrings.medicalEnterValidNumbers.tr);
    } else if (mrp <= 0) {
      _updateValidity(false, AppStrings.medicalMrpMustBeGreaterThanZero.tr);
    } else if (selling > mrp) {
      _updateValidity(false, AppStrings.medicalSellingPriceCannotExceedMrp.tr);
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
            // Drag handle
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

            _input(AppStrings.medicalMrpRupee.tr, AppStrings.medicalEgRupeeMrp.tr, mrpController, isNumber: true),
            SizedBox(height: SizeConfig.size12),

            _input(AppStrings.medicalSellingPriceRupee.tr, AppStrings.medicalEgRupeeSelling.tr, sellingController, isNumber: true),

            if (errorMessage != null) ...[
              SizedBox(height: SizeConfig.size8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: Colors.red),
                    SizedBox(width: 6),
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

            CustomBtn(
              onTap: isFormValid
                  ? () => widget.onSubmit(
                        mrpController.text.trim(),
                        sellingController.text.trim(),
                      )
                  : null,
              isValidate: isFormValid,
              radius: SizeConfig.size10,
              title: AppStrings.medicalUpdatePrice.tr,
            ),
            SizedBox(height: SizeConfig.size10),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController controller,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 6),
        CommonTextField(
          textEditController: controller,
          keyBoardType: isNumber ? TextInputType.number : TextInputType.text,
          hintText: hint,
        ),
      ],
    );
  }
}

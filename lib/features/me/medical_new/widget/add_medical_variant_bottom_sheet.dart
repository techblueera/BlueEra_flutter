import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class AddMedicalVariantBottomSheet extends StatefulWidget {
  final String title;
  final Function(String weight, String unit, String mrp, String sellingPrice)
      onSubmit;
  final bool isLoading;

  const AddMedicalVariantBottomSheet({
    super.key,
    required this.title,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<AddMedicalVariantBottomSheet> createState() =>
      _AddMedicalVariantBottomSheetState();
}

class _AddMedicalVariantBottomSheetState
    extends State<AddMedicalVariantBottomSheet> {
  final weightController = TextEditingController();
  final unitController = TextEditingController();
  final mrpController = TextEditingController();
  final sellingController = TextEditingController();

  bool isFormValid = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    weightController.addListener(_validateForm);
    unitController.addListener(_validateForm);
    mrpController.addListener(_validateForm);
    sellingController.addListener(_validateForm);
  }

  @override
  void dispose() {
    weightController.dispose();
    unitController.dispose();
    mrpController.dispose();
    sellingController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final weight = weightController.text.trim();
    final unit = unitController.text.trim();
    final mrpText = mrpController.text.trim();
    final sellingText = sellingController.text.trim();

    if (weight.isEmpty || unit.isEmpty || mrpText.isEmpty || sellingText.isEmpty) {
      _updateValidity(false, null);
      return;
    }

    final mrp = double.tryParse(mrpText);
    final selling = double.tryParse(sellingText);

    if (mrp == null || selling == null) {
      _updateValidity(false, 'Enter valid numbers for price');
    } else if (mrp <= 0) {
      _updateValidity(false, 'MRP must be greater than 0');
    } else if (selling <= 0) {
      _updateValidity(false, 'Selling price must be greater than 0');
    } else if (selling > mrp) {
      _updateValidity(false, 'Selling price cannot exceed MRP');
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

            // Title
            CustomText(
              widget.title,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size15),

            // Weight + Unit row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Weight / Quantity',
                    hint: 'E.g. 100',
                    controller: weightController,
                    isNumber: true,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    label: 'Unit',
                    hint: 'GM / KG / PCS',
                    controller: unitController,
                    isCapitalize: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),

            // MRP
            _buildField(
              label: 'MRP (₹)',
              hint: 'E.g. 1999',
              controller: mrpController,
              isNumber: true,
            ),
            SizedBox(height: SizeConfig.size12),

            // Selling Price
            _buildField(
              label: 'Selling Price (₹)',
              hint: 'E.g. 1499',
              controller: sellingController,
              isNumber: true,
            ),

            // Error
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

            // Submit
            CustomBtn(
              onTap: isFormValid && !widget.isLoading
                  ? () => widget.onSubmit(
                        weightController.text.trim(),
                        unitController.text.trim(),
                        mrpController.text.trim(),
                        sellingController.text.trim(),
                      )
                  : null,
              isValidate: isFormValid,
              radius: SizeConfig.size10,
              title: 'Add Variant',
              isLoading: widget.isLoading,
            ),
            SizedBox(height: SizeConfig.size10),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    bool isCapitalize = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: 6),
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

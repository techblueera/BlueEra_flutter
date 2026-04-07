import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class EditMedicalInventoryBottomSheet extends StatefulWidget {
  final String title;
  final String currentMrp;
  final String currentSellingPrice;
  final String currentQuantity;
  final Function(String mrp, String sellingPrice, String quantity) onSubmit;
  final bool isLoading;

  const EditMedicalInventoryBottomSheet({
    super.key,
    required this.title,
    required this.currentMrp,
    required this.currentSellingPrice,
    required this.currentQuantity,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<EditMedicalInventoryBottomSheet> createState() =>
      _EditMedicalInventoryBottomSheetState();
}

class _EditMedicalInventoryBottomSheetState
    extends State<EditMedicalInventoryBottomSheet> {
  late final TextEditingController mrpController;
  late final TextEditingController sellingController;
  late final TextEditingController quantityController;

  bool isFormValid = false;
  String? errorMessage;

  late final double _originalMrp;
  late final double _originalSellingPrice;

  @override
  void initState() {
    super.initState();
    mrpController = TextEditingController(text: widget.currentMrp);
    sellingController = TextEditingController(text: widget.currentSellingPrice);
    quantityController = TextEditingController(text: widget.currentQuantity);

    _originalMrp = double.tryParse(widget.currentMrp) ?? 0;
    _originalSellingPrice = double.tryParse(widget.currentSellingPrice) ?? 0;

    mrpController.addListener(_validateForm);
    sellingController.addListener(_validateForm);
    quantityController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    mrpController.dispose();
    sellingController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final mrpText = mrpController.text.trim();
    final sellingText = sellingController.text.trim();
    final qtyText = quantityController.text.trim();

    if (mrpText.isEmpty || sellingText.isEmpty || qtyText.isEmpty) {
      _updateValidity(false, null);
      return;
    }

    final mrp = double.tryParse(mrpText);
    final selling = double.tryParse(sellingText);
    final qty = int.tryParse(qtyText);

    if (mrp == null || selling == null || qty == null) {
      _updateValidity(false, AppStrings.medicalEnterValidNumbers.tr);
      return;
    }

    if (mrp <= 0) {
      _updateValidity(false, AppStrings.medicalMrpMustBeGreaterThanZero.tr);
    } else if (mrp > _originalMrp && _originalMrp > 0) {
      _updateValidity(false, '${AppStrings.medicalMrpCannotBeIncreasedPrefix.tr} ₹${_originalMrp.toStringAsFixed(2)})');
    } else if (selling > mrp) {
      _updateValidity(false, AppStrings.medicalSellingPriceCannotExceedMrp.tr);
    } else if (selling > _originalSellingPrice && _originalSellingPrice > 0) {
      _updateValidity(false, '${AppStrings.medicalSellingPriceCannotBeIncreasedPrefix.tr} ₹${_originalSellingPrice.toStringAsFixed(2)})');
    } else if (qty < 0) {
      _updateValidity(false, AppStrings.medicalQuantityCannotBeNegative.tr);
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
            SizedBox(height: 4),
            CustomText(
              AppStrings.medicalPriceCanOnlyBeDecreased,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size15),

            // MRP field
            _buildField(
              label: AppStrings.medicalMrpRupee.tr,
              hint: AppStrings.medicalEnterMrp.tr,
              controller: mrpController,
              isNumber: true,
              originalValue: _originalMrp > 0 ? '${AppStrings.medicalCurrentPrefix.tr} ₹${_originalMrp.toStringAsFixed(2)}' : null,
            ),
            SizedBox(height: SizeConfig.size12),

            // Selling Price field
            _buildField(
              label: AppStrings.medicalSellingPriceRupee.tr,
              hint: AppStrings.medicalEnterSellingPrice.tr,
              controller: sellingController,
              isNumber: true,
              originalValue: _originalSellingPrice > 0 ? '${AppStrings.medicalCurrentPrefix.tr} ₹${_originalSellingPrice.toStringAsFixed(2)}' : null,
            ),
            SizedBox(height: SizeConfig.size12),

            // Quantity field
            _buildField(
              label: AppStrings.medicalQuantity.tr,
              hint: AppStrings.medicalEnterQuantity.tr,
              controller: quantityController,
              isNumber: true,
            ),
            SizedBox(height: SizeConfig.size6),

            // Error message
            if (errorMessage != null)
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

            SizedBox(height: SizeConfig.size20),

            // Submit button
            CustomBtn(
              onTap: isFormValid && !widget.isLoading
                  ? () => widget.onSubmit(
                        mrpController.text.trim(),
                        sellingController.text.trim(),
                        quantityController.text.trim(),
                      )
                  : null,
              isValidate: isFormValid,
              radius: SizeConfig.size10,
              title: AppStrings.medicalUpdateInventory.tr,
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
    String? originalValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
            ),
            if (originalValue != null) ...[
              Spacer(),
              CustomText(
                originalValue,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ],
        ),
        SizedBox(height: 6),
        CommonTextField(
          textEditController: controller,
          keyBoardType: isNumber ? TextInputType.number : TextInputType.text,
          hintText: hint,
        ),
      ],
    );
  }
}
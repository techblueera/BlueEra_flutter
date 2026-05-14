import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Row showing a label on the left and a compact [Switch] on the right.
///
/// [value] is reactive; toggling the switch updates it and invokes
/// [onChanged] so the parent controller can re-validate the form.
class LabSwitchRow extends StatelessWidget {
  final String title;
  final RxBool value;
  final VoidCallback? onChanged;

  const LabSwitchRow({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(title, color: AppColors.mainTextColor),
          ),
          Transform.scale(
            scale: 0.8,
            child: Obx(
              () => Switch(
                value: value.value,
                onChanged: (val) {
                  value.value = val;
                  onChanged?.call();
                },
                activeColor: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

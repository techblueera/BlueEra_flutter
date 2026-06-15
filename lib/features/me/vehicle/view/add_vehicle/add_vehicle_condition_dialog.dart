import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Presents the "is this a NEW or USED vehicle?" chooser. Resolves to
/// [VehicleCondition.isNew] / [VehicleCondition.used], or `null` if the
/// user dismisses it — the caller then routes to the matching flow.
Future<String?> showVehicleConditionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _VehicleConditionDialog(),
  );
}

class _VehicleConditionDialog extends StatelessWidget {
  const _VehicleConditionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.addVehicleTitle.tr,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.chooseVehicleConditionPrompt.tr,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size18),
            _OptionTile(
              icon: Icons.fiber_new_rounded,
              title: AppStrings.newVehicleOption.tr,
              subtitle: AppStrings.newVehicleOptionDesc.tr,
              onTap: () =>
                  Navigator.of(context).pop(VehicleCondition.isNew),
            ),
            SizedBox(height: SizeConfig.size12),
            _OptionTile(
              icon: Icons.directions_car_filled_outlined,
              title: AppStrings.usedVehicleOption.tr,
              subtitle: AppStrings.usedVehicleOptionDesc.tr,
              onTap: () => Navigator.of(context).pop(VehicleCondition.used),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F9FE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E8F4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 24),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    subtitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9AA6B6)),
          ],
        ),
      ),
    );
  }
}

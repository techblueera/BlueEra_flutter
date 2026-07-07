import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/add_lab_package_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Create Your Own Packages" preset landing (assets/img_1.png).
///
/// Vertical list of the presets from [LabPackageController.presetNames]
/// with an "Add Manually" tile at the bottom for a blank-name package.
/// Tapping any row opens [AddLabPackageScreen] with the tile's name
/// pre-filled (still editable).
class CreateYourOwnPackagesScreen extends StatelessWidget {
  const CreateYourOwnPackagesScreen({super.key});

  // Preset icons — chosen to visually distinguish rows in the list.
  static const Map<String, IconData> _iconFor = {
    'Basic Health Checkup': Icons.receipt_long_outlined,
    'Full Body Checkup': Icons.accessibility_new_rounded,
    'Executive Health Package': Icons.work_outline_rounded,
    'Diabetes Package': Icons.water_drop_outlined,
    'Thyroid Package': Icons.spa_outlined,
    'Heart Check-up Package': Icons.favorite_border_rounded,
    'Senior Citizen Package': Icons.elderly_rounded,
    'Men Health Package': Icons.man_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final presets = LabPackageController.presetNames;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonBackAppBar(title: 'Create Your Own Packages'),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
        itemCount: presets.length + 1, // +1 for the "Add Manually" tile
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
        itemBuilder: (context, i) {
          if (i < presets.length) {
            final name = presets[i];
            return _PresetTile(
              label: name,
              icon: _iconFor[name] ?? Icons.medical_information_outlined,
              onTap: () => _openForm(context, presetName: name),
            );
          }
          // Trailing "Others (Add Manually)" tile — opens the same form
          // with a blank name so the owner can type their own.
          return _PresetTile(
            label: 'Others (Add Manually)',
            icon: Icons.edit_note_rounded,
            trailingIcon: Icons.add_circle_outline_rounded,
            onTap: () => _openForm(context, presetName: ''),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {required String presetName}) {
    Get.to(() => AddLabPackageScreen(presetName: presetName));
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _PresetTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryColor),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: CustomText(
                label,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(trailingIcon,
                size: 20, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}

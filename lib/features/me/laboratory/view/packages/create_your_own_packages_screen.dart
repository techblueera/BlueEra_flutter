import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../widgets/local_assets.dart';

/// "Create Your Own Packages" preset landing (assets/img_1.png).
///
/// Vertical list of the presets from [LabPackageController.presetNames]
/// with an "Add Manually" tile at the bottom. Every row (presets + manual)
/// funnels into [AddLabTestScreen] under the Pathology collection so the
/// owner can compose the package by adding tests one at a time. Preset name
/// is only used as the row label — the form starts empty by design.
class CreateYourOwnPackagesScreen extends StatelessWidget {
  const CreateYourOwnPackagesScreen({super.key});

  // Preset icons — chosen to visually distinguish rows in the list.
  static const Map<String, String> _iconFor = {
    'Basic Health Checkup': AppIconAssets.basicHealthCampIcon,
    'Full Body Checkup': AppIconAssets.fullBodycheckupIcon,
    'Executive Health Package': AppIconAssets.healthPackageIcon,
    'Diabetes Package': AppIconAssets.diabetesPackageIcon,
    'Thyroid Package': AppIconAssets.thyroidPackageIcon,
    'Heart Check-up Package': AppIconAssets.heartPacakgeIcon,
    'Senior Citizen Package': AppIconAssets.seniorPackageIcon,
    'Men Health Package': AppIconAssets.menhealthPackageIcon,
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
              icon: _iconFor[name] ?? '',
              // Hand the preset name over so the form's Package Type
              // dropdown lands pre-selected on this row's package.
              onTap: () => _openAddLabTest(presetPackageType: name),
            );
          }
          // Trailing "Others (Add Manually)" tile — no preset, form starts
          // blank so the owner can pick a package type themselves.
          return _PresetTile(
            label: 'Others (Add Manually)',
            icon: AppIconAssets.addOutlinedIcon,
            trailingIcon: Icons.add_circle_outline_rounded,
            onTap: () => _openAddLabTest(),
          );
        },
      ),
    );
  }

  // These presets are all pathology-flavored health checkups, so the test
  // form is opened under the Pathology collection. `presetPackageType`
  // (when given) matches an entry in `LabTestController.packageTypeList`
  // and pre-selects that Package Type on the form.
  void _openAddLabTest({String? presetPackageType}) {
    Get.to(() => AddLabTestScreen(
          collection: 'pathology',
          presetPackageType: presetPackageType,
        ));
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final String icon;
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
              child: LocalAssets(
                imagePath: icon,
                width: 20,
                height: 20,
                imgColor: AppColors.secondaryTextColor,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: CustomText(
                label,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(trailingIcon, size: 20, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}

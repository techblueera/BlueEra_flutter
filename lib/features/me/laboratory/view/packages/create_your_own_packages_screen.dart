import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/add_lab_package_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/my_lab_packages_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../widgets/local_assets.dart';

/// "Create Your Own Packages" preset landing.
///
/// Vertical list of the presets from [LabPackageController.presetNames],
/// followed by an "Others (Add Manually)" tile at the bottom. Every tile
/// opens [AddLabPackageScreen] — the preset tiles pre-fill the package
/// name; the manual tile opens the form blank. Per
/// `lib/docs/FLUTTER_CATALOGUE_INTEGRATION.md` PART 5, these presets are
/// *packages* (bundles of tests), so tap targets the Package form —
/// never the Test form.
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

  static const String _manualLabel = 'Others (Add Manually)';

  @override
  Widget build(BuildContext context) {
    // Presets + one extra tile for the manual-create entry.
    final tiles = <String>[
      ...LabPackageController.presetNames,
      _manualLabel,
    ];
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Create Your Own Packages',
        showRightTextButton: true,
        rightTextButtonText: 'My Packages',
        rightTextButtonColor: AppColors.primaryColor,
        onRightTextButtonTap: () =>
            Get.to(() => const MyLabPackagesScreen()),
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
        itemBuilder: (context, i) {
          final name = tiles[i];
          final isManual = name == _manualLabel;
          return _PresetTile(
            label: name,
            icon: isManual ? AppIconAssets.editIcon : (_iconFor[name] ?? ''),
            onTap: () => _openAddPackage(presetName: isManual ? '' : name),
          );
        },
      ),
    );
  }

  /// Every tile — preset or manual — opens [AddLabPackageScreen]. The
  /// preset's name pre-fills the form (still editable); the manual tile
  /// opens with an empty name.
  void _openAddPackage({required String presetName}) {
    Get.to(() => AddLabPackageScreen(presetName: presetName));
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _PresetTile({
    required this.label,
    required this.icon,
    required this.onTap,
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
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}

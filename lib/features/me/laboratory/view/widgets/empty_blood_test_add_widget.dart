import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hero empty-state card on the lab tests tab inviting the lab owner to add
/// their first Blood & Routine test.
class BloodTestEmptyState extends StatelessWidget {
  const BloodTestEmptyState({super.key});

  static const String _backgroundAsset =
      'assets/category/medical/lab_blood_test_bg.png';
  static const String _emptyIconAsset =
      'assets/category/medical/empty_white_data.png';

  // These are the collection key + title that LabTestListScreen expects for
  // the Blood & Routine bucket. Kept aligned with [CategorySelector].
  static const String _bloodCollection = 'Blood & Routine Tests';
  static const String _bloodTitle = 'blood_routine';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "blood_routine_title".tr,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  _backgroundAsset,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildEmptyContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalAssets(imagePath: _emptyIconAsset, width: 60, height: 60),
        const SizedBox(height: 12),
        CustomText(
          "no_tests_posted".tr,
          color: Colors.white,
          textAlign: TextAlign.center,
          fontSize: SizeConfig.size15,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Get.to(() => LabTestListScreen(
                collection: _bloodCollection,
                title: _bloodTitle,
              )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white54),
            ),
            child: CustomText(
              "add_tests".tr,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

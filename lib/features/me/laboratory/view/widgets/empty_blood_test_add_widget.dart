import 'dart:ui';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class BloodTestEmptyState extends StatelessWidget {
  const BloodTestEmptyState({super.key});

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
                // Background Image with Blur
                Image.asset(
                  'assets/category/medical/lab_blood_test_bg.png',
                  // Use a high-quality lab image
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Positioned.fill(
                //   child: Container(color: Colors.black.withOpacity(0.4)),
                // ),
                // The Content Overlay
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Folder/Search Icon
                      LocalAssets(
                          imagePath:
                              "assets/category/medical/empty_white_data.png",width: 60,height: 60,),
                      const SizedBox(height: 12),
                      CustomText(
                        "no_tests_posted".tr,
                        color: Colors.white,
                        textAlign: TextAlign.center,
                        fontSize: SizeConfig.size15,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 16),
                      // Action Button
                      InkWell(
                        onTap: () {
                          Get.to(LabTestListScreen(
                            collection: "Blood & Routine Tests",
                            title: "blood_routine",
                          ));
                        },
                        // onTap: () => _openAddTestOption(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAddTestOption(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText("Select Test Category",
                fontSize: 18, fontWeight: FontWeight.bold),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.biotech, color: Colors.blue),
              title: const Text("Complete Blood Count (CBC)"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.red),
              title: const Text("Blood Glucose / Sugar"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

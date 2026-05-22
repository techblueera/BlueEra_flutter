import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class MedicalCategorySelectorWidget extends StatelessWidget {
  const MedicalCategorySelectorWidget({super.key,  this.labID});
  final String? labID;
  @override
  Widget build(BuildContext context) {
    // List of data for the grid

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: SizeConfig.size16,),
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.medicalUpdateYourMedicalProducts, // Using GetX translation
                fontWeight: FontWeight.w700,
              ),
              // const Icon(Icons.edit_outlined, size: 24),
            ],
          ),
          SizedBox(height: SizeConfig.size20),

          // Responsive Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns as per image
              crossAxisSpacing: SizeConfig.size12,
              mainAxisSpacing: SizeConfig.size12,
              childAspectRatio: 0.85, // Adjust this for height vs width ratio
            ),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  // Get.to(LabTestListScreen(
                  //   collection: categories[index]['key'] ?? "",
                  //   title: categories[index]['title'],labId: labID,
                  // ));  // Get.to(LabTestListScreen(
                  //   collection: categories[index]['key'] ?? "",
                  //   title: categories[index]['title'],labId: labID,
                  // ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    // Subtle blue tint from image
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image Asset
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            categories[index]['image']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Text Label
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: CustomText(
                            categories[index]['title'],
                            fontSize: SizeConfig.size13,
                            fontWeight: FontWeight.w500,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

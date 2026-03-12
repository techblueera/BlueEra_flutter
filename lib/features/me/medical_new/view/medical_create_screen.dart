import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalCreateScreen extends StatefulWidget {
  const MedicalCreateScreen({super.key});

  @override
  State<MedicalCreateScreen> createState() => _MedicalCreateScreenState();
}

class _MedicalCreateScreenState extends State<MedicalCreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: Column(
        children: [
          Flexible(
            child: CommonCardWidget(

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText("Bulk Upload Shop Product Photos",fontSize: 16,fontWeight: FontWeight.w600,),
                 SizedBox(height: 10,),
                  Row(
                    children: [
                      uploadMediaWidget(
                          imagePath:
                              'assets/category/medical/medical_upload_photo_med.png',
                          title: 'Upload Photo'),
                      SizedBox(width: 7,),
                      uploadMediaWidget(
                          imagePath:
                              'assets/category/medical/medical_upload_photo.png',
                          title: 'Upload List'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 3 columns as per image
                crossAxisSpacing: SizeConfig.size6,
                mainAxisSpacing: SizeConfig.size6,
                childAspectRatio: 1.5, // Adjust this for height vs width ratio
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
                      color: Colors.white,
                      // Subtle blue tint from image
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.whiteE5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image Asset
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset(
                              categories[index]['image']!,
                              fit: BoxFit.contain,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        // Text Label
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 5),
                          child: CustomText(
                            categories[index]['title'],
                            fontSize: SizeConfig.size13,
                            fontWeight: FontWeight.w500,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget uploadMediaWidget({
    required String imagePath,
    required String title,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            color: Colors.white,
            // Subtle blue tint from image
            borderRadius: BorderRadius.circular(6),
            // border: Border.all(color: AppColors.whiteE5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Asset
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  // width: 60,
                  // height: 60,
                ),
              ),
              SizedBox(height: 10,),

              // Text Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5),
                child: CustomText(
                  title,
                  fontSize: SizeConfig.small,
                  // fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  color:AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

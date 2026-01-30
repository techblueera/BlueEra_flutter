import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../category/OphthalmologyENTPage.dart';
import '../category/basic_blood_test_page.dart';
import '../category/lab_pathology_page.dart';
import '../category/pulmonology_diagnostics_page.dart';
import '../category/radiology_page.dart';
import 'me_menu_card_design.dart';
class AddLabServices extends StatefulWidget {
  const AddLabServices({super.key});

  @override
  State<AddLabServices> createState() => _AddLabServicesState();
}
class _AddLabServicesState extends State<AddLabServices> {
  // Map of service title to corresponding page
  final Map<String, Widget Function()> servicePages = {
    "Basic Blood Test": () => BasicBloodTestPage(),
    "Pathology": () => PathologyTestsPage(),
    "Radiology": () => RadiologyPage(),
    "Pulmonology Diagnostics": () => PulmonologyDiagnosticsPage(),
    "Ophthalmology & ENT": () => OphthalmologyENTPage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Service",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...servicePages.keys.map((title) {
            return InkWell(
              onTap: () {
                final pageBuilder = servicePages[title];
                if (pageBuilder != null) {
                  Get.to(() => pageBuilder());
                }
              },
              child: MeMenuCardDesign(
                title: title,
                icon: '',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryColor),
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "Create Your Own Packages",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

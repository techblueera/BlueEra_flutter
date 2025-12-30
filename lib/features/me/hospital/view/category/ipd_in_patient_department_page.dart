import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../../medical/view/category/otc_items_page.dart';

class IpdInPatientDepartmentPage extends StatefulWidget {
  const IpdInPatientDepartmentPage({super.key});

  @override
  State<IpdInPatientDepartmentPage> createState() => _IpdInPatientDepartmentPageState();
}
class _IpdInPatientDepartmentPageState extends State<IpdInPatientDepartmentPage> {

  final Map<String, Widget Function()> servicePages = {
    "General Ward (Male / Female)": () => Container(),
    "Semi-Private Ward": () => Container(),
    "Private Ward": () => Container(),
    "Isolation Ward": () => Container(),
    "Pediatric Ward": () => Container(),
    "Maternity Ward": () => Container(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "IPD (In-Patient Departments / Wards)",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...servicePages.keys.map((title) {
            return InkWell(
              onTap: () {
                final pageBuilder = servicePages[title];
                // if (pageBuilder != null) {
                //   Get.to(() => pageBuilder());
                // }
              },
              child: MeMenuCardDesign(
                count: "2",
                showCount: title=="General Ward (Male / Female)",
                title: title,
                icon: 'assets/icons/service_icon.svg',
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
                Icon(Icons.add_circle_outline,color: AppColors.primaryColor,size: 20,),
                SizedBox(width: SizeConfig.size4,),
                CustomText(
                  "Add More Ward",
                  fontSize: 14,
                  textAlign: TextAlign.center,
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

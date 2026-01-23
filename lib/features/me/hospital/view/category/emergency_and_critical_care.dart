import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
class EmergencyAndCriticalCare extends StatefulWidget {
  const EmergencyAndCriticalCare({super.key});

  @override
  State<EmergencyAndCriticalCare> createState() => _EmergencyAndCriticalCareState();
}
class _EmergencyAndCriticalCareState extends State<EmergencyAndCriticalCare> {

  final Map<String, Widget Function()> servicePages = {
    "Emergency / Casualty": () => Container(),
    "Trauma Care": () => Container(),
    "ICU (Intensive Care Unit)": () => Container(),
    "CCU (Cardiac Care Unit)": () => Container(),
    "NICU (Neonatal ICU)": () => Container(),
    "PICU (Pediatric ICU)": () => Container(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Emergency & Critical Care",
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
                showToggleButton:true,
                title: title,
                icon: '',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}

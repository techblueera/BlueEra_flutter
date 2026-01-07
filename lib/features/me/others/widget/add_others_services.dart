import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../laboratory/view/widgets/me_menu_card_design.dart';
import '../category/about_us/about_us.dart';
class AddOthersServices extends StatefulWidget {
  const AddOthersServices({super.key});

  @override
  State<AddOthersServices> createState() => _AddOthersServicesState();
}
class _AddOthersServicesState extends State<AddOthersServices> {

  final Map<String, Widget Function()> servicePages = {
    "About US": () => OthersAboutUs(),
    "Products": () => Container(),
    "Services": () => Container(),
    "Announcements": () => Container(),
    "Gallery": () => Container(),
    "Privacy Policy, Terms & Condition": () => Container(),
    "Careers": () => Container(),
    "Timing": () => Container(),
    "Contact US": () => Container(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Others Service",
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

        ],
      ),
    );
  }
}

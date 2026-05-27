import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/view/about_us/about_organization.dart';
import 'package:BlueEra/features/me/automotive_service/view/management/management_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/staff/staff_screen.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class OthersAboutUs extends StatefulWidget {
  const OthersAboutUs({super.key});

  @override
  State<OthersAboutUs> createState() => _AddOthersServicesState();
}

class _AddOthersServicesState extends State<OthersAboutUs> {
  late final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: AppStrings.otherAboutOrganizationTitle.tr,
      icon: AppIconAssets.other_org_about,
      page: () => AboutOrganization(),
    ),
    ServiceMenuItem(
      title: AppStrings.otherManagementTitle.tr,
      icon: AppIconAssets.other_management,
      page: () => ManagementScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.otherStaffsTitle.tr,
      icon: AppIconAssets.other_staffs,
      page: () => StaffScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.otherOfficeFacilityTitle.tr,
      icon: AppIconAssets.other_office_facility,
      page: () => ComingSoon(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherAboutUsTitle.tr,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...serviceMenus.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              // Spacing between cards
              child: InkWell(
                onTap: () => Get.to(item.page),
                child: MeMenuCardDesign(
                  title: item.title,
                  icon: item.icon,
                ),
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}

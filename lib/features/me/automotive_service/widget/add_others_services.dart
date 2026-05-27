import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_contact_us/other_contact_us.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_service_gallery/other_service_photos_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/timing_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/about_us/about_us.dart';
import 'package:BlueEra/features/me/automotive_service/view/announcements/announcements_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_career_jobs/other_job_listing_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_privacy_condition/other_privacy_condition_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/add_product_text_or_snap_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';
import '../../laboratory/view/widgets/me_menu_card_design.dart';

class AddOthersServices extends StatefulWidget {
  const AddOthersServices({super.key});

  @override
  State<AddOthersServices> createState() => _AddOthersServicesState();
}

class _AddOthersServicesState extends State<AddOthersServices> {
  late final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: AppStrings.aboutUs.tr,
      icon: AppIconAssets.about_us,
      page: () => OthersAboutUs(),
    ),
    ServiceMenuItem(
      title: AppStrings.products.tr,
      icon: AppIconAssets.other_products,
      page: () => AddProductTextOrSnapSearchScreen(id: businessId, providerType: ProviderType.business),
    ),
    ServiceMenuItem(
      title: AppStrings.services.tr,
      icon: AppIconAssets.other_services,
      page: () => ServiceUploadScreen(providerType: ProviderType.business),
    ),
    ServiceMenuItem(
      title: AppStrings.otherAnnouncements.tr,
      icon: AppIconAssets.other_announcements,
      page: () => AnnouncementsScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.gallery.tr,
      icon: AppIconAssets.other_gallery,
      page: () => OtherServicePhotosPhotoScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.otherPrivacyTncTitle.tr,
      icon: AppIconAssets.other_privacy,
      page: () => OtherPrivacyConditionScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.careers.tr,
      icon: AppIconAssets.other_careers,
      page: () => OtherJobListingScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.otherTimingTitle.tr,
      icon: AppIconAssets.other_timing,
      page: () => TimingScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.contactUs.tr,
      icon: AppIconAssets.contact_us,
      page: () => OtherContactUs(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Column(
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
            SizedBox(height: SizeConfig.size60),
          ],
        ),
      ),
    );
  }
}

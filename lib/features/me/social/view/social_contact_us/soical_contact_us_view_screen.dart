import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/social/controller/social_contact_us_controller.dart';
import 'package:BlueEra/features/me/social/view/social_contact_us/social_contact_us_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialContactUsViewScreen extends StatefulWidget {
  const SocialContactUsViewScreen({super.key});

  @override
  State<SocialContactUsViewScreen> createState() =>
      _SocialContactUsViewScreenState();
}

class _SocialContactUsViewScreenState extends State<SocialContactUsViewScreen> {
  final controller = Get.put(SocialContactUsController());

  @override
  void initState() {
    // TODO: implement initState
    controller.fetchHomeData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.contactUs.tr,
      ),
      body: Column(
        children: [
          CommonCardWidget(
            cardMargin: 0,
            padding: 10,
            child: _buildContact(),
          ),
          SizedBox(height: SizeConfig.size12),
          // const SizedBox(height: 20),
          // Map Placeholder
          Obx(() {
            return BusinessLocationWidget(
                key: ValueKey(controller
                        .contactUsData.value?.data?.location?.coordinates?[0]
                        .toString() ??
                    "0.0"),
                locationText: "",
                latitude: double.parse(controller
                        .contactUsData.value?.data?.location?.coordinates?[0]
                        .toString() ??
                    "0.0"),
                longitude: double.parse(controller
                        .contactUsData.value?.data?.location?.coordinates?[1]
                        .toString() ??
                    "0.0"),
                businessName: "",
                padding: 10,
                isTitleShow: true);
          }),
        ],
      ),
    );
  }

  Widget _buildContact() {
    return Obx(() {
      final contact = controller.contactUsData.value?.data;

      return Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(AppStrings.contactUs.tr),
                InkWell(
                    onTap: () {
                      Get.to(() => SocialContactUsScreen(
                        profile: contact,
                      ));
                    },
                    child:
                        LocalAssets(imagePath: AppIconAssets.tablerEditIcon)),
              ],
            ),
            if ((contact?.websiteUrl ?? "").isNotEmpty)
              _contactRow(
                  AppIconAssets.website_click, contact?.websiteUrl ?? "",
                  isLink: true),
            if ((contact?.phoneNo ?? "").isNotEmpty)
              _contactRow(AppIconAssets.phone_outline, contact?.phoneNo ?? ""),
            if ((contact?.email ?? "").isNotEmpty)
              _contactRow(AppIconAssets.email, contact?.email ?? ""),
            if ((contact?.location?.name ?? "").isNotEmpty)
              _contactRow(
                  AppIconAssets.location_new, contact?.location?.name ?? "",
                  color: AppColors.secondaryTextColor),
          ],
        ),
      );
    });
  }

  Widget _contactRow(String icon, String text,
      {bool isLink = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink == false ? AppColors.mainTextColor : null,
            height: 20,
            width: 20,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: CustomText(
                text,
                color: color ?? AppColors.black,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

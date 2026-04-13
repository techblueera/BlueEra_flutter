import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarnServiceContactMapCard extends StatelessWidget {
  final String? logoUrl;
  final String? serviceName;
  final String? description;
  final String? contactNo;
  final String? email;
  final String? address;
  final String? serviceCategory;
  final double latitude;
  final double longitude;
  final bool showEditButton;
  final VoidCallback? onEditTap;

  const EarnServiceContactMapCard({
    super.key,
    this.logoUrl,
    this.serviceName,
    this.description,
    this.contactNo,
    this.email,
    this.address,
    this.serviceCategory,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.showEditButton = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.contactUs.tr,
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showEditButton && onEditTap != null)
                InkWell(
                  onTap: onEditTap,
                  child: LocalAssets(
                    height: 16,
                    imagePath: AppIconAssets.pen_line,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.greyE5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                        image: DecorationImage(
                          image: (logoUrl != null && logoUrl!.isNotEmpty)
                              ? NetworkImage(logoUrl!) as ImageProvider
                              : AssetImage(AppIconAssets.place_holder_image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            serviceName,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 5),
                          if (description != null && description!.isNotEmpty)
                            ExpandableText(
                              text: description!,
                              trimLines: 3,
                              isReadMoreNewLine: false,
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          else
                            CustomText(
                              'N/A',
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.greyE5, height: 30),
                if (serviceCategory != null && serviceCategory!.isNotEmpty)
                  _contactItem(AppIconAssets.principal, serviceCategory!,
                      AppColors.secondaryTextColor),
                if (email != null && email!.isNotEmpty)
                  _contactItem(AppIconAssets.email, email!,
                      AppColors.secondaryTextColor),
                if (contactNo != null && contactNo!.isNotEmpty)
                  _contactItem(AppIconAssets.phone_outline, contactNo!,
                      AppColors.secondaryTextColor),
                if (address != null && address!.isNotEmpty)
                  _contactItem(AppIconAssets.location_new, address!,
                      AppColors.secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 10),
          BusinessLocationMapWidget(
            latitude: latitude,
            longitude: longitude,
            businessName: serviceName ?? '',
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(label,
                fontSize: 15, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }
}

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_bottom_sheet.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_profile_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessContactMapCard extends StatelessWidget {
  final BusinessProfileDetails? businessProfileDetails;
  final bool showEditButton;

  const BusinessContactMapCard({
    super.key,
    this.businessProfileDetails,
    this.showEditButton = true,
  });


  Future<void> updateLocationDialog(
      BuildContext context,
      BusinessProfileDetails? details,
     ) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size40),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          backgroundColor: AppColors.white,
          contentPadding: EdgeInsets.zero,
          content: Container(
            margin: EdgeInsets.only(
                left: SizeConfig.size16,
                right: SizeConfig.size16,
                bottom: SizeConfig.size16,
                top: SizeConfig.size8),
            // vertical: SizeConfig.size30, horizontal: SizeConfig.size40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () =>  Get.back(),
                      child: Icon(
                        Icons.close,
                        color: AppColors.secondaryTextColor,
                      ),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalAssets(imagePath: AppIconAssets.warningIcon),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      AppStrings.updateLocation,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size7,
                ),
                CustomText(
                    AppStrings.updateLocationWarning,
                    fontSize: SizeConfig.medium,
                    textAlign: TextAlign.center,
                    color: AppColors.secondaryTextColor),
                SizedBox(height: SizeConfig.size15),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () =>  Get.back(),
                        title: AppStrings.cancel,
                        textColor: AppColors.secondaryTextColor,
                        bgColor: AppColors.white,
                        borderColor: AppColors.secondaryTextColor,
                        radius: 8.0,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () {
                          Get.back();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => BusinessLocationBottomSheet(
                                prevBusinessDetails: details),
                          );
                        },
                        title: AppStrings.confirm,
                        isValidate: true,
                        bgColor: AppColors.red02,
                        radius: 8.0,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = businessProfileDetails?.logo;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(
          top: 10.0
       ),
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
              if (showEditButton)
                InkWell(
                  onTap: () => updateLocationDialog(
                      context,
                      businessProfileDetails
                  ),
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

                // ─── Logo + Name + Description ───
                Row(
                  children: [
                    Container(
                      key: ValueKey(logoUrl),
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        image: DecorationImage(
                          image: (logoUrl != null && logoUrl.isNotEmpty)
                              ? NetworkImage(logoUrl) as ImageProvider
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
                            businessProfileDetails?.businessName,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 5),
                          (businessProfileDetails?.businessDescription?.isNotEmpty ?? false)
                              ? ExpandableText(
                            text: businessProfileDetails?.businessDescription ?? '',
                            trimLines: 3,
                            isReadMoreNewLine: false,
                            expandMode: ExpandMode.dialog,
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppConstants.OpenSans,
                            ),
                          )
                              : CustomText(
                            AppStrings.na,
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppConstants.OpenSans,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(color: AppColors.greyE5, height: 30),

                // ─── Contact Items ───
                if (businessProfileDetails?.websiteUrl?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.website_click, businessProfileDetails!.websiteUrl!, AppColors.primaryColor),

                if (businessProfileDetails?.subCategoryDetails?.name?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.principal, businessProfileDetails!.subCategoryDetails!.name!, AppColors.secondaryTextColor),

                if (businessProfileDetails?.ownerDetails?[0].email?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.email, businessProfileDetails!.ownerDetails![0].email!, AppColors.secondaryTextColor),

                if (businessProfileDetails?.userContactNo?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.phone_outline, businessProfileDetails!.userContactNo!, AppColors.secondaryTextColor),

                if (businessProfileDetails?.address?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.location_new, businessProfileDetails!.address!, AppColors.secondaryTextColor),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ─── Map ───
          BusinessLocationMapWidget(
            latitude:     businessProfileDetails?.businessLocation?.lat  ?? 0.0,
            longitude:    businessProfileDetails?.businessLocation?.lon  ?? 0.0,
            businessName: businessProfileDetails?.businessName           ?? '',
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
            child: CustomText(label, fontSize: 15, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }

}
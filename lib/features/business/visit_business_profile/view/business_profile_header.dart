import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class BusinessProfileHeader extends StatelessWidget {
  BusinessProfileHeader({super.key, required this.businessProfileDetails});

  final BusinessProfileDetails businessProfileDetails;
  final controllerVisit = Get.put(VisitProfileController());
  final chatViewController = Get.find<ChatViewController>();
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///PROFILE PICTURE & Follow Un follow action....
              Padding(
                padding: EdgeInsets.only(
                    right: SizeConfig.size10,
                    left: SizeConfig.size10,
                    top: SizeConfig.size10,
                    bottom: SizeConfig.size10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      backgroundImage: businessProfileDetails.logo != null
                          ? NetworkImage(businessProfileDetails.logo ?? "")
                          : null,
                      child: businessProfileDetails.logo == null
                          ? CustomText(
                              getInitials(businessProfileDetails.businessName),
                              fontSize: SizeConfig.size18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    if (businessProfileDetails.userId != null)
                      Obx(() {
                        return InkWell(
                            onTap: () async {
                              if (isGuestUser()) {
                                createProfileScreen();
                              } else {
                                if (controllerVisit.isFollow.value) {
                                  await controllerVisit.unFollowUserController(
                                      candidateResumeId:
                                          businessProfileDetails.userId);
                                } else {
                                  await controllerVisit.followUserController(
                                      candidateResumeId:
                                          businessProfileDetails.userId);
                                }
                              }
                            },
                            child: CustomText(
                              controllerVisit.isFollow.value
                                  ? "Unfollow"
                                  : "Follow",
                              color: controllerVisit.isFollow.value
                                  ? AppColors.colorTextDarkGrey
                                  : AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: controllerVisit.isFollow.value
                                  ? AppColors.colorTextDarkGrey
                                  : AppColors.primaryColor,
                              fontSize: SizeConfig.size12,
                            ));
                      }),
                  ],
                ),
              ),
              SizedBox(
                width: SizeConfig.size10,
              ),

              /// USER NAME AND FOLLOW/UNFOLLOW,MORE ICON VIEW....
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: SizeConfig.size5,
                    ),
                    SizedBox(
                      width: Get.width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: CustomText(
                                    businessProfileDetails.businessName,
                                    fontSize: SizeConfig.large,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    color: AppColors.black,
                                  ),
                                ),
                                if(businessProfileDetails.username!=null&&(businessProfileDetails.username?.isNotEmpty??false))
                                Flexible(
                                  child: CustomText(
                                    " @${businessProfileDetails.username}",
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w600,
                                    overflow: TextOverflow.ellipsis,
                                    color: AppColors.shadowColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size10),
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                      top: SizeConfig.size8,
                                      left: SizeConfig.size10),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10,
                                      vertical: SizeConfig.size3),
                                  decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: InkWell(
                                      onTap: () async {
                                        chatViewController
                                            .openAnyOneChatFunction(
                                          profileImage: businessProfileDetails.logo,
                                          otherUserId:(viewBusinessDetailsController
                                              .conversationId.value=='')?viewBusinessDetailsController
                                            .otherUserId?.value :null,
                                          businessId: businessProfileDetails.id,
                                          type: "business",
                                          isInitialMessage: (viewBusinessDetailsController
                                              .conversationId.value=='')?true:false,
                                          userId: businessProfileDetails.userId,
                                          conversationId:
                                              viewBusinessDetailsController
                                                  .conversationId.value,
                                          contactName: businessProfileDetails
                                              .businessName,
                                          contactNo: businessProfileDetails
                                              .businessNumber
                                              ?.officeMobNo
                                              ?.number
                                              .toString(),
                                        );
                                      },
                                      child: CustomText(
                                        "Chat",
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: SizeConfig.size12,
                                      )),
                                ),
                                SizedBox(
                                  width: SizeConfig.size6,
                                ),
                                Container(
                                  height: 20,
                                  width: 20,
                                  margin: EdgeInsets.only(
                                      top: SizeConfig.size8,
                                      right: SizeConfig.size2),
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    // offset: const Offset(-6, 36),
                                    color: AppColors.white,

                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    onSelected: (value) async {
                                      if (value.toUpperCase() == "SHARE") {
                                        final link = profileDeepLink(
                                            userId:
                                                businessProfileDetails.userId);
                                        final message =
                                            "See my profile on BlueEra:\n$link\n";
                                        await SharePlus.instance
                                            .share(ShareParams(
                                          text: message,
                                          subject: businessProfileDetails
                                              .businessName,
                                        ));
                                      }
                                    },
                                    icon: LocalAssets(
                                        imagePath: AppIconAssets.more_vertical),
                                    itemBuilder: (context) =>
                                        popupMenuVisitProfileItems(),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: _buildTag((businessProfileDetails
                                          .subCategoryDetails !=
                                      null &&
                                  businessProfileDetails
                                          .subCategoryDetails?.name !=
                                      null)
                              ? businessProfileDetails
                                      .subCategoryDetails?.name ??
                                  ''
                              : (businessProfileDetails.categoryDetails !=
                                          null &&
                                      businessProfileDetails
                                              .categoryDetails?.name !=
                                          null)
                                  ? businessProfileDetails
                                          .categoryDetails?.name ??
                                      ''
                                  : (businessProfileDetails.natureOfBusiness ??
                                      'OTHERS')),
                        ),
                        SizedBox(
                          width: SizeConfig.size6,
                        ),
                        _buildTag(
                            businessProfileDetails.isActive ?? false
                                ? "Opened"
                                : "Closed",
                            borderColor:
                                businessProfileDetails.isActive ?? false
                                    ? AppColors.green39
                                    : AppColors.red,
                            textColor: businessProfileDetails.isActive ?? false
                                ? AppColors.green39
                                : AppColors.red),
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),
                    Row(
                      children: [
                        LocalAssets(
                            height: 20,
                            width: 20,
                            imagePath: AppIconAssets.businessprofile_location),
                        SizedBox(width: SizeConfig.size5),
                        Flexible(
                          child: CustomText(
                            "${(viewBusinessDetailsController.distanceFromKm.value ?? 0).toStringAsFixed(2)} Km Far",
                            color: AppColors.primaryColor,
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                    if(businessProfileDetails.cityStatePincode!=null&&(businessProfileDetails.cityStatePincode?.isNotEmpty??false)&&(businessProfileDetails.cityStatePincode?.toLowerCase())!="null")...[
                      SizedBox(width: SizeConfig.size5),
                      Padding(
                        padding:  EdgeInsets.only(right: SizeConfig.size20),
                        child: CustomText(
                          "City : ${businessProfileDetails.cityStatePincode}",
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]

                  ],
                ),
              ),
            ],
          ),

          ///BUSINESS DESCRIPTION
         if(businessProfileDetails.businessDescription!=null&&(businessProfileDetails.businessDescription?.isNotEmpty??false))
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size10,
                right: SizeConfig.size10,
                bottom: SizeConfig.size10),
            child: ExpandableText(
              text: "      ${businessProfileDetails.businessDescription}",
              trimLines: 3,
              style: TextStyle(
                color: AppColors.mainTextColor,
                fontFamily: AppConstants.OpenSans,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: SizeConfig.size12),
          Container(
            margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size10,
              horizontal: SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE5E5E5), // #E5E5E5 border
                width: 1,
              ),
              borderRadius: BorderRadius.circular(SizeConfig.size14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x14000000), // #000000 with 8% opacity
                  offset: const Offset(0, 1), // X: 0, Y: 1
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
              color: Colors.white, // optional background
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInfo("Rating",
                          "★ ${(businessProfileDetails.rating ?? 0).toStringAsFixed(1)}"),
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      buildInfo(
                          "Views", "${formatIndianNumber(businessProfileDetails.total_views ?? 0)}"),
                    ],
                  ),
                ),
                // SizedBox(
                //   width: 100,
                // ),
                Expanded(
                  child: SizedBox(
                    height: SizeConfig.size50,
                    child: VerticalDivider(
                      color: AppColors.coloGreyText,
                      width: 12,
                      thickness: 1.2,
                    ),
                  ),
                ),
                // SizedBox(
                //   width: SizeConfig.size24,
                // ),
                Flexible(
                  flex: 2,

                  child: Container(
                    // color: Colors.red,
                    width: Get.width,
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding:  EdgeInsets.symmetric(),
                          child: buildInfo("Inquiries",formatIndianNumber(0) ),
                        ),
                        SizedBox(
                          height: SizeConfig.size12,
                        ),
                        InkWell(
                            onTap: () {
                              Get.to(() => FollowersFollowingPage(
                                    tabIndex: 1,
                                    userID: businessProfileDetails.id ?? "",
                                  ));
                            },
                            child: buildInfo("Followers",
                                "${formatIndianNumber(businessProfileDetails.total_followers ?? 0)}")),
                      ],
                    ),
                  ),
                ),
                // SizedBox(
                //   width: SizeConfig.size20,
                // ),
                Expanded(
                  child: SizedBox(
                    height: SizeConfig.size50,
                    child: VerticalDivider(
                      color: AppColors.coloGreyText,
                      width: 12,
                      thickness: 1.2,
                    ),
                  ),
                ),
                // SizedBox(
                //   width: SizeConfig.size20,
                // ),
                Expanded(
                  flex: 2,

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        "Joined",
                        fontSize: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        businessProfileDetails.dateOfIncorporation == null
                            ? ""
                            : "${businessProfileDetails.dateOfIncorporation?.date ?? ""}/${(businessProfileDetails.dateOfIncorporation?.month ?? 1)}/${businessProfileDetails.dateOfIncorporation?.year ?? ""}",
                        fontSize: SizeConfig.size12,
                        maxLines: 1,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: SizeConfig.size10),
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size12),
        ],
      ),
    );
  }

  Widget _buildTag(
    String text, {
    Color borderColor = AppColors.greyA5,
    Color textColor = AppColors.black,
  }) {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          border: Border.all(color: borderColor),
        ),
        child: CustomText(
          text,
          fontSize: SizeConfig.size10,
          fontWeight: FontWeight.w400,
          color: textColor,
        ));
  }

}
Widget buildInfo(String title, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        title + ":",
        fontSize: SizeConfig.size12,
        color: AppColors.grayText,
        fontWeight: FontWeight.w400,
      ),
      SizedBox(width: SizeConfig.size6),
      Flexible(
        child: CustomText(
          value ,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
        ),
      ),
    ],
  );
}


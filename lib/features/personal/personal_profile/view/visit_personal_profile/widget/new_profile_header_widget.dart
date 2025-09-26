import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../core/api/model/user_profile_res.dart';

class NewProfileHeaderWidget extends StatelessWidget {
  NewProfileHeaderWidget(
      {super.key, required this.user, required this.screenFromName});

  final User? user;
  final controller = Get.find<VisitProfileController>();
  final String? screenFromName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///PROFILE PICTURE....
                Padding(
                  padding: EdgeInsets.only(right: 0, top: SizeConfig.size25),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    backgroundImage: user?.profileImage != null
                        ? NetworkImage(user?.profileImage ?? "")
                        : null,
                    child: user?.profileImage == null
                        ? CustomText(
                            getInitials(user?.name),
                            fontSize: SizeConfig.size18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                SizedBox(
                  width: SizeConfig.size10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: SizeConfig.size5,
                      ),

                      /// USER NAME AND FOLLOW/UNFOLLOW,MORE ICON VIEW....
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
                                      user?.name,
                                      fontSize: SizeConfig.large,
                                      fontWeight: FontWeight.w600,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      // color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                  if (user?.username != null &&
                                      (user?.username?.isNotEmpty ?? false))
                                    Flexible(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 3),
                                        child: CustomText(
                                          " @${user?.username}",
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w600,
                                          overflow: TextOverflow.ellipsis,
                                          color: AppColors.shadowColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (user?.id != null)
                                  Obx(() {
                                    return Container(
                                      margin: EdgeInsets.only(
                                          top: SizeConfig.size8,
                                          left: SizeConfig.size10),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size10,
                                          vertical: SizeConfig.size3),
                                      decoration: BoxDecoration(
                                          color: controller.isFollow.value
                                              ? AppColors.colorTextDarkGrey
                                              : AppColors.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: InkWell(
                                          onTap: () async {
                                            if (isGuestUser()) {
                                              createProfileScreen();
                                            } else {
                                              if (controller.isFollow.value) {
                                                await controller
                                                    .unFollowUserController(
                                                        candidateResumeId:
                                                            user?.id);
                                              } else {
                                                await controller
                                                    .followUserController(
                                                        candidateResumeId:
                                                            user?.id);
                                              }
                                            }
                                          },
                                          child: CustomText(
                                            controller.isFollow.value
                                                ? "Unfollow"
                                                : "Follow",
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                            // decoration: TextDecoration.underline,
                                            // decorationColor: AppColors.primaryColor,
                                            fontSize: SizeConfig.size12,
                                          )),
                                    );
                                  }),
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
                                        final link =
                                            profileDeepLink(userId: user?.id);
                                        final message =
                                            "See my profile on BlueEra:\n$link\n";
                                        await SharePlus.instance
                                            .share(ShareParams(
                                          text: message,
                                          subject: user?.name,
                                        ));
                                      }
                                    },
                                    icon: LocalAssets(
                                        imagePath:
                                            AppIconAssets.more_vertical),
                                    itemBuilder: (context) =>
                                        popupMenuVisitProfileItems(),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      ///PERSONAL DETAILS VIEW TEXT  DIALOG...
                      if (screenFromName == AppConstants.chatScreen)
                        GestureDetector(
                          onTap: () async {
                            // await controller.getUserChannelDetailsController(
                            //     userId: user?.id);
                            showPersonalDetailsPopup(context);
                          },
                          // Reuse method if applicable
                          child: CustomText(
                            'Personal Details',
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryColor,
                            fontSize: SizeConfig.size12,
                          ),
                        ),

                      ///SET PROFESSION...
                      if (screenFromName == AppConstants.feedScreen)...[
                        Padding(
                          padding: EdgeInsets.only(top: SizeConfig.size1),
                          child: (user?.profession != null &&user?.profession != "null" &&
                              (user?.profession?.isNotEmpty ?? false))
                              ? Container(
                            margin: EdgeInsets.only(top: SizeConfig.size5),
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size8,
                                  vertical: SizeConfig.size3),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors
                                          .secondaryTextColor),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: CustomText(
                                "${user?.profession}",
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.extraSmall,
                                maxLines: 1,
                              ))
                              : SizedBox(),
                        ),

                      ],
                      ///VISIT CHANNEL IF CHANNEL IS CREATED...
                      Obx(() {
                        return (controller
                                    .channelUserName?.value.isNotEmpty ??
                                false)
                            ? Padding(
                                padding:
                                    EdgeInsets.only(top: SizeConfig.size1),
                                child: Row(
                                  children: [
                                    CustomText(
                                      "Visit my channel : ",
                                      fontSize: SizeConfig.size12,
                                    ),
                                    Flexible(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context,
                                              RouteHelper
                                                  .getChannelScreenRoute(),
                                              arguments: {
                                                ApiKeys.argAccountType:
                                                    user?.accountType,
                                                ApiKeys.channelId: controller
                                                    .channelUserId?.value,
                                                ApiKeys.authorId: user?.id
                                              });
                                        },
                                        child: CustomText(
                                          '@${controller.channelName?.value}',
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline,
                                          decorationColor:
                                              AppColors.primaryColor,
                                          fontSize: SizeConfig.size12,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox();
                      }),
                      ///SHOW POST/FOLLOWER/FOLLOWING COUNT....
                      Padding(
                        padding: EdgeInsets.only(
                            right: 38.0, top: SizeConfig.size5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                Get.to(() => FollowersFollowingPage(
                                      tabIndex: 0,
                                      userID: controller
                                              .userData.value?.user?.id ??
                                          "",
                                    ));
                              },
                              child: StatBlock(
                                  count:
                                      controller.userData.value?.totalPosts !=
                                              null
                                          ? formatIndianNumber(num.parse(
                                              controller.userData.value
                                                      ?.totalPosts
                                                      .toString() ??
                                                  "0"))
                                          : "0",
                                  label: "Post"),
                            ),
                            Container(
                              height: 15,
                              width: 0.9,
                              color: AppColors.secondaryTextColor,
                              margin: EdgeInsets.only(
                                  left: SizeConfig.size5,
                                  right: SizeConfig.size5),
                            ),
                            InkWell(
                              onTap: () {
                                Get.to(() => FollowersFollowingPage(
                                      tabIndex: 0,
                                      userID: controller
                                              .userData.value?.user?.id ??
                                          "",
                                    ));
                              },
                              child: StatBlock(
                                  count: controller.userData.value
                                              ?.followingCount !=
                                          null
                                      ? formatIndianNumber(num.parse(
                                          controller.userData.value
                                                  ?.followingCount
                                                  .toString() ??
                                              "0"))
                                      : "0",
                                  label: "Following"),
                            ),
                            Container(
                              height: 15,
                              width: 0.9,
                              color: AppColors.secondaryTextColor,
                              margin: EdgeInsets.only(
                                  left: SizeConfig.size5,
                                  right: SizeConfig.size5),
                            ),
                            InkWell(
                              onTap: () {
                                Get.to(() => FollowersFollowingPage(
                                      tabIndex: 1,
                                      userID: controller
                                              .userData.value?.user?.id ??
                                          "",
                                    ));
                              },
                              child: StatBlock(
                                  count: formatIndianNumber(
                                      controller.followerCount.value),
                                  label: "Followers"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size5),
                  ///LOCATION AND JOIN DATE VIEW....
                      // if (screenFromName == AppConstants.feedScreen)
                      Row(
                        children: [
                          if (user?.location != null &&
                              (user?.location?.isNotEmpty ?? false)) ...[
                            LocalAssets(
                                imagePath: AppIconAssets.location_new),
                            SizedBox(
                              width: SizeConfig.size5,
                            ),
                            Flexible(
                              child: CustomText(
                                "${user?.location}",
                                fontSize: SizeConfig.size12,
                                overflow: TextOverflow.ellipsis,
                                color: AppColors.mainTextColor,
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.size5,
                            ),
                          ],
                          if (user?.createdAt != null &&
                              (user?.createdAt?.isNotEmpty ?? false)) ...[
                            LocalAssets(
                                imagePath: AppIconAssets.calender_new),
                            SizedBox(
                              width: SizeConfig.size5,
                            ),
                            CustomText(
                              stringDateFormatDate(
                                  dateValue: user?.createdAt ?? ""),
                              fontSize: SizeConfig.size12,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.mainTextColor,
                            ),
                          ],
                        ],
                      ),
                      /*   if (screenFromName == AppConstants.chatScreen)
                        Row(
                          children: [
                            LocalAssets(imagePath: AppIconAssets.calender_new),
                            SizedBox(
                              width: SizeConfig.size5,
                            ),
                            CustomText(
                              "Join US: ",
                              color: Colors.black,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w600,
                            ),
                            CustomText(
                              (user?.createdAt != null)
                                  ? stringDateFormatDate(dateValue: user?.createdAt ?? "")
                                  : "N/A",
                              fontSize: SizeConfig.size12,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.mainTextColor,
                            ),
                          ],
                        ),*/
                    ],
                  ),
                ),
              ],
            ),
          ),
          // SizedBox(height: SizeConfig.size12),

          SizedBox(height: SizeConfig.size5),
/// ADD USER BIO VIEW....
          if ((user?.bio ?? '').trim().isNotEmpty)
            CustomText("     ${user?.bio ?? ''}"),
          SizedBox(height: SizeConfig.size10),
        ],
      ),
    );
  }

  void showPersonalDetailsPopup(BuildContext context) {
    final user = controller.userData.value?.user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomText(
                          user.name,
                          fontSize: SizeConfig.size20,
                          fontWeight: FontWeight.bold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                            height: SizeConfig.size25,
                            width: SizeConfig.size25,
                            child: LocalAssets(
                              imagePath: AppIconAssets.close_white,
                              imgColor: Colors.black,
                            )),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CustomText(
                    user.profession,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size5),
                  Divider(
                    color: AppColors.greyE5,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  _buildDetailRow(
                    icon: AppIconAssets.mail_new,
                    label: 'Email',
                    value: user.email ?? 'Not available',
                  ),
                  SizedBox(height: SizeConfig.size16),
                  _buildDetailRow(
                    icon: AppIconAssets.calender_new,
                    label: 'Birth Day',
                    value: stringDateFormat(
                        day: user.dateOfBirth?.date ?? 0,
                        month: user.dateOfBirth?.month ?? 0,
                        year: user.dateOfBirth?.year ?? 0),
                  ),
                  SizedBox(height: SizeConfig.size16),
                  _buildDetailRow(
                    icon: AppIconAssets.location_new,
                    label: 'Location',
                    value: user.location ?? 'Not available',
                  ),
                  SizedBox(height: SizeConfig.size16),
                  if (controller.channelUserName?.value.isNotEmpty ?? false)
                    _buildDetailRow(
                        icon: AppIconAssets.channel_video_new,
                        label: 'Channel Name',
                        value: "@${controller.channelUserName?.value}",
                        valueColor: AppColors.primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(top: 5),
          child: LocalAssets(
            imagePath: icon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            // color: Colors.red,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.size15,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  value, fontSize: SizeConfig.size16,
                  color: valueColor ?? AppColors.secondaryTextColor,
                  // maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

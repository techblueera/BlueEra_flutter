import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_bio_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../core/api/model/user_profile_res.dart';
import '../visiting_profile_screen.dart';

class NewProfileHeaderWidget extends StatelessWidget {
  NewProfileHeaderWidget({super.key, required this.user});

  final User? user;
  final controller = Get.find<VisitProfileController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size15),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 0, top: 4),
                      child: CircleAvatar(
                        radius: 40,
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
                      height: SizeConfig.size5,
                    ),
                    (controller.channelUserName?.value.isNotEmpty ?? false)
                        ? InkWell(
                      onTap: (){

                        Navigator.pushNamed(
                            context,
                            RouteHelper.getChannelScreenRoute(),
                            arguments: {
                              ApiKeys.argAccountType:user?.accountType,
                              ApiKeys.channelId: controller.channelUserId?.value,
                              ApiKeys.authorId: user?.id
                            }
                        );
                      },
                          child: CustomText(
                              'View Channel',
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryColor,
                              fontSize: SizeConfig.size12,
                            ),
                        )
                        : CustomText(
                            'Channel not\n found',
                            color: AppColors.grey99,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.size12,
                            textAlign: TextAlign.center,
                          ),
                  ],
                ),
                SizedBox(
                  width: SizeConfig.size15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              user?.name ?? 'N/A',
                              fontSize: SizeConfig.size20,
                              fontWeight: FontWeight.w700,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Obx(() {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size10,
                                  vertical: SizeConfig.size3),
                              decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(8)),
                              child: InkWell(
                                  onTap: () async {
                                    if (isGuestUser()) {
                                      createProfileScreen();
                                    } else {
                                      if (controller.isFollow.value) {
                                        await controller.unFollowUserController(
                                            candidateResumeId: user?.id);
                                      } else {
                                        await controller.followUserController(
                                            candidateResumeId: user?.id);
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
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              // offset: const Offset(-6, 36),
                              color: AppColors.white,

                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              onSelected: (value) async {
                                if (value.toUpperCase() == "SHARE") {
                                  final link =
                                      profileDeepLink(userId: user?.id);
                                  final message =
                                      "See my profile on BlueEra:\n$link\n";
                                  await SharePlus.instance.share(ShareParams(
                                    text: message,
                                    subject: user?.name,
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
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await controller.getUserChannelDetailsController(
                                  userId: user?.id);
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
                        ],
                      ),
                      SizedBox(height: SizeConfig.size12),
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
                            stringDateFormatDate(
                                dateValue: user?.createdAt ?? DateTime.now().toString()),
                            fontSize: SizeConfig.size12,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            right: 38.0, top: SizeConfig.size10),
                        child: Row(
                          // mainAxisAlignment:
                          // MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                Get.to(() => FollowersFollowingPage(
                                      tabIndex: 0,
                                      userID:
                                          controller.userData.value?.user?.id ??
                                              "",
                                    ));
                              },
                              child: StatBlock(
                                  count: formatIndianNumber(num.parse(controller
                                          .userData.value?.followingCount
                                          .toString() ??
                                      "0")),
                                  label: "Following"),
                            ),
                            Container(
                              height: 15,
                              width: 0.9,
                              color: AppColors.mainTextColor,
                              margin: EdgeInsets.only(
                                  left: SizeConfig.size5,
                                  right: SizeConfig.size5),
                            ),
                            InkWell(
                              onTap: () {
                                Get.to(() => FollowersFollowingPage(
                                      tabIndex: 1,
                                      userID:
                                          controller.userData.value?.user?.id ??
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
                    ],
                  ),
                ),
              ],
            ),
          ),


          SizedBox(height: SizeConfig.size10),
          if ((user?.bio ?? '').trim().isNotEmpty)
            CustomText(
                user?.bio ?? ''),
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
                        label: 'View Channel',
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

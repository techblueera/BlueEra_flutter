import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/gestures.dart';

import '../../../../../../core/api/model/user_profile_res.dart';
import '../../../../../../widgets/expandable_text.dart';
import '../../../../../../widgets/highlight_text_widget.dart';

class NewProfileHeaderWidget extends StatelessWidget {
  final User? user;
  final String? screenFromName;
  final controller = Get.find<VisitProfileController>();

  NewProfileHeaderWidget({
    super.key,
    required this.user,
    required this.screenFromName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ==== Banner ====
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF8DD0F7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: (user?.profileImage != null &&
                          (user?.profileImage?.isNotEmpty ?? false))
                      ? DecorationImage(
                          image: NetworkImage(user?.profileImage ?? ""),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),

              /// ==== Profile Image ====
              Positioned(
                left: 20,
                bottom: -35,
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.white,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: (user?.profileImage != null &&
                            (user?.profileImage?.isNotEmpty ?? false))
                        ? NetworkImage(user?.profileImage ?? "")
                        : null,
                    backgroundColor: AppColors.primaryColor,
                    child: (user?.profileImage == null ||
                            (user?.profileImage?.isEmpty ?? false))
                        ? CustomText(
                            getInitials(user?.name),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.size20,
                          )
                        : null,
                  ),
                ),
              ),

              /// ==== Follow Button + Menu ====
              Positioned(
                right: 4,
                bottom: -50,
                child: Row(
                  children: [
                    if (user?.id != null)
                      Obx(() {
                        return GestureDetector(
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 4),
                            decoration: BoxDecoration(
                              color: controller.isFollow.value
                                  ? AppColors.colorTextDarkGrey
                                  : AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CustomText(
                                  controller.isFollow.value
                                      ? "Unfollow"
                                      : "Follow",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.size10,
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.person_add_alt,
                                  color: Colors.white,
                                  size: 14,
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    // const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      color: AppColors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (value) async {
                        if (value.toUpperCase() == "SHARE") {
                          final link = profileDeepLink(userId: user?.id);
                          final message = "See my profile on BlueEra:\n$link\n";
                          await SharePlus.instance.share(
                            ShareParams(text: message, subject: user?.name),
                          );
                        }
                      },
                      icon: LocalAssets(imagePath: AppIconAssets.more_vertical),
                      itemBuilder: (context) => popupMenuVisitProfileItems(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 45),

          /// ==== Name + Username ====
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  user?.name ?? '',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (user?.username != null && user!.username!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.secondaryTextColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText(
                          "@${user?.username}",
                          fontSize: SizeConfig.extraSmall,
                          color: Colors.grey[600],
                        ),
                      ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size6),
                      child: Column(
                        children: [
                          if (user?.profession != null &&
                              user?.profession != "null" &&
                              (user?.profession?.isNotEmpty ?? false))
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size10,
                                  vertical: SizeConfig.size4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.secondaryTextColor),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: CustomText(
                                "${user?.profession}",
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.extraSmall,
                              ),
                            ),
                          //const SizedBox(height: 4),
                          Obx(() {
                            return (controller
                                        .channelUserName?.value.isNotEmpty ??
                                    false)
                                ? Row(
                                    children: [
                                      // CustomText(
                                      //   "Visit my channel: ",
                                      //   fontSize: SizeConfig.size12,
                                      // ),
                                      // InkWell(
                                      //   onTap: () {
                                      //     Navigator.pushNamed(
                                      //       context,
                                      //       RouteHelper.getChannelScreenRoute(),
                                      //       arguments: {
                                      //         ApiKeys.argAccountType: user?.accountType,
                                      //         ApiKeys.channelId:
                                      //         controller.channelUserId?.value,
                                      //         ApiKeys.authorId: user?.id,
                                      //       },
                                      //     );
                                      //   },
                                      //   child: CustomText(
                                      //     "@${controller.channelName?.value}",
                                      //     color: AppColors.primaryColor,
                                      //     fontWeight: FontWeight.w600,
                                      //     decoration: TextDecoration.underline,
                                      //     decorationColor: AppColors.primaryColor,
                                      //     fontSize: SizeConfig.size12,
                                      //   ),
                                      // ),
                                    ],
                                  )
                                : const SizedBox();
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // const SizedBox(height: 10),

          /// ==== Profession or Channel ====

          const SizedBox(height: 12),

          /// ==== Stats Row ====
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                statBlock("Post",
                    controller.userData.value?.totalPosts?.toString() ?? "0"),
                const SizedBox(width: 20),

                //  _divider(),
                InkWell(
                  onTap: () {
                    Get.to(() => FollowersFollowingPage(
                        tabIndex: 0, userID: user?.id ?? ""));
                  },
                  child: statBlock(
                      "Following",
                      controller.userData.value?.followingCount?.toString() ??
                          "0"),
                ),
                const SizedBox(width: 20),

                //  _divider(),
                InkWell(
                  onTap: () {
                    Get.to(() => FollowersFollowingPage(
                        tabIndex: 1, userID: user?.id ?? ""));
                  },
                  child: statBlock(
                      "Followers", controller.followerCount.value.toString()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          /// ==== Bio ====
          // if ((user?.bio ?? '').trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
            child: ExpandableText(
              text: user?.bio ?? '',
              trimLines: 3,
              style: TextStyle(
                color: AppColors.mainTextColor,
                fontSize: 14,
                wordSpacing: 0.4,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w400,
                height:
                    1.5, // 👈 increases vertical gap between lines (default is ~1.0)
              ),
              expandMode: ExpandMode.dialog,
              dialogTitle: 'Bio',
            ),
          ),
          //ExpandableText(
          //                 text: viewProfileController
          //                         .personalProfileDetails.value.user?.bio ??
          //                     "",
          //                 trimLines: 3,
          //                 style: TextStyle(
          //                   color: AppColors.mainTextColor,
          //                   fontSize: 14,
          //                   wordSpacing: 0.4,
          //                   letterSpacing: 0.2,
          //                   fontWeight: FontWeight.w400,
          //                   height: 1.5, // 👈 increases vertical gap between lines (default is ~1.0)
          //                 ),
          //                 expandMode: ExpandMode.dialog,
          //                 dialogTitle: 'Bio',
          //               )

          // const SizedBox(height: 8),

          //  const SizedBox(height: 16),

          /// ==== Location + Join Date ====
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
          //   child: Row(
          //     children: [
          //       if (user?.location?.isNotEmpty ?? false) ...[
          //         LocalAssets(imagePath: AppIconAssets.location_new),
          //         const SizedBox(width: 5),
          //         Flexible(
          //           child: CustomText(
          //             user?.location ?? '',
          //             fontSize: SizeConfig.size12,
          //             color: AppColors.mainTextColor,
          //             overflow: TextOverflow.ellipsis,
          //           ),
          //         ),
          //       ],
          //       const SizedBox(width: 10),
          //       if (user?.createdAt?.isNotEmpty ?? false) ...[
          //         LocalAssets(imagePath: AppIconAssets.calender_new),
          //         const SizedBox(width: 5),
          //         CustomText(
          //           stringDateFormatDate(dateValue: user?.createdAt ?? ""),
          //           fontSize: SizeConfig.size12,
          //           color: AppColors.mainTextColor,
          //         ),
          //       ],
          //     ],
          //   ),
          // ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

Widget statBlock(String label, String count) {
  return Row(
    children: [
      CustomText(
        formatNumberLikePost(int.tryParse(count) ?? 0),
        fontSize: SizeConfig.size14,
        fontWeight: FontWeight.w700,
        color: AppColors.mainTextColor,
      ),
      const SizedBox(
        width: 4,
      ),
      CustomText(
        label,
        fontSize: SizeConfig.size14,
        color: AppColors.secondaryTextColor,
      ),
    ],
  );
}

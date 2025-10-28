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
  void _showFullTextDialog(BuildContext context,String text) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: HighlightText(
                      text: text,
                      style: TextStyle(
                        color: AppColors.mainTextColor,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppConstants.OpenSans,
                      )
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const CustomText('Close', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.08),
        //     blurRadius: 6,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
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
                      user!.profileImage!.isNotEmpty)
                      ? DecorationImage(
                    image: NetworkImage(user!.profileImage!),
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
                        user!.profileImage!.isNotEmpty)
                        ? NetworkImage(user!.profileImage!)
                        : null,
                    backgroundColor: AppColors.primaryColor,
                    child: (user?.profileImage == null ||
                        user!.profileImage!.isEmpty)
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

                                Icon(Icons.person_add_alt,color: Colors.white,size: 14,)
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
                          final message =
                              "See my profile on BlueEra:\n$link\n";
                          await SharePlus.instance.share(
                            ShareParams(text: message, subject: user?.name),
                          );
                        }
                      },
                      icon: LocalAssets(
                          imagePath: AppIconAssets.more_vertical),
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
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size10,
                            vertical: SizeConfig.size4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.secondaryTextColor),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: CustomText(
                          "@${user?.username}",
                          fontSize: SizeConfig.extraSmall,
                          color: Colors.grey[600],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size6),
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
                                border: Border.all(color: AppColors.secondaryTextColor),
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
                            return (controller.channelUserName?.value.isNotEmpty ?? false)
                                ? Row(
                              children: [
                                CustomText(
                                  "Visit my channel: ",
                                  fontSize: SizeConfig.size12,
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteHelper.getChannelScreenRoute(),
                                      arguments: {
                                        ApiKeys.argAccountType: user?.accountType,
                                        ApiKeys.channelId:
                                        controller.channelUserId?.value,
                                        ApiKeys.authorId: user?.id,
                                      },
                                    );
                                  },
                                  child: CustomText(
                                    "@${controller.channelName?.value}",
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryColor,
                                    fontSize: SizeConfig.size12,
                                  ),
                                ),
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
                _statBlock(
                    "Post",
                    controller.userData.value?.totalPosts?.toString() ??
                        "0"),
                const SizedBox(width: 20),

                //  _divider(),
                InkWell(
                  onTap: () {
                    Get.to(() => FollowersFollowingPage(
                        tabIndex: 0, userID: user?.id ?? ""));
                  },
                  child: _statBlock(
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
                  child: _statBlock("Followers",
                      controller.followerCount.value.toString()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// ==== Bio ====
         // if ((user?.bio ?? '').trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: user?.bio != null && user!.bio!.isNotEmpty
                        ? user!.bio!
                        : 'No bio available',
                    style: TextStyle(
                      fontSize: SizeConfig.size14,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  TextSpan(
                    text: '   Read More',
                    style: TextStyle(
                      fontSize: SizeConfig.size12,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _showFullTextDialog(context,user?.bio??'');
                      },
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

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

  Widget _statBlock(String label, String count) {
    return Row(
      children: [
        CustomText(
          count,
          fontSize: SizeConfig.size14,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(width: 4,),
        CustomText(
          label,
          fontSize: SizeConfig.size14,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }

}

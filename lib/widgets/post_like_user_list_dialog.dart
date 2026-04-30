import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/all_like_users_list_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostLikeUserListDialog extends StatefulWidget {
  final String postId;

  const PostLikeUserListDialog({super.key, required this.postId});

  @override
  State<PostLikeUserListDialog> createState() => _PostLikeUserListDialogState();
}

class _PostLikeUserListDialogState extends State<PostLikeUserListDialog> {
  var feedController = Get.find<FeedController>();

  @override
  void initState() {
    Get.find<FeedController>()
        .getAllLikesUser(postId: widget.postId, isInitialLoading: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Obx(() {
        if (feedController.allLikeUsersListLoading.isTrue) {
          // 🔹 Shrink dialog to just loader
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (feedController.allLikeUsersOfPostResponse.status ==
            Status.COMPLETE) {
          // 🔹 Actual list with fixed max height
          return Container(
            width: double.maxFinite,
            // constraints: BoxConstraints(
            //   minHeight: SizeConfig.screenHeight * 0.5,
            //   maxHeight: SizeConfig.screenHeight * 0.8,
            // ),
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        'Likes',
                        fontSize: SizeConfig.large18,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    itemCount: feedController.allLikeUsersList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return _UserTile(
                          user: feedController.allLikeUsersList[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (feedController.allLikeUsersOfPostResponse.status ==
            Status.ERROR) {
          Get.back();
        }

        return SizedBox();
      }),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final LikeUserData user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size20, vertical: SizeConfig.size10),
      child: InkWell(
        onTap: () {
          Get.back();
          redirectToProfileScreen(
              accountType: user.accountType ?? "",
              profileId:
                  user.accountType?.toUpperCase() == AppConstants.business
                      ? user.business_id ?? ""
                      : user.sId ?? "");
        },
        child: Row(
          children: [
            InkWell(
              onTap: () {
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: AppStrings.imageViewer,
                    // imageUrls: [post?.author.profileImage ?? ''],
                    imageUrls: [user.profileImage ?? ""],
                    initialIndex: 0,
                  ),
                );
              },
              child: CachedAvatarWidget(
                  imageUrl: user.profileImage ?? "",
                  size: SizeConfig.size42,
                  borderColor: AppColors.primaryColor,
                  borderRadius: SizeConfig.size25),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    user.accountType?.toUpperCase() == AppConstants.business
                        ? "${user.business_name}"
                        : user.name ?? "User",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomText(
                    user.accountType?.toUpperCase() == AppConstants.business
                        ? user.business_category ??
                            user.categoryOfBusiness ??
                            "Other"
                        : user.designation?.toLowerCase() != "null"
                            ? "${user.designation ?? "Other"}"
                            : "Other",
                    fontSize: SizeConfig.small,
                    color: Colors.grey.shade600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // _FollowButton(
            //   initiallyFollowing: user.isFollowing ?? false,
            //   onPressed: () {
            //     // TODO: Handle API call for follow/unfollow
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

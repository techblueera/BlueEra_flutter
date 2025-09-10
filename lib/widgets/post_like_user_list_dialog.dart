import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/all_like_users_list_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
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
  var feedController= Get.find<FeedController>();

  @override
  void initState() {
    Get.find<FeedController>().getAllLikesUser(postId: widget.postId, isInitialLoading: true);
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

        if(feedController.allLikeUsersOfPostResponse.status == Status.COMPLETE) {
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
                        fontSize: SizeConfig.extraLarge22,
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
                ListView.builder(
                  itemCount: feedController.allLikeUsersList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return _UserTile(
                        user: feedController.allLikeUsersList[index]
                    );
                  },
                ),
              ],
            ),
          );
        }else if(feedController.allLikeUsersOfPostResponse.status == Status.ERROR){
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [

          InkWell(
            onTap: () {
                  navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: AppLocalizations.of(context)!.imageViewer,
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
                borderRadius: SizeConfig.size25
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  user.name ?? "",
                ),
                CustomText(
                  user.username ?? "",
                  fontSize: SizeConfig.small,
                  color: Colors.grey.shade600,
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
    );
  }
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({
    required this.onPressed,
    this.initiallyFollowing = true,
  });

  final bool initiallyFollowing;
  final VoidCallback onPressed;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initiallyFollowing;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isFollowing = !_isFollowing);
        widget.onPressed();
      },
      child: AnimatedContainer(
        width: 100,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isFollowing ? Colors.white10 : AppColors.primaryColor,
          border: Border.all(
            color: _isFollowing ? AppColors.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: _isFollowing ? AppColors.primaryColor : Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

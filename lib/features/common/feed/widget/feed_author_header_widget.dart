import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/feed_profile_navigation.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_option_popup_menu.dart';
import 'package:BlueEra/widgets/block_user_dialog.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';

void openMeOverview() {
  if (Get.isRegistered<BottomBarController>()) {
    Get.until((route) => route.isFirst);
    Get.find<BottomBarController>().openMeOverviewTab();
  } else {
    Get.offAllNamed(
      RouteHelper.getBottomNavigationBarScreenRoute(),
      arguments: {ApiKeys.initialIndex: BottomBarController.meTabIndex},
    );
  }
}
/// The byline: avatar, then the display name and `@handle` sharing one line,
/// with the designation chip on the line beneath.
///
/// This replaced [ChannelProfileHeader] on feed cards. The two had diverged —
/// that widget stacks the handle under the name and ends with a
/// designation-plus-timestamp row, whereas the card now shows the timestamp in
/// its stats strip instead. [ChannelProfileHeader] is untouched and still used
/// by the post-preview and video-player screens.
class _AuthorIdentity extends StatelessWidget {
  const _AuthorIdentity({
    required this.imageUrl,
    required this.title,
    required this.userName,
    required this.designation,
  });

  final String imageUrl;
  final String title;
  final String userName;
  final String designation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CachedAvatarWidget(
          imageUrl: imageUrl,
          size: SizeConfig.size48,
          borderRadius: SizeConfig.size48 / 2,
          borderColor: AppColors.shadowColor,
          showProfileOnFullScreen: false,
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // Both names are Flexible so a long display name yields to
                  // the handle rather than pushing it off the row entirely.
                  Flexible(
                    child: CustomText(
                      title,
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (userName.isNotEmpty) ...[
                    SizedBox(width: SizeConfig.size6),
                    Flexible(
                      child: CustomText(
                        '@$userName',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (designation.trim().isNotEmpty) ...[
                SizedBox(height: SizeConfig.size6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size12,
                    vertical: SizeConfig.size4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.greyE5),
                  ),
                  child: CustomText(
                    designation,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class PostAuthorHeader extends StatelessWidget {
  final Post? post;
  final String authorId;
  final PostType postType;
  final VoidCallback? onTapAvatar;
  final VoidCallback? onTapOptions;
  final String? postedAgo;
  final bool? isRepost;

  /// Channel name coming from the channel screen (channel feed context).
  /// When the post is created via channel this takes priority over the
  /// per-post [Post.channelName] so the channel feed always shows the
  /// correct channel name. Null in the global feed, where we fall back
  /// to the per-post value.
  final String? channelName;

  const PostAuthorHeader({
    super.key,
    required this.post,
    required this.authorId,
    required this.postType,
    this.onTapAvatar,
    this.onTapOptions,
    this.postedAgo,
    this.isRepost = false,
    this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    logs(" post?.post_via ${post?.post_via} | passedChannelName $channelName"
        " | post.channel?.name ${post?.channel?.name}"
        " | post.channelName ${post?.channelName}");
    String name =
        (post?.user?.accountType?.toUpperCase() == AppConstants.individual)
            ? post?.user?.name ?? 'User'
            : post?.user?.businessName ?? 'User';

    String designation =
        (post?.user?.accountType?.toUpperCase() == AppConstants.individual)
            ? post?.user?.designation ?? "OTHERS"
            : (post?.user?.categoryOfBusiness?.isNotEmpty ?? false)
                ? post?.user?.categoryOfBusiness ?? 'OTHERS'
                : 'OTHERS';

    String id =
        (post?.user?.accountType?.toUpperCase() == AppConstants.individual)
            ? authorId
            : post?.user?.business_id ?? '';

    return Padding(
      padding: EdgeInsets.only(

          // right: SizeConfig.size10,
          left: SizeConfig.size15,
          top: SizeConfig.size10,
          bottom: SizeConfig.size5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (((authorId == userId) ||
                        (post?.user?.business_id == businessId)) &&
                    (postType == PostType.myPosts ||
                        postType == PostType.saved)) {
                  return;
                }
                // Every feed profile tap goes through the one resolver, so a
                // tapped lab/restaurant/pharmacy opens ITS screen rather than
                // the generic business profile. `authorId` is passed
                // explicitly: on a channel post the header shows the channel
                // but the tap must still open the author this widget was built
                // for.
                openFeedProfile(post?.user?.copyWith(id: authorId));
              },
              child: _AuthorIdentity(
                imageUrl: post?.user?.profileImage ?? '',
                title: post?.post_via == "channel"
                    ? (channelName ??
                        post?.channel?.name ??
                        post?.channelName ??
                        name)
                    : name,
                userName: post?.user?.username ?? '',
                designation: designation != "null" ? designation : 'OTHERS',
              ),
            ),
          ),
          if (isRepost == false) ...[
            if (post?.user?.accountType == AppConstants.individual)
              if (id != userId)
                Container(
                  height: 20,
                  width: 20,
                  margin: EdgeInsets.only(right: SizeConfig.size15),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    // offset: const Offset(-6, 36),
                    color: AppColors.white,

                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (value) async {
                      onTapFunction(valueData: value, contextBuild: context);
                    },
                    icon: LocalAssets(imagePath: AppIconAssets.more_vertical),
                    itemBuilder: (context) =>
                        PopupMenuBuilders.popupMenuVisitProfileActionItems(
                            isSavePost: (post?.isPostSavedLocal ?? false)),
                  ),
                )
              else
                FeedPopUpMenu(
                  post: post ?? Post(id: ''),
                  postFilteredType: postType,
                )
            else if (post?.user?.accountType == AppConstants.business)
              if (id != businessId)
                Container(
                  height: 20,
                  width: 20,
                  margin: EdgeInsets.only(right: SizeConfig.size12),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    // offset: const Offset(-6, 36),
                    color: AppColors.white,

                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (value) async {
                      onTapFunction(valueData: value, contextBuild: context);
                    },
                    icon: LocalAssets(imagePath: AppIconAssets.more_vertical),
                    itemBuilder: (context) =>
                        PopupMenuBuilders.popupMenuVisitProfileActionItems(),
                  ),
                )
              else
                FeedPopUpMenu(
                    post: post ?? Post(id: ''), postFilteredType: postType)
          ],
        ],
      ),
    );
  }

  void onTapFunction(
      {required String valueData, required BuildContext contextBuild}) {
    String value = valueData.toUpperCase();
    if (value == "SAVE") {
      Get.find<FeedController>().savePostToLocalDB(
        postId: post?.id ?? '0',
        type: postType,
      );
    }
    if (value == "BLOCK USER") {
      if (isGuestUser()) {
        createProfileScreen();
      } else {
        blockUserPopUp(postType: postType, postData: post ?? Post(id: ''));
      }
    }
    if (value == "REPORT POST") {
      if (isGuestUser()) {
        createProfileScreen();
      } else {
        postReportPopUp(postData: post ?? Post(id: ''), postType: postType);
      }
    }
    // if (value == "REPOST") {
    //   if (isGuestUser()) {
    //     createProfileScreen();
    //   } else {
    //     rePostYourFeed(contextBuild: contextBuild, originalPostID: post?.id);
    //   }
    // }
  }

  void blockReportUserPopUp() {
    openBlockSelectionDialog(
        context: Get.context!,
        userId: authorId,
        contentId: post?.id ?? '',
        reportType: 'POST',
        userBlockVoidCallback: () {
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          Get.find<FeedController>()
              .userBlocked(otherUserId: post?.user?.id ?? '', type: postType);
        },
        reportCallback: (params) async {
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          Get.find<FeedController>().postReport(
              postId: post?.id ?? '', type: postType, params: params);
        });
  }
}

void blockUserPopUp({required Post postData, required PostType postType}) {
  showDialog(
    context: Get.context!,
    builder: (context) => BlockUserDialog(
      onConfirm: () {
        if (isGuestUser()) {
          createProfileScreen();

          return;
        }
        Get.find<FeedController>()
            .userBlocked(otherUserId: postData.user?.id ?? '', type: postType);
      },
      userName: postData.user?.name,
    ),
  );
}

void postReportPopUp({required Post postData, required PostType postType}) {
  Get.back();
  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Material(
            color: AppColors.white,
            child: ReportDialog(
              reportType: "POST",
              reportReasons: {
                'Sexual content': false,
                'Violent or repulsive content': false,
                'Hateful or abusive content': false,
                'Harassment or bullying': false,
                'Harmful or dangerous act': false,
                'Suicide, self harm or eating disorder': false,
                'Misinformation': false,
                'Child abuse': false,
                'Promotes terrorism': false,
                'Spam or misleading': false,
                'Legal issue': false,
              },
              contentId: postData.id,
              otherUserId: postData.user?.id ?? "",
              reportCallback: (params) async {
                if (isGuestUser()) {
                  createProfileScreen();

                  return;
                }
                Get.find<FeedController>().postReport(
                    postId: postData.id, type: postType, params: params);
              },
            ),
          ),
        ),
      );
    },
  );
}

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/translator_function.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_reference_widget.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_repost_screen.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/feed_tag_people_bottom_sheet.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/common/feed/view/twitter_post_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';
import 'social_message_post_grid_widget.dart';

bool shouldShowTranslate(String text) {
  // Returns true if the text contains non-English characters
  return RegExp(r'[^\x00-\x7F]+').hasMatch(text);
}

class MessagePostWidget extends StatefulWidget {
  final Post? post;
  final Widget Function() authorSection;
  final Widget Function() buildActions;
  final VoidCallback commentView;
  final VoidCallback likeFeed;
  final VoidCallback onShareButtonPressed;
  final double? horizontalPadding;
  final double? bottomPadding;
  final bool? isRepost;
  final bool? isShowOnlyDetails;
  final PostType? postType;
  final SortBy? sortBy;

  MessagePostWidget({
    super.key,
    required this.post,
    required this.authorSection,
    required this.buildActions,
    required this.commentView,
    required this.likeFeed,
    this.horizontalPadding,
    this.bottomPadding,
    this.isRepost = false,
    this.isShowOnlyDetails = false,
    required this.onShareButtonPressed,
    this.postType,
    this.sortBy,
  });

  @override
  State<MessagePostWidget> createState() => _MessagePostWidgetState();
}

class _MessagePostWidgetState extends State<MessagePostWidget> {
  late Post _post;
  late String subTitle;
  late String natureOfPost;
  String languageCode = 'en';
  ShortFeedItem? videoData;
  late FeedTranslationController transController;

  @override
  void initState() {
    super.initState();
    videoData = getVideoData(widget.post!);
    updateData();
    transController = Get.put(
      FeedTranslationController(),
      tag: _post.id.toString(),
    );
    transController.loadText(_post.title?.trim() ?? "", subTitle.trim());
  }

  @override
  void dispose() {
    Get.delete<FeedTranslationController>(tag: _post.id.toString());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessagePostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      updateData();
    }
  }

  void updateData() {
    _post = widget.post!;
    subTitle = _post.subTitle ?? '';
    natureOfPost = _post.natureOfPost ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.isRepost == true ? true : false,
      child: InkWell(
        onTap: () {
          // Open Twitter-style detail screen with inline comments
          Get.to(() => TwitterPostDetailScreen(
                post: _post,
                postType: widget.postType ?? PostType.all,
                sortBy: widget.sortBy,
              ));
        },
        child: Container(
          color: AppColors.lightBlueE9,
          // color: AppColors.white,
          margin: EdgeInsetsDirectional.only(top: 12),
          // margin: EdgeInsetsDirectional.zero,

          child: FeedCardWidget(
              horizontalPadding: widget.horizontalPadding,
              bottomPadding: widget.bottomPadding,
              childWidget: Column(
                children: [
                  widget.authorSection(),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: SizeConfig.size1, left: SizeConfig.size15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_post.title?.isNotEmpty ?? false) ...[
                              Padding(
                                padding: EdgeInsets.only(
                                  left: SizeConfig.size15,
                                  right: SizeConfig.size15,
                                ),
                                child: Obx(() {
                                  return CustomText(
                                    // _post.title,
                                    transController.currentTitleText.value,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    // fontSize: SizeConfig.large,
                                  );
                                }),
                              ),
                            ],
                            // Inside your Column
                            // ... inside your Widget tree
                            if (subTitle.isNotEmpty) ...[
                              Obx(() => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: SizeConfig.size15,
                                            right: SizeConfig.size15),
                                        child: ExpandableText(
                                          // Use the text from the controller
                                          // text:"Gemini said Birds are feathered, warm-blooded vertebrates that lay hard-shelled eggs. Known for their lightweight skeletons and wings, most species possess the remarkable ability to fly and inhabit every global ecosystem.",
                                          text:
                                              transController.currentText.value,
                                          trimLines: 4,
                                          expandMode: ExpandMode.dialog,
                                          style: TextStyle(
                                              color: AppColors.mainTextColor,
                                              fontFamily: AppConstants.OpenSans,
                                              fontWeight: FontWeight.w400,
                                              fontSize: SizeConfig.size15),
                                        ),
                                      ),

                                      // Show Translate Option if NOT English OR if already translated (to allow toggle back)
                                      if (!transController.translator
                                              .isEnglishText(subTitle) ||
                                          transController.isTranslated.value)
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: SizeConfig.size15,
                                              top: 4,
                                              bottom: 5),
                                          child: InkWell(
                                            onTap: () => transController
                                                .toggleTranslation(),
                                            child: transController
                                                    .isLoading.value
                                                ? SizedBox(
                                                    height: 12,
                                                    width: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColors
                                                                .primaryColor))
                                                : CustomText(
                                                    transController
                                                            .isTranslated.value
                                                        ? "Show Original"
                                                        : "Translate to English",
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontSize: SizeConfig.size12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  )),
                              SizedBox(height: SizeConfig.size5),
                            ],
                          ],
                        ),
                        if (_post.referenceLink?.isNotEmpty ?? false)
                          Padding(
                            padding: EdgeInsets.only(
                                left: SizeConfig.size15,
                                right: SizeConfig.size15,
                                bottom: SizeConfig.size10,
                                top: SizeConfig.size5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                // The light blue background color from the image
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded "pill" shape
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LocalAssets(
                                    imagePath: AppIconAssets.link,
                                    imgColor: AppColors.primaryColor,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Flexible(
                                      child: ClickableLinkText(
                                          url: _post.referenceLink!,)),
                                ],
                              ),
                            ),
                          ),
                        /* Padding(
                            padding: EdgeInsets.only(
                                left: SizeConfig.size15,
                                right: SizeConfig.size15,
                                bottom: SizeConfig.size10,
                                top: SizeConfig.size5),
                            child: ClickableLinkText(url: _post.referenceLink!),
                          ),*/
                        if (_post.taggedUsers?.isNotEmpty ?? false) ...[
                          Padding(
                            padding: EdgeInsets.only(
                                left: SizeConfig.size15,
                                right: SizeConfig.size15,
                                top: SizeConfig.size10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Show first 3 users
                                ...?_post.taggedUsers?.take(2).map(
                                      (user) => UserChipFeed(
                                        user: user,
                                      ),
                                    ),

                                // If more than 3, show +remaining count
                                if ((_post.taggedUsers?.length ?? 0) > 2)
                                  InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            FeedTagPeopleBottomSheet(
                                                taggedUser:
                                                    _post.taggedUsers ?? []),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size10,
                                          vertical: SizeConfig.size3),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightBlue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: CustomText(
                                        '+${(_post.taggedUsers?.length ?? 0) - 2}',
                                        color: AppColors.mainTextColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: SizeConfig.size12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        ],
                        if (_post.media?.isNotEmpty ?? false) ...[
                          if ((_post.media_types?.firstOrNull
                                      ?.startsWith("video/") ??
                                  false) ||
                              isVideoUrl(_post.media?.firstOrNull)) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                  left: SizeConfig.size5,
                                  right: SizeConfig.size5,
                                  top: SizeConfig.size10),
                              child: PostFeedAutoPlayVideoCard(
                                videoItem: videoData!,
                                globalMuteNotifier: ValueNotifier(false),
                                videoType: VideoType.videoFeed,
                                onTapOption: () {
                                  openBlockSelectionDialog(
                                      context: context,
                                      reportType: 'VIDEO_POST',
                                      userId: videoData?.video?.userId ?? '',
                                      contentId: videoData?.video?.id ?? '',
                                      userBlockVoidCallback: () async {
                                        await Get.find<VideoController>()
                                            .userBlocked(
                                          videoType: VideoType.videoFeed,
                                          otherUserId:
                                              videoData?.video?.userId ?? '',
                                        );
                                      },
                                      reportCallback: (params) {
                                        Get.find<VideoController>()
                                            .videoPostReport(
                                                videoId:
                                                    videoData?.video?.id ?? '',
                                                videoType: VideoType.videoFeed,
                                                params: params);
                                      });
                                },
                              ),
                            ),
                          ],
                          if ((_post.media_types?.firstOrNull
                                      ?.startsWith("image/") ??
                                  false) ||
                              isImageUrl(_post.media?.firstOrNull))
                            Padding(
                              padding: EdgeInsets.only(
                                  left: SizeConfig.size15,
                                  right: SizeConfig.size15),
                              child: SocialImageGrid(
                                imageUrls: _post.media ?? [],
                                subTitle: _post.subTitle ?? "",
                                postData: _post,
                              ),
                            ),
                        ],
                        if (!(widget.isShowOnlyDetails ?? true)) ...[
                          if (widget.post?.is_reposted ?? false) ...[
                            // if (widget.isRepost ?? false) ...[
                            ((widget.post?.children_post?.media?.isNotEmpty ??
                                    false))
                                ? Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size15,
                                      vertical: SizeConfig.size8,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        openProfileToClickUser();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors
                                                  .secondaryTextColor
                                                  .withValues(alpha: 0.2)),
                                          color: AppColors
                                              .white, // light background
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.only(
                                                  top: SizeConfig.size10,
                                                  left: SizeConfig.size10),
                                              child: Row(
                                                children: [
                                                  CachedAvatarWidget(
                                                      imageUrl: widget
                                                          .post
                                                          ?.children_post
                                                          ?.user
                                                          ?.profileImage,
                                                      size: 30.0,
                                                      borderRadius: 25),
                                                  SizedBox(
                                                    width: SizeConfig.size10,
                                                  ),
                                                  Expanded(
                                                    child: SizedBox(
                                                      width: Get.width,
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Flexible(
                                                            child: CustomText(
                                                              widget
                                                                  .post
                                                                  ?.children_post
                                                                  ?.user
                                                                  ?.name,
                                                              fontSize:
                                                                  SizeConfig
                                                                      .large,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              color: AppColors
                                                                  .secondaryTextColor,
                                                            ),
                                                          ),
                                                          if (widget
                                                                      .post
                                                                      ?.children_post
                                                                      ?.user
                                                                      ?.username !=
                                                                  null &&
                                                              (widget
                                                                      .post
                                                                      ?.children_post
                                                                      ?.user
                                                                      ?.username
                                                                      ?.isNotEmpty ??
                                                                  false))
                                                            Expanded(
                                                              child: Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        top: 0),
                                                                child:
                                                                    CustomText(
                                                                  " @${widget.post?.children_post?.user?.username}",
                                                                  fontSize:
                                                                      SizeConfig
                                                                          .medium,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  color: AppColors
                                                                      .shadowColor,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: SizeConfig.size10,
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 110,
                                                  height: 110,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 8.0),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Container(
                                                        color: Colors.black,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: ((_post
                                                                          .children_post
                                                                          ?.media_types
                                                                          ?.firstOrNull
                                                                          ?.startsWith(
                                                                              "video/") ??
                                                                      false) ||
                                                                  isVideoUrl(_post
                                                                      .children_post
                                                                      ?.media
                                                                      ?.firstOrNull))
                                                              ? widget
                                                                      .post
                                                                      ?.children_post
                                                                      ?.thumbnail ??
                                                                  ""
                                                              : widget
                                                                      .post
                                                                      ?.children_post
                                                                      ?.media
                                                                      ?.first ??
                                                                  "",
                                                          width: 110,
                                                          height: 110,
                                                          fit: BoxFit.cover,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Container(
                                                            width: 110,
                                                            height: 110,
                                                            color: Colors
                                                                .grey[300],
                                                            // child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.person,
                                                                  size: 42 / 2),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // RIGHT: Text Section
                                                Expanded(
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: SizeConfig.size10,
                                                        right:
                                                            SizeConfig.size10),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if ((widget
                                                                .post
                                                                ?.children_post
                                                                ?.title
                                                                ?.isNotEmpty ??
                                                            false))
                                                          CustomText(
                                                            widget
                                                                    .post
                                                                    ?.children_post
                                                                    ?.title ??
                                                                "",
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .mainTextColor,
                                                          ),
                                                        SizedBox(height: 4),
                                                        CustomText(
                                                          widget
                                                                  .post
                                                                  ?.children_post
                                                                  ?.subTitle ??
                                                              "",
                                                          maxLines: 4,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color: AppColors
                                                              .secondaryTextColor,
                                                          fontSize:
                                                              SizeConfig.size13,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: SizeConfig.size10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : InkWell(
                                    onTap: () {
                                      openProfileToClickUser();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: SizeConfig.size15,
                                      ),
                                      child: FeedCard(
                                          post: widget.post?.children_post,
                                          index: 0,
                                          postFilteredType: PostType.otherPosts,
                                          horizontalPadding: 0,
                                          isRepost: true),
                                    ),
                                  ),
                          ],
                        ],
                        if (widget.isRepost == false) ...[
                          SizedBox(
                            height: SizeConfig.size5,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size12,
                                vertical: SizeConfig.size6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Views
                                _feedActionButton(
                                  iconPath: AppIconAssets.eye_new,
                                  count: formatNumberLikePost(_post.viewsCount ?? 0),
                                ),

                                // Comment
                                _feedActionButton(
                                  iconPath: AppIconAssets.comment_new,
                                  count: formatNumberLikePost(_post.commentsCount ?? 0),
                                  onTap: () {
                                    if (isGuestUser()) {
                                      createProfileScreen();
                                    } else {
                                      widget.commentView();
                                    }
                                  },
                                ),
                                // Like
                                _feedActionButton(
                                  iconPath: AppIconAssets.like_new,
                                  count: formatNumberLikePost(_post.likesCount ?? 0),
                                  iconColor: (widget.post?.isLiked ?? false)
                                      ? AppColors.primaryColor
                                      : AppColors.secondaryTextColor,
                                  onTap: () {
                                    if (isGuestUser()) {
                                      createProfileScreen();
                                    } else {
                                      widget.likeFeed();
                                    }
                                  },
                                ),
                                // Repost
                                if (widget.post?.type?.toLowerCase() == "message_post")
                                  _feedActionButton(
                                    iconPath: AppIconAssets.repost_new,
                                    count: formatNumberLikePost(_post.repostCount ?? 0),
                                    onTap: () {
                                      if (isGuestUser()) {
                                        createProfileScreen();
                                        return;
                                      }
                                      _showRepostDialog();
                                    },
                                  ),

                                // Share
                                _feedActionButton(
                                  iconPath: AppIconAssets.share_bold,
                                  count: '',
                                  onTap: () => widget.onShareButtonPressed(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size5,
                          ),
                          widget.buildActions(),
                          // SizedBox(
                          //   height: SizeConfig.size10,
                          // ),
                        ],
                      ],
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }

  Widget _feedActionButton({
    required String iconPath,
    required String count,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size6, vertical: SizeConfig.size6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: iconPath,
              width: SizeConfig.size20,
              height: SizeConfig.size20,
              imgColor: iconColor ?? AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              count,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.size12,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showRepostDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: SizeConfig.size20),
                    InkWell(
                      onTap: () async {
                        Get.put(MessagePostController());
                        Get.back();
                        ResponseModel responseModel =
                            await PostRepo().addRePostNewRepo(
                          reqDataData: {
                            ApiKeys.type: AppConstants.MESSAGE_POST,
                            ApiKeys.repostId: widget.post?.id ?? "",
                          },
                        );
                        if (responseModel.isSuccess) {
                          commonSnackBar(
                              message: AppStrings.repostedSuccessfully);
                          Get.find<NavigationHelperController>()
                              .shouldRefreshBottomBar
                              .value = true;
                          Get.until((route) =>
                              route.settings.name ==
                              RouteHelper
                                  .getBottomNavigationBarScreenRoute());
                        } else {
                          commonSnackBar(
                              message: AppStrings.alreadyReposted);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: SizeConfig.size30,
                            height: SizeConfig.size30,
                            child: LocalAssets(
                              imagePath: AppIconAssets.repost_new,
                              width: SizeConfig.size30,
                              height: SizeConfig.size30,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.Repost,
                                    textAlign: TextAlign.left,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.size16,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.sharePostWithFollowers,
                                    textAlign: TextAlign.left,
                                    color:
                                        AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.size13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: SizeConfig.size10,
                          bottom: SizeConfig.size10),
                      child: Divider(
                          color: AppColors.secondaryTextColor),
                    ),
                    InkWell(
                      onTap: () {
                        Get.back();
                        Get.to(CreateMessagePostScreenRepost(
                          isEdit: false,
                          post: widget.post,
                        ));
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: SizeConfig.size30,
                            height: SizeConfig.size30,
                            child: LocalAssets(
                              imagePath: AppIconAssets.pencilIcon,
                              width: SizeConfig.size20,
                              height: SizeConfig.size20,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.addYourThings,
                                    textAlign: TextAlign.left,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.size16,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.addCommentBeforeShare,
                                    textAlign: TextAlign.left,
                                    color:
                                        AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.size13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  openProfileToClickUser() {
    Post? data = widget.post?.children_post;
    String? authorId = data?.user?.id;
    String? userBusinessId = data?.user?.id;
    String? userAccountType = data?.user?.accountType?.toUpperCase();
    if (userAccountType == AppConstants.individual) {
      if (userId == authorId) {
        navigatePushTo(context, PersonalProfileSetupNewScreen());
      } else {
        Get.to(() => NewVisitProfileScreen(
              authorId: authorId ?? "",
              screenFromName: AppConstants.feedScreen,
            ));
      }
    }
    if (userAccountType == AppConstants.business) {
      if (businessId == userBusinessId) {
        navigatePushTo(context, BusinessOwnProfileScreen());
      } else {
        Get.to(() => VisitBusinessProfileNew(
              businessId: userBusinessId ?? "",
              screenName: AppConstants.feedScreen,
            ));
      }
    }
  }
}

ViewFeedActionWidget({required String iconPath, required String data}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      LocalAssets(
        imagePath: iconPath,
        width: SizeConfig.size24,
        height: SizeConfig.size24,
      ),
      SizedBox(
        width: SizeConfig.size3,
      ),
      Flexible(
        child: CustomText(
          data,
          color: AppColors.secondaryTextColor,
          fontSize: SizeConfig.size12,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

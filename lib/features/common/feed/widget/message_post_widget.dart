import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';
import 'social_message_post_grid_widget.dart';

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

  @override
  void initState() {
    super.initState();
    videoData = getVideoData(widget.post!);
    updateData();
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
                            child: CustomText(
                              _post.title,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.bold,
                              // fontSize: SizeConfig.large,
                            ),
                          ),
                        ],
                        if (subTitle.isNotEmpty) ...[
                          Container(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: SizeConfig.size15,
                                right: SizeConfig.size15,
                              ),
                              child: ExpandableText(
                                text: subTitle.trim(),
                                trimLines: 5,
                                expandMode: ExpandMode.dialog,
                                style: TextStyle(
                                  color: AppColors.mainTextColor,
                                  fontFamily: AppConstants.OpenSans,
                                  fontWeight: FontWeight.w400,
                                  fontSize: SizeConfig.size15
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size5,
                          ),
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
                        child: ClickableLinkText(url: _post.referenceLink!),
                      ),
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
                      if ((_post.media_types?.firstOrNull?.startsWith("video/") ?? false) ||
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
                                    Get.find<VideoController>().videoPostReport(
                                        videoId: videoData?.video?.id ?? '',
                                        videoType: VideoType.videoFeed,
                                        params: params);
                                  });
                            },
                          ),
                        ),
                      ],
                      if ((_post.media_types?.firstOrNull?.startsWith("image/") ?? false) ||
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
                                    // Get.to(MessagePostDetailsScreen(
                                    //   post: _post,
                                    //   postType: PostType.all
                                    //   ,
                                    // ));
                                    openProfileToClickUser();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.secondaryTextColor
                                              .withValues(alpha: 0.2)),
                                      color:
                                          AppColors.white, // light background
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
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Flexible(
                                                        child: CustomText(
                                                          widget
                                                              .post
                                                              ?.children_post
                                                              ?.user
                                                              ?.name,
                                                          fontSize:
                                                              SizeConfig.large,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
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
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 0),
                                                            child: CustomText(
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
                                                padding:
                                                    EdgeInsets.only(left: 8.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Container(
                                                    color: Colors.black,
                                                    child: CachedNetworkImage(
                                                      imageUrl: widget
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
                                                        color: Colors.grey[300],
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
                                                    right: SizeConfig.size10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .mainTextColor,
                                                      ),
                                                    SizedBox(height: 4),
                                                    CustomText(
                                                      widget.post?.children_post
                                                              ?.subTitle ??
                                                          "",
                                                      maxLines: 4,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                            horizontal: SizeConfig.size15,
                            vertical: SizeConfig.size5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ViewFeedActionWidget(
                                iconPath: AppIconAssets.clock_new,
                                data: timeAgo(_post.createdAt != null
                                    ? _post.createdAt ?? DateTime.now()
                                    : DateTime.now())),
                            ViewFeedActionWidget(
                              iconPath: AppIconAssets.eye_new,
                              data: formatNumberLikePost(_post.viewsCount ?? 0),
                            ),
                            InkWell(
                              onTap: () {
                                if (isGuestUser()) {
                                  createProfileScreen();
                                } else {
                                  widget.commentView();
                                }
                              },
                              child: ViewFeedActionWidget(
                                  iconPath: AppIconAssets.comment_new,
                                  data: formatNumberLikePost(
                                      _post.commentsCount ?? 0)),
                            ),
                            InkWell(
                              onTap: () {
                                if (isGuestUser()) {
                                  createProfileScreen();
                                } else {
                                  widget.likeFeed();
                                }
                                // if ((_post.likesCount ?? 0) < 1) {
                                //   return;
                                // }

                                // showDialog(
                                //   context: context,
                                //   builder: (context) => PostLikeUserListDialog(
                                //     postId: widget.post?.id ?? '',
                                //   ),
                                // );
                              },
                              child: Padding(
                                padding:
                                    EdgeInsets.only(right: SizeConfig.size10),
                                child: Row(
                                  children: [
                                    LocalAssets(
                                      imagePath: AppIconAssets.like_new,
                                      width: SizeConfig.size18,
                                      height: SizeConfig.size18,
                                      imgColor: (widget.post?.isLiked ?? false)
                                          ? AppColors.primaryColor
                                          : AppColors.secondaryTextColor,
                                    ),
                                    SizedBox(
                                      width: SizeConfig.size5,
                                    ),
                                    CustomText(
                                      formatNumberLikePost(
                                          _post.likesCount ?? 0),
                                      color: AppColors.secondaryTextColor,
                                      fontSize: SizeConfig.size10,
                                    ),
                                  ],
                                ),
                              )
                              ,
                            ),
                            if (widget.post?.type?.toLowerCase() ==
                                "message_post")
                              InkWell(
                                onTap: () {
                                  if (isGuestUser()) {
                                    createProfileScreen();

                                    return;
                                  }
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return Dialog(
                                        insetPadding: EdgeInsets.symmetric(
                                            horizontal: SizeConfig.size20),
                                        backgroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 800),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      SizeConfig.size15),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                      height:
                                                          SizeConfig.size20),
                                                  InkWell(
                                                    onTap: () async {
                                                      Get.put(
                                                          MessagePostController());

                                                      ///REPOST MESSAGE AND POLL POST...
                                                      Get.back();
                                                      ResponseModel
                                                          responseModel =
                                                          await PostRepo()
                                                              .addRePostNewRepo(
                                                        reqDataData: {
                                                          ApiKeys.type:
                                                              AppConstants
                                                                  .MESSAGE_POST,
                                                          ApiKeys.repostId:
                                                              widget.post?.id ??
                                                                  ""
                                                        },
                                                      );
                                                      if (responseModel
                                                          .isSuccess) {
                                                        commonSnackBar(
                                                            message:
                                                                "Reposted successfully");
                                                        Get.find<
                                                                NavigationHelperController>()
                                                            .shouldRefreshBottomBar
                                                            .value = true;
                                                        Get.until((route) =>
                                                            route.settings
                                                                .name ==
                                                            RouteHelper
                                                                .getBottomNavigationBarScreenRoute());
                                                      } else {
                                                        commonSnackBar(
                                                            message:
                                                                "You have already reposted this post");
                                                      }
                                                    },
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width:
                                                              SizeConfig.size30,
                                                          height:
                                                              SizeConfig.size30,
                                                          child: LocalAssets(
                                                            imagePath:
                                                                AppIconAssets
                                                                    .repost_new,
                                                            width: SizeConfig
                                                                .size30,
                                                            height: SizeConfig
                                                                .size30,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        SizeConfig
                                                                            .size10),
                                                                child:
                                                                    CustomText(
                                                                  "Repost",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      SizeConfig
                                                                          .size16,
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        SizeConfig
                                                                            .size10),
                                                                child:
                                                                    CustomText(
                                                                  "Share this post with your followers",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                  color: AppColors
                                                                      .secondaryTextColor,
                                                                  fontSize:
                                                                      SizeConfig
                                                                          .size13,
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
                                                        bottom:
                                                            SizeConfig.size10),
                                                    child: Divider(
                                                      color: AppColors
                                                          .secondaryTextColor,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Get.back();
                                                      Get.to(
                                                          CreateMessagePostScreenRepost(
                                                        isEdit: false,
                                                        post: widget.post,
                                                      ));
                                                    },
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width:
                                                              SizeConfig.size30,
                                                          height:
                                                              SizeConfig.size30,
                                                          child: LocalAssets(
                                                            imagePath:
                                                                AppIconAssets
                                                                    .pencilIcon,
                                                            width: SizeConfig
                                                                .size20,
                                                            height: SizeConfig
                                                                .size20,
                                                            // imgColor: AppColors.secondaryTextColor,
                                                          ),
                                                        ),
                                                        Flexible(
                                                          flex: 2,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        SizeConfig
                                                                            .size10),
                                                                child:
                                                                    CustomText(
                                                                  "Add your things",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      SizeConfig
                                                                          .size16,
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        SizeConfig
                                                                            .size10),
                                                                child:
                                                                    CustomText(
                                                                  "Add a comment ,photo before you share this post",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                  color: AppColors
                                                                      .secondaryTextColor,
                                                                  fontSize:
                                                                      SizeConfig
                                                                          .size13,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          SizeConfig.size20),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: ViewFeedActionWidget(
                                    iconPath: AppIconAssets.repost_new,
                                    data: formatNumberLikePost(
                                        _post.repostCount ?? 0)),
                              ),
                            Padding(
                              padding: EdgeInsets.only(left: SizeConfig.size5),
                              child: InkWell(
                                onTap: () => widget.onShareButtonPressed(),
                                child: LocalAssets(
                                  imagePath: AppIconAssets.share_bold,
                                  imgColor: AppColors.secondaryTextColor,
                                ),
                              ),
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
    );
  }

  openProfileToClickUser() {
    Post? data = widget.post?.children_post;
    String? authorId = data?.user?.id;
    String? userBusinessId = data?.user?.id;
    String? userAccountType = data?.user?.accountType?.toUpperCase();
    logs("userAccountType=== ${userAccountType}");
    logs("userId=== ${userId} authorId  === $authorId");
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
  return Padding(
    padding: EdgeInsets.only(right: SizeConfig.size10),
    child: Row(
      children: [
        LocalAssets(
          imagePath: iconPath,
          width: SizeConfig.size18,
          height: SizeConfig.size18,
        ),
        SizedBox(
          width: SizeConfig.size5,
        ),
        CustomText(
          data,
          color: AppColors.secondaryTextColor,
          fontSize: SizeConfig.size10,
        ),
      ],
    ),
  );
}

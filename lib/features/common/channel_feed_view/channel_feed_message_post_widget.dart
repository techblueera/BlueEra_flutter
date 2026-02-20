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
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_reference_widget.dart';
import 'package:BlueEra/features/common/feed/widget/social_message_post_grid_widget.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_repost_screen.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelFeedMessagePostWidget extends StatefulWidget {
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

  ChannelFeedMessagePostWidget({
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
  State<ChannelFeedMessagePostWidget> createState() =>
      _MessagePostWidgetState();
}

class _MessagePostWidgetState extends State<ChannelFeedMessagePostWidget> {
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
  void didUpdateWidget(covariant ChannelFeedMessagePostWidget oldWidget) {
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
          horizontalPadding: 0,
          bottomPadding: 10,
          childWidget: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_post.media?.isNotEmpty ?? false) ...[
                    if ((_post.media_types?.firstOrNull?.startsWith("video/") ??
                            false) ||
                        isVideoUrl(_post.media?.firstOrNull)) ...[
                      Padding(
                        padding: EdgeInsets.only(left: 0, right: 0, top: 0),
                        child: PostFeedAutoPlayVideoCard(
                          videoItem: videoData!,
                          key: ValueKey(videoData?.videoId ?? 0),
                          globalMuteNotifier: ValueNotifier(false),
                          videoType: VideoType.videoFeed,
                          onTapOption: () {
                            openBlockSelectionDialog(
                                context: context,
                                reportType: 'VIDEO_POST',
                                userId: videoData?.video?.userId ?? '',
                                contentId: videoData?.video?.id ?? '',
                                userBlockVoidCallback: () async {
                                  await Get.find<VideoController>().userBlocked(
                                    videoType: VideoType.videoFeed,
                                    otherUserId: videoData?.video?.userId ?? '',
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
                    if ((_post.media_types?.firstOrNull?.startsWith("image/") ??
                            false) ||
                        isImageUrl(_post.media?.firstOrNull))
                      SocialImageGrid(
                        imageUrls: _post.media ?? [],
                        subTitle: _post.subTitle ?? "",
                        postData: _post,
                      ),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_post.title?.isNotEmpty ?? false) ...[
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
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
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                        Container(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: SizeConfig.size15,
                              right: SizeConfig.size15,
                            ),
                            child: ExpandableText(
                              text: subTitle.trim(),
                              trimLines: 3,
                              expandMode: ExpandMode.dialog,
                              style: TextStyle(
                                  color: AppColors.mainTextColor,
                                  fontFamily: AppConstants.OpenSans,
                                  fontWeight: FontWeight.w400,
                                  fontSize: SizeConfig.size15),
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
                  if (widget.isShowOnlyDetails == false) ...[
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
                                    formatNumberLikePost(_post.likesCount ?? 0),
                                    color: AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.size10,
                                  ),
                                ],
                              ),
                            ) /*ViewFeedActionWidget(
                                iconPath: AppIconAssets.like_new,
                                data: formatNumberLikePost(
                                    _post.likesCount ?? 0))*/
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
                                        borderRadius: BorderRadius.circular(12),
                                        child: ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxWidth: 800),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: SizeConfig.size15),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                    height: SizeConfig.size20),
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
                                                          message: AppStrings
                                                              .repostedSuccessfully);
                                                      Get.find<
                                                              NavigationHelperController>()
                                                          .shouldRefreshBottomBar
                                                          .value = true;
                                                      Get.until((route) =>
                                                          route.settings.name ==
                                                          RouteHelper
                                                              .getBottomNavigationBarScreenRoute());
                                                    } else {
                                                      commonSnackBar(
                                                          message: AppStrings
                                                              .alreadyReposted);
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
                                                          width:
                                                              SizeConfig.size30,
                                                          height:
                                                              SizeConfig.size30,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          SizeConfig
                                                                              .size10),
                                                              child: CustomText(
                                                                AppStrings
                                                                    .Repost,
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
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          SizeConfig
                                                                              .size10),
                                                              child: CustomText(
                                                                AppStrings
                                                                    .sharePostWithFollowers,
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
                                                          width:
                                                              SizeConfig.size20,
                                                          height:
                                                              SizeConfig.size20,
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
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          SizeConfig
                                                                              .size10),
                                                              child: CustomText(
                                                                AppStrings
                                                                    .addYourThings,
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
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          SizeConfig
                                                                              .size10),
                                                              child: CustomText(
                                                                AppStrings
                                                                    .addCommentBeforeShare,
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
                                                    height: SizeConfig.size20),
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
                  ]
                ],
              ),
            ],
          )),
    );
  }
}

ViewFeedActionWidget(
    {required String iconPath, required String data, Color? fontColor}) {
  return Padding(
    padding: EdgeInsets.only(right: SizeConfig.size10),
    child: Row(
      children: [
        LocalAssets(
          imagePath: iconPath,
          width: SizeConfig.size24,
          height: SizeConfig.size24,
          imgColor: fontColor ?? AppColors.secondaryTextColor,
        ),
        SizedBox(
          width: SizeConfig.size5,
        ),
        CustomText(
          data,
          color: fontColor ?? AppColors.secondaryTextColor,
          fontSize: SizeConfig.size12,
        ),
      ],
    ),
  );
}

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_screen.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:BlueEra/features/common/reel/widget/common_video_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:octo_image/octo_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostFeedAutoPlayVideoCard extends StatefulWidget {
  final ShortFeedItem videoItem;
  final ValueNotifier<bool>? globalMuteNotifier;
  final VideoType videoType;
  final VoidCallback onTapOption;

  const PostFeedAutoPlayVideoCard({
    super.key,
    required this.videoItem,
    this.globalMuteNotifier,
    required this.videoType,
    required this.onTapOption,
  });

  @override
  State<PostFeedAutoPlayVideoCard> createState() =>
      _PostFeedAutoPlayVideoCardState();
}

class _PostFeedAutoPlayVideoCardState extends State<PostFeedAutoPlayVideoCard>
    with WidgetsBindingObserver {
  final videoManager = Get.isRegistered<SimplePriorityVideoManager>()
      ? Get.find<SimplePriorityVideoManager>()
      : Get.put(SimplePriorityVideoManager());

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    videoManager.removeVideo(widget.videoItem.videoId ?? '');
    super.dispose();
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    String videoUrl;

    videoUrl = widget.videoItem.video?.videoUrl ?? '';
    videoManager.updateVideoVisibility(
      widget.videoItem.videoId ?? '',
      videoUrl,
      info.visibleFraction,
    );
  }

  /// 🧩 Helper: Cover Image Widget

  @override
  Widget build(BuildContext context) {
    /// 🧩 Helper: Image Builder
    final mainContent = VisibilityDetector(
      key: ValueKey(widget.videoItem.videoId),
      onVisibilityChanged: _handleVisibilityChange,
      child: GetBuilder<SimplePriorityVideoManager>(builder: (videoManager) {
        final isCurrent = videoManager.currentIndex.value ==
            widget.videoItem.videoId.hashCode;
        final controller = videoManager.controller;
        final isScrolling = videoManager.isScrolling.value;

        final bool showVideo = isCurrent &&
            controller != null &&
            controller.value.isInitialized &&
            controller.value.size.width > 0 &&
            controller.value.size.height > 0;

        return LayoutBuilder(builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final videoWidth =
              widget.videoItem.video?.media_width?.toDouble() ?? 0.0;
          final videoHeight =
              widget.videoItem.video?.media_height?.toDouble() ?? 0.0;
          final bool isLandscape = videoWidth > videoHeight;
          final bool isPortrait = videoHeight > videoWidth;
          final aspectRatio = (videoWidth > 0 && videoHeight > 0)
              ? videoWidth / videoHeight
              : 16 / 9;

          double displayWidth = screenWidth;
          double displayHeight;

          if (isLandscape) {
            // landscape: based on ratio, clamped to prevent jumps
            displayHeight = displayWidth / aspectRatio;
            displayHeight = displayHeight.clamp(180.0, 300.0);
          } else if (isPortrait) {
            // portrait: fixed height
            displayHeight = 300;
          } else {
            // square: 1:1
            displayHeight = displayWidth;
          }

          // --- Common Container (same height for thumbnail + video)
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              color: Colors.black,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- 🖼️ Thumbnail always first (acts as background)
                OctoImage(
                  image: NetworkImage(
                    widget.videoItem.video?.coverUrl ?? "",
                  ),
                  fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                ),

                // --- 🎬 Video Player (only visible when ready)
                if (showVideo && controller.value.isInitialized)
                  FittedBox(
                    fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),

                // --- 🔄 Loading overlay (optional)
                if (isScrolling && isCurrent)
                  Container(
                    color: Colors.black38,
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // --- 🔇 Mute Button

                if (isCurrent && controller != null)
                  Positioned(
                    top: SizeConfig.size12,
                    right: SizeConfig.size10,
                    child: GestureDetector(
                      onTap: videoManager.toggleMute,
                      child: Container(
                        padding: EdgeInsets.all(SizeConfig.size6),
                        decoration: BoxDecoration(
                          color: AppColors.blackCC,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: videoManager.isMuted,
                          builder: (_, isMuted, __) => Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            color: AppColors.white,
                            size: SizeConfig.size20,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ⭐ NEW — LinkedIn-style UI
                Obx(() {
                  if (videoManager.showReplayOverlay.value&&(showVideo && controller.value.isInitialized)) {
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Repost button (rounded)
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
                                                            widget.videoItem.videoId ??
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
                                                          route.settings.name ==
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
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          SizeConfig
                                                                              .size10),
                                                              child: CustomText(
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                      color: Colors.white, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.repeat, color: Colors.white),
                                    SizedBox(width: 8),
                                    CustomText(AppStrings.Repost,
                                        color: Colors.white, fontSize: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Watch again
                            GestureDetector(
                              onTap: () {
                                videoManager.playVideo(
                                    widget.videoItem.video?.id ?? "");
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.refresh, color: Colors.white),
                                  SizedBox(width: 8),
                                  CustomText(AppStrings.watchAgain,
                                      color: Colors.white, fontSize: 16),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],
            ),
          );
        });
      }),
    );

    /// 🧩 Helper: Cover Image Widget
    return SizedBox(
      width: Get.width,
      child: CommonVideoCard(
        mainContent: mainContent,
        videoItem: widget.videoItem,
        videoType: widget.videoType,
        onTapOption: widget.onTapOption,
        onTapCard: () async {
          await Get.to(() => VideoFeedScreen(
                videoData: VideoPost(
                  id: '${widget.videoItem.video?.id}',
                  title: '${widget.videoItem.video?.title}',
                  subTitle: '${widget.videoItem.video?.description}',
                  videoUrl: '${widget.videoItem.video?.videoUrl}',
                  thumbnail: '',
                  aspectRatio: '',
                  authorName: '${widget.videoItem.author?.name}',
                  authorUsername: '${widget.videoItem.author?.username}',
                  avatar: '${widget.videoItem.author?.profileImage}',
                  designation: '${widget.videoItem.author?.designation}',
                  business_category: '',
                  account_type: '${widget.videoItem.author?.accountType}',
                  createdAt: widget.videoItem.video?.createdAt ?? "",
                  comments_count: widget.videoItem.commentsCount ?? 0,
                  repost_count: widget.videoItem.repostCount ?? 0,
                  type: widget.videoItem.video?.type ?? "",
                  views_count: widget.videoItem.viewsCount ?? 0,
                  isLiked: widget.videoItem.interactions?.isLiked ?? false,
                  likes_count: widget.videoItem.likesCount ?? 0,
                ),
                // Provide the manager instance so fullscreen can reuse the controller
              ));
        },
        isShowUser: false,
      ),
    );
  }
}

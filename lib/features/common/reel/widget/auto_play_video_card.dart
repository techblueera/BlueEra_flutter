
import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_screen.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:BlueEra/features/common/reel/widget/common_video_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  Widget singleNetworkImage({
    required String urlLink,
    required double media_width,
    required double media_height,
  }) {
    // final double screenWidth = Get.width;
    const double borderRadiusValue = 12.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadiusValue),
      child: CachedNetworkImage(
        imageUrl: urlLink,
        width: media_width,
        height: media_height,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, _, __) => Container(
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }

  /// 🧩 Helper: Cover Image Widget

  @override
  Widget build(BuildContext context) {
    // 👇 only the video section
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
              ],
            ),
          );
        });

      }),
    );

    /// 🧩 Helper: Cover Image Widget
    // return SizedBox();
    return SizedBox(
      width: Get.width,
      child: CommonVideoCard(
        mainContent: mainContent,
        videoItem: widget.videoItem,
        videoType: widget.videoType,
        onTapOption: widget.onTapOption,
        // Changes to onTapCard in PostFeedAutoPlayVideoCard (replace your onTapCard)

        onTapCard: () async {
          // Pause headline playback before pushing fullscreen
          // videoManager.pauseCurrentVideo();

          // Option A (recommended): Reuse shared controller in fullscreen.
          // Pass an identifier and let fullscreen UI use the same manager/controller.
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

/*
class AutoPlayVideoCard extends StatefulWidget {
  final ShortFeedItem videoItem;
  final ValueNotifier<bool>? globalMuteNotifier;
  final VideoType videoType;
  final VoidCallback onTapOption;

  const AutoPlayVideoCard({
    super.key,
    required this.videoItem,
    this.globalMuteNotifier,
    required this.videoType,
    required this.onTapOption,
  });

  @override
  State<AutoPlayVideoCard> createState() => _AutoPlayVideoCardState();
}

class _AutoPlayVideoCardState extends State<AutoPlayVideoCard> {
  final videoManager = Get.isRegistered<SimplePriorityVideoManager>()
      ? Get.find<SimplePriorityVideoManager>()
      : Get.put(SimplePriorityVideoManager());

  @override
  void dispose() {
    // final videoManager = Get.isRegistered<SimplePriorityVideoManager>()
    //     ? Get.find<SimplePriorityVideoManager>()
    //     : Get.put(SimplePriorityVideoManager());
    videoManager.removeVideo(widget.videoItem.videoId ?? '');
    super.dispose();
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    // final videoManager = Get.isRegistered<SimplePriorityVideoManager>()
    //     ? Get.find<SimplePriorityVideoManager>()
    //     : Get.put(SimplePriorityVideoManager());

    String videoUrl;
    // if(Platform.isAndroid){
    //   videoUrl = widget.videoItem.video?.transcodedUrls?.master ??
    //       widget.videoItem.video?.videoUrl ??
    //       '';
    // }else{
    //   videoUrl =
    //       widget.videoItem.video?.videoUrl ??
    //       '';
    // }
    videoUrl = widget.videoItem.video?.videoUrl ?? '';

    videoManager.updateVideoVisibility(
      widget.videoItem.videoId ?? '',
      videoUrl,
      info.visibleFraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final videoManager = Get.put(SimplePriorityVideoManager());

    // 👇 only the video section
    final mainContent = AspectRatio(
      aspectRatio: 16 / 9,
      child: VisibilityDetector(
        key: ValueKey(widget.videoItem.videoId),
        onVisibilityChanged: _handleVisibilityChange,
        child: Obx(() {
          final isCurrent = videoManager.currentIndex.value ==
              widget.videoItem.videoId.hashCode;
          final controller = videoManager.controller;
          final isScrolling = videoManager.isScrolling.value;

          return Stack(
            // fit: StackFit.expand,
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: widget.videoItem.video?.coverUrl != null &&
                          isNetworkImage(widget.videoItem.video?.coverUrl ?? '')
                      ? CachedNetworkImage(
                          imageUrl: widget.videoItem.video?.coverUrl ?? '',
                          width: SizeConfig.screenWidth,
                          height: SizeConfig.size170,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: SizeConfig.screenWidth,
                            height: SizeConfig.size140,
                            // color: Colors.grey[300],
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: SizeConfig.screenWidth,
                            height: SizeConfig.size140,
                            color: Colors.grey[300],
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                            // LocalAssets(imagePath: AppIconAssets.appIcon),
                          ),
                        )
                      : widget.videoItem.video?.coverUrl != null
                          ? Image.file(
                              File(widget.videoItem.video?.coverUrl ?? ''),
                              width: SizeConfig.screenWidth,
                              height: SizeConfig.size170,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: SizeConfig.screenWidth,
                              height: SizeConfig.size140,
                              color: Colors.grey[300],
                              child: LocalAssets(
                                  imagePath: AppIconAssets.place_holder_image,
                                  boxFix: BoxFit.cover),
                            ),
                ),
              ),

              // Video
              if (isCurrent &&
                  controller != null &&
                  controller.value.isInitialized)
                AspectRatio(
                    aspectRatio: 16 / 9, child: VideoPlayer(controller)),

              // Loading overlay
              if (isScrolling && isCurrent)
                Container(
                  color: Colors.black38,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Mute button
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

              // Video meta info (duration, likes)
              Positioned(
                left: SizeConfig.size12,
                right: SizeConfig.size12,
                bottom: SizeConfig.size12,
                child: VideoPostMetaInfo(
                  totalVideoDuration: formatDuration(
                    Duration(seconds: widget.videoItem.video?.duration ?? 0),
                  ),
                  totalLikes:
                      widget.videoItem.video?.stats?.likes.toString() ?? '0',
                  videoType: widget.videoType,
                ),
              ),

              // Change Thumbnail button
              if ((widget.videoItem.channel?.id != null &&
                      widget.videoItem.channel?.id == channelId) ||
                  (widget.videoItem.author?.accountType ==
                          AppConstants.individual &&
                      widget.videoItem.author?.id == userId))
                Positioned(
                  left: SizeConfig.size10,
                  top: SizeConfig.size12,
                  child: InkWell(
                    onTap: () => _pickImageFromGallery(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size6,
                        horizontal: SizeConfig.size8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blackCC,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomText(
                        "Change Thumbnail",
                        color: AppColors.white,
                        fontSize: SizeConfig.small,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );

    return CommonVideoCard(
      mainContent: mainContent,
      videoItem: widget.videoItem,
      videoType: widget.videoType,
      onTapOption: widget.onTapOption,
      onTapCard: () {
        Navigator.pushNamed(
          context,
          RouteHelper.getVideoPlayerScreenRoute(),
          arguments: {
            ApiKeys.videoItem: widget.videoItem,
            ApiKeys.videoType: widget.videoType
          },
        );
      },
      isShowUser: true,
    );
  }

  void _pickImageFromGallery(BuildContext context) async {
    final croppedPath = await SelectProfilePictureDialog.pickFromGallery(
      context,
      cropAspectRatio: const CropAspectRatio(width: 16, height: 9),
    );
    if (croppedPath != null) {
      await Get.find<VideoController>().updateVideoThumbnail(
        videoId: widget.videoItem.video?.id ?? '',
        videoType: widget.videoType,
        thumbnail: croppedPath,
      );
    }
  }
}
*/

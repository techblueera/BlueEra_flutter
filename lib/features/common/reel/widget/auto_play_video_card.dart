import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:BlueEra/features/common/reel/widget/common_video_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/video_post_meta_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/api/apiService/api_keys.dart';

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
  @override
  void dispose() {
    final videoManager = Get.find<SimplePriorityVideoManager>();
    videoManager.removeVideo(widget.videoItem.videoId ?? '');
    super.dispose();
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    final videoManager = Get.isRegistered<SimplePriorityVideoManager>()
        ? Get.find<SimplePriorityVideoManager>()
        : Get.put(SimplePriorityVideoManager());

    String videoUrl;
    if(Platform.isAndroid){
      videoUrl = widget.videoItem.video?.transcodedUrls?.master ??
          widget.videoItem.video?.videoUrl ??
          '';
    }else{
      videoUrl =
          widget.videoItem.video?.videoUrl ??
          '';
    }


    videoManager.updateVideoVisibility(
      widget.videoItem.videoId ?? '',
      videoUrl,
      info.visibleFraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoManager = Get.put(SimplePriorityVideoManager());

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
            fit: StackFit.expand,
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
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: SizeConfig.screenWidth,
                            height: SizeConfig.size140,
                            color: Colors.grey[300],
                            child:
                                LocalAssets(imagePath: AppIconAssets.appIcon),
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
                                  imagePath: AppIconAssets.blue_era_app_logo),
                            ),
                ),
              ),
              // Video
              if (isCurrent &&
                  controller != null &&
                  controller.value.isInitialized)
                VideoPlayer(controller),

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

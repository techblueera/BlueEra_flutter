import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoPostMetaInfo extends StatelessWidget {
  final String totalLikes;
  final String totalVideoDuration;
  final VideoType videoType;

  const VideoPostMetaInfo(
      {super.key, required this.totalLikes, required this.totalVideoDuration, required this.videoType});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            // _onLikeDislikePressed();
          },
          child: Container(
            height: SizeConfig.size30,
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size6, horizontal: SizeConfig.size8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.blackCC,
                borderRadius: BorderRadius.circular(8.0)),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size2),
                  child: LocalAssets(imagePath: AppIconAssets.unlikeIcon),
                ),
                CustomText(
                  "$totalLikes",
                  color: AppColors.white,
                  fontSize: SizeConfig.extraSmall,
                ),
              ],
            ),
          ),
        ),
        Container(
          height: SizeConfig.size30,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size6, horizontal: SizeConfig.size8),
          decoration: BoxDecoration(
              color: AppColors.blackCC,
              borderRadius: BorderRadius.circular(8.0)),
          child: CustomText(
            "$totalVideoDuration",
            color: AppColors.white,
            fontSize: SizeConfig.extraSmall,
          ),
        )
      ],
    );
  }

  Future<void> _onLikeDislikePressed() async {
    final videoController = Get.find<VideoController>();
    final videoId = videoController.videoFeedItem?.video?.id ?? '0';

    // Update UI immediately
    if (videoController.isLiked.isTrue) {
      // Unlike action
      videoController.videoFeedItem?.interactions?.isLiked = false;
      videoController.videoFeedItem?.video?.stats?.likes =
          (  videoController.videoFeedItem?.video?.stats?.likes ?? 1) - 1;

      // Call debounced unlike API
      Get.find<VideoController>().videoUnLike(videoId: videoId);
    } else {
      // Like action
      videoController.videoFeedItem?.interactions?.isLiked = true;
      videoController.videoFeedItem?.video?.stats?.likes =
          (  videoController.videoFeedItem?.video?.stats?.likes ?? 0) + 1;

      // Call debounced like API
      Get.find<VideoController>().videoLike(videoId: videoId);
    }

    // Sync controller state and propagate to lists
    final isLiked = videoController.videoFeedItem?.interactions?.isLiked?? false;
    final likes =  videoController.videoFeedItem?.video?.stats?.likes ?? 0;
    videoController.isLiked.value = isLiked;
    videoController.likes.value = likes;
    Get.find<VideoController>().updateVideoLikeCount(
      videoType:videoType,
      videoId: videoController.videoFeedItem?.video?.id ?? '0',
      isLiked: isLiked,
      newLikeCount: likes,
    );
  }
}

import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/widget/common_video_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/video_post_meta_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoCard extends StatelessWidget {
  final ShortFeedItem videoItem;
  final VoidCallback onTapOption;
  final VideoType videoType;
  final VoidCallback? voidCallback;
  final List<BoxShadow>? boxShadow;

  const VideoCard({
    super.key,
    required this.videoItem,
    required this.onTapOption,
    required this.videoType,
    this.voidCallback,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    // Thumbnail + overlays = mainContent
    final mainContent = GestureDetector(
      onTap: voidCallback ??
              () {
            if (videoType == VideoType.underProgress) return;

            Navigator.pushNamed(
              context,
              RouteHelper.getVideoPlayerScreenRoute(),
              arguments: {
                ApiKeys.videoItem: videoItem,
                ApiKeys.videoType: videoType
              },
            );
          },
      child: Stack(
        children: [
          // Thumbnail (network/file)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: isNetworkImage(videoItem.video?.coverUrl ?? '')
                  ? CachedNetworkImage(
                imageUrl: videoItem.video?.coverUrl ?? '',
                width: SizeConfig.screenWidth,
                height: SizeConfig.size170,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size140,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size140,
                  color: Colors.grey[300],
                  child: LocalAssets(imagePath: AppIconAssets.appIcon),
                ),
              )
                  : Image.file(
                File(videoItem.video?.coverUrl ?? ''),
                width: SizeConfig.screenWidth,
                height: SizeConfig.size170,
                fit: BoxFit.cover,
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
                Duration(seconds: videoItem.video?.duration ?? 0),
              ),
              totalLikes: videoItem.video?.stats?.likes.toString() ?? '0',
            ),
          ),

          // Change Thumbnail button
          if ((videoItem.channel?.id != null && videoItem.channel?.id == channelId) ||
              videoItem.author?.id == userId)
          Positioned(
            right: SizeConfig.size10,
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
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Stack(
        children: [
          CommonVideoCard(
            mainContent: mainContent,
            videoItem: videoItem,
            videoType: videoType,
            onTapOption: onTapOption,
            onTapCard: voidCallback,
            boxShadow: boxShadow,
          ),

          // Overlay if video is under progress
          if (videoType == VideoType.underProgress)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.black65,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: LocalAssets(imagePath: AppIconAssets.progressIndicator),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _pickImageFromGallery(BuildContext context) async {
    final croppedPath = await SelectProfilePictureDialog.pickFromGallery(
      context,
      cropAspectRatio: const CropAspectRatio(width: 16, height: 9),
    );
    if (croppedPath != null) {
      await Get.find<VideoController>().updateVideoThumbnail(
        videoId: videoItem.video?.id ?? '',
        videoType: videoType,
        thumbnail: croppedPath,
      );
    }
  }
}


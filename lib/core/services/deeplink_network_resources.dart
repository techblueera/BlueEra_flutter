import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/reel/view/shorts/share_short_player_item.dart';
import 'package:get/get.dart';

final deepLinkNetworkResources = DeepLinkNetworkResources();

class DeepLinkNetworkResources {
  /// Get Video By ID for deep link handling
  Future<ShortFeedItem?> getVideoById(String videoId) async {
    try {
      final response = await FeedRepo().getVideoById(videoId: videoId);
      if (response.isSuccess) {
        final responseData = response.response?.data;
        if (responseData != null) {
          // The API returns: { data: { videos: [VideoFeedItem] } }
          // We need to extract the first video from the videos array
          final videosData = responseData['data'];
          if (videosData != null &&
              videosData['videos'] != null &&
              videosData['videos'].isNotEmpty) {
            final videoData = videosData['videos'][0];
            final videoFeedItem = ShortFeedItem.fromJson(videoData);
            return videoFeedItem;
          }
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs('DEEPLINK_DEBUG: Error fetching video by ID: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }

    return null;
  }

  Future<void> navigateToVideoDetail(String videoId) async {
    try {
      final videoFeedItem = await getVideoById(videoId);

      if (videoFeedItem == null) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      final videoType = videoFeedItem.video?.type;
      switch (videoType) {
        case 'long':
          Get.toNamed(
            RouteHelper.getVideoPlayerScreenRoute(),
            arguments: {
              ApiKeys.videoItem: videoFeedItem,
              ApiKeys.videoType: VideoType.videoFeed,
            },
          );

          // Get.toNamed(() => DeeplinkVideoScreen(videoItem: videoFeedItem));
          break;
        case 'short':
          Get.to(() => ShareShortPlayerItem(
                videoItem: videoFeedItem,
                autoPlay: true,
                onTapOption: () {},
              ));
          break;
        default:
          logs('DEEPLINK_DEBUG: Unknown video type: $videoType');
          commonSnackBar(message: 'Unsupported video type');
      }
    } catch (e) {
      logs('DEEPLINK_DEBUG: Error navigating to video detail: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}

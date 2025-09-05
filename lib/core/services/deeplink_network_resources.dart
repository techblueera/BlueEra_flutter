import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/reel/view/shorts/share_short_player_item.dart';
import 'package:BlueEra/features/common/reel/view/video/deeplink_video_screen.dart';
import 'package:get/get.dart';

final deepLinkNetworkResources = DeepLinkNetworkResources();

class DeepLinkNetworkResources {
  /// Get Video By ID for deep link handling
  Future<ShortFeedItem?> getVideoById(String videoId) async {
    try {
      logs('DEEPLINK_DEBUG: Fetching video with ID: $videoId');
      final response = await FeedRepo().getVideoById(videoId: videoId);

      logs('DEEPLINK_DEBUG: API Response - Success: ${response.isSuccess}');
      logs('DEEPLINK_DEBUG: API Response - Message: ${response.message}');
      logs('DEEPLINK_DEBUG: API Response - Data: ${response.response?.data}');

      if (response.isSuccess) {
        final responseData = response.response?.data;
        if (responseData != null) {
          logs('DEEPLINK_DEBUG: Response data found, extracting video from nested structure');

          // The API returns: { data: { videos: [VideoFeedItem] } }
          // We need to extract the first video from the videos array
          final videosData = responseData['data'];
          if (videosData != null && videosData['videos'] != null && videosData['videos'].isNotEmpty) {
            final videoData = videosData['videos'][0];
            logs('DEEPLINK_DEBUG: Extracted video data from nested structure');

            final videoFeedItem = ShortFeedItem.fromJson(videoData);

            // Log the parsed video details
            logs('DEEPLINK_DEBUG: Parsed VideoFeedItem - Video URL: ${videoFeedItem.video?.videoUrl}');
            logs('DEEPLINK_DEBUG: Parsed VideoFeedItem - Video ID: ${videoFeedItem.video?.id}');
            logs('DEEPLINK_DEBUG: Parsed VideoFeedItem - Video Title: ${videoFeedItem.video?.title}');

            return videoFeedItem;
          } else {
            logs('DEEPLINK_DEBUG: No videos found in nested data structure');
          }
        } else {
          logs('DEEPLINK_DEBUG: Video data is null in successful response');
        }
      } else {
        logs('DEEPLINK_DEBUG: API call failed with message: ${response.message}');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
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
          Get.to(() => DeeplinkVideoScreen(videoItem: videoFeedItem));
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

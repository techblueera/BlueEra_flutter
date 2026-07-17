import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/view/hotel_discover_home_screen.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/reel/view/shorts/share_short_player_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final deepLinkNetworkResources = DeepLinkNetworkResources();

class DeepLinkNetworkResources {
  /// Get Video By ID for deep link handling.
  ///
  /// Owns the user-facing message for every failure path, so callers can treat
  /// a null return as "already explained" and stay silent.
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
        // Request succeeded but the video is gone — deleted, private, or a
        // stale share link. Say so instead of failing silently.
        logs('DEEPLINK_DEBUG: No video found for id: $videoId');
        commonSnackBar(message: AppStrings.somethingWentWrong);
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

  /// Opens the fullscreen player for a video reached via the
  /// `https://beapp.in/app/video/<videoId>` deep link.
  ///
  /// Both `videoDeepLink` and `shortDeepLink` emit that same path, so the URL
  /// alone doesn't say which kind of video it is — the type only arrives with
  /// the fetch. Longs open the watch page; shorts open the fullscreen reels
  /// player. The fetch sits behind a loader because this runs straight off a
  /// link tap, where the app would otherwise look frozen.
  Future<void> navigateToVideoDetail(String videoId) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    ShortFeedItem? videoFeedItem;
    try {
      videoFeedItem = await getVideoById(videoId);
    } catch (e) {
      logs('DEEPLINK_DEBUG: Error navigating to video detail: $e');
    } finally {
      if (Get.isDialogOpen ?? false) Get.back();
    }

    final item = videoFeedItem;
    // [getVideoById] already told the user why it failed — a second snackbar
    // here would just stack on top of that one.
    if (item == null) return;

    final videoType = item.video?.type;
    switch (videoType) {
      case 'long':
        Get.toNamed(
          RouteHelper.getVideoPlayerScreenRoute(),
          arguments: {
            ApiKeys.videoItem: item,
            ApiKeys.videoType: VideoType.videoFeed,
          },
        );
        break;
      case 'short':
        Get.to(() => ShareShortPlayerItem(
              videoItem: item,
              autoPlay: true,
              onTapOption: () {},
            ));
        break;
      default:
        logs('DEEPLINK_DEBUG: Unknown video type: $videoType');
        commonSnackBar(message: 'Unsupported video type');
    }
  }

  /// Opens [HotelDiscoverHomeScreen] for a hotel reached via the
  /// `https://beapp.in/app/hotel/<businessId>` deep link. The screen needs a
  /// fully-hydrated [HotelServiceData], so we fetch it by businessId first
  /// (behind a brief loader), ensure the business controller the screen reads
  /// is registered, then navigate.
  Future<void> navigateToHotelDetail(String businessId) async {
    // HotelDiscoverHomeScreen does `Get.find<ViewBusinessDetailsController>()`
    // in initState — make sure it exists on a cold-start deep link.
    getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    final discover = getOrPut(() => DiscoverController());

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    HotelServiceData? hotel;
    try {
      hotel = await discover.fetchHotelByBusinessId(businessId);
    } catch (e) {
      logs('DEEPLINK_DEBUG: Error fetching hotel by businessId: $e');
    } finally {
      if (Get.isDialogOpen ?? false) Get.back();
    }

    final data = hotel;
    if (data == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    Get.to(() => HotelDiscoverHomeScreen(data: data));
  }
}

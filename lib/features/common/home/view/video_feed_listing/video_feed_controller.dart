import 'dart:convert';

import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/features/common/home/repo/home_feed_repo.dart';
import 'package:get/get.dart';

// controllers/video_feed_controller.dart
import 'package:BlueEra/core/api/model/video_post_model.dart' show VideoPost;
import 'video_cache_manager.dart';

class VideoFeedController extends GetxController {
  var videos = <VideoPost>[].obs;
  var isLoading = false.obs;
  var hasMore = true.obs;
  int _page = 1;

  Future<void> fetchVideos({bool loadMore = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    if (!loadMore) _page = 1;
    final fetchedData = await HomeFeedRepo().userFeedServiceVideoRepo(pageNo:_page); // implement your API fetch
    final data = fetchedData.response?.data;

    late final Map<String, dynamic> json;

    if (data is String) {
      json = jsonDecode(data);
    } else if (data is Map<String, dynamic>) {
      json = data;
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }

    final fetched = (json['data'] as List)
        .map((item) => VideoPost.fromJson(item))
        .toList();
    if (fetched.isEmpty) {
      hasMore.value = false;
    } else {
      if (loadMore) {
        videos.addAll(fetched);
      } else {
        videos.assignAll(fetched);
      }
      _page++;
    }

    // ✅ Preload next 2 videos silently
    _precacheNextVideos();
    isLoading.value = false;
  }

  void _precacheNextVideos() {
    for (int i = 0; i < videos.length; i++) {
      final url = videos[i].videoUrl;
      if (url.isNotEmpty && i < videos.length - 2) {
        VideoCacheManager().getController(url); // pre-initialize next 2 videos
      }
    }
  }

  @override
  void onClose() {
    // VideoCacheManager().disposeAll();
    super.onClose();
  }
}

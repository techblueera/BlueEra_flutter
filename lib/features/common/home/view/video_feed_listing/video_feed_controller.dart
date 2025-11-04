import 'dart:convert';

import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/features/common/home/repo/home_feed_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// controllers/video_feed_controller.dart
import 'package:BlueEra/core/api/model/video_post_model.dart' show VideoPost;
import 'video_cache_manager.dart';

// class VideoFeedController extends GetxController {
//   var videos = <VideoPost>[].obs;
//   var isLoading = false.obs;
//   var hasMore = true.obs;
//   int _page = 1;
//
//   Future<void> fetchVideos({bool loadMore = false}) async {
//     if (isLoading.value) return;
//     isLoading.value = true;
//
//     if (!loadMore) _page = 1;
//     final fetchedData = await HomeFeedRepo().userFeedServiceVideoRepo(pageNo:_page); // implement your API fetch
//     final data = fetchedData.response?.data;
//
//     late final Map<String, dynamic> json;
//
//     if (data is String) {
//       json = jsonDecode(data);
//     } else if (data is Map<String, dynamic>) {
//       json = data;
//     } else {
//       throw Exception('Unexpected response type: ${data.runtimeType}');
//     }
//
//     final fetched = (json['data'] as List)
//         .map((item) => VideoPost.fromJson(item))
//         .toList();
//     if (fetched.isEmpty) {
//       hasMore.value = false;
//     } else {
//       if (loadMore) {
//         videos.addAll(fetched);
//       } else {
//         videos.assignAll(fetched);
//       }
//       _page++;
//     }
//
//     // ✅ Preload next 2 videos silently
//     _precacheNextVideos();
//     isLoading.value = false;
//   }
//
//   void _precacheNextVideos() {
//     for (int i = 0; i < videos.length; i++) {
//       final url = videos[i].videoUrl;
//       if (url.isNotEmpty && i < videos.length - 2) {
//         VideoCacheManager().getController(url); // pre-initialize next 2 videos
//       }
//     }
//   }
//
//   @override
//   void onClose() {
//     // VideoCacheManager().disposeAll();
//     super.onClose();
//   }
// }

class VideoFeedController extends GetxController {
  var videos = <VideoPost>[].obs;
  var isLoading = false.obs;
  var hasMore = true.obs;
  int _page = 1;
  int _currentIndex = 0; // Track current video index

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  Future<void> fetchVideos({bool loadMore = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      if (!loadMore) _page = 1;

      final fetchedData = await HomeFeedRepo().userFeedServiceVideoRepo(pageNo: _page);
      final data = fetchedData.response?.data;

      late final Map<String, dynamic> json;

      if (data is String) {
        json = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        json = data;
      } else {
        throw Exception('Unexpected response type: ${data.runtimeType}');
      }

      // final fetched = (json['data'] as List)
      //     .map((item) => VideoPost.fromJson(item))
      //     .toList();

      final fetched = (json['data'] as List)
          .map((item) => VideoPost.fromJson(item))
          .where((post) => !videos.any((existing) => existing.id == post.id)) // ✅ skip duplicates
          .toList();

      if (fetched.isEmpty) {
        hasMore.value = false;
      } else {
        if (loadMore) {
          videos.addAll(fetched);
        } else {
          final firstVideo = videos.first;
          videos.assignAll([firstVideo, ...fetched]);
        }
        _page++;
      }

      // ✅ Preload videos around current index
      _precacheVideosAroundIndex(_currentIndex);

    } catch (e) {
      debugPrint("Error fetching videos: $e");
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Update current index for better precaching
  void updateCurrentIndex(int index) {
    _currentIndex = index;
    _precacheVideosAroundIndex(index);
  }

  // ✅ Improved precaching - only cache videos around current position
  void _precacheVideosAroundIndex(int currentIndex) {
    // Precache: current, next 2, and previous 1 video
    final indicesToCache = [
      currentIndex - 1, // Previous
      currentIndex,     // Current
      currentIndex + 1, // Next
      currentIndex + 2, // Next + 1
    ];

    for (int i in indicesToCache) {
      if (i >= 0 && i < videos.length) {
        final url = videos[i].videoUrl;
        if (url.isNotEmpty) {
          VideoCacheManager().getController(url).catchError((e) {
            debugPrint("Error precaching video at index $i: $e");
          });
        }
      }
    }
  }

  // ✅ Clean up videos that are far from current index
  void disposeDistantVideos(int currentIndex) {
    for (int i = 0; i < videos.length; i++) {
      // Dispose videos that are more than 3 positions away
      if ((i < currentIndex - 3 || i > currentIndex + 3)) {
        final url = videos[i].videoUrl;
        if (url.isNotEmpty) {
          VideoCacheManager().releaseController(url);
        }
      }
    }
  }

  @override
  void onClose() {
    VideoCacheManager().disposeAll();
    super.onClose();
  }
}

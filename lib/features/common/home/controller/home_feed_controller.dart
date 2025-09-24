import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/home/model/home_feed_model.dart';
import 'package:BlueEra/features/common/home/repo/home_feed_repo.dart';
import 'package:get/get.dart';

class HomeFeedController extends GetxController {
  Rx<ApiResponse> feedResponse = ApiResponse.initial('Initial').obs;

  RxList<PaginationBatch> paginationBatches = <PaginationBatch>[].obs;

  // Pagination variables
  RxString cursor = "".obs;
  RxBool isLoading = false.obs;
  RxBool hasMoreData = true.obs;
  final int limit = 20;

  @override
  void onInit() {
    super.onInit();
    getFeed(refresh: true);
  }

  Future<void> getFeed({bool refresh = false}) async {
    if (isLoading.value) return;

    if (refresh) {
      cursor.value = "";
      paginationBatches.clear();
      hasMoreData.value = true;
    }

    if (!hasMoreData.value) return;

    isLoading.value = true;

    try {
      final timestamp = cursor.value;

      ResponseModel responseModel =
          await HomeFeedRepo().homeFeedRepo(queryParam: {
        ApiKeys.limit: "20",
        ApiKeys.refresh: refresh,
        if (cursor.value.isNotEmpty) ApiKeys.cursor: timestamp,
      });

      if (responseModel.isSuccess) {
        final homeFeedResponse =
            HomeFeedResponse.fromJson(responseModel.response?.data);

        if (homeFeedResponse.feed.isNotEmpty) {
          // Categorize items by type
          List<Post> posts = [];
          List<Post> videos = [];
          List<Post> shorts = [];

          for (var item in homeFeedResponse.feed) {
            Post postData = Post(
              id: item.id,
              type: item.type,
              authorId: item.author.id,
              title: item.title,
              subTitle: item.subTitle,
              media: item.content?.images ?? [],
              message: item.description,
              videoUrl: item.videoUrl,
              thumbnail: item.thumbnail,
              duration: item.duration,
              channel: item.channel,
              isLiked: item.is_post_liked,
              likesCount: int.parse(item.stats?.likes.toString() ?? "0"),
              commentsCount: int.parse(item.stats?.comments.toString() ?? "0"),
              repostCount: int.parse(item.stats?.shares.toString() ?? "0"),
              viewsCount: int.parse(item.stats?.views.toString() ?? "0"),
              createdAt: item.createdAt,
              taggedUsers: item.taggedUsers,
              user: User(
                  id: item.author.id,
                  name: item.author.name,
                  accountType: item.author.accountType,
                  profileImage: item.author.avatar,
                  business_id: item.author.id,
                  businessName: item.author.businessName,
                  designation: item.author.designation,
                  username: item.author.username,
                  categoryOfBusiness: item.author.businessCategory),
            );
            if (item.type == 'message_post') {
              posts.add(postData);
            } else if (item.type == 'long_video') {
              videos.add(postData);
            } else if (item.type == 'short_video') {
              shorts.add(postData);
            }
          }

          // Add videos to the main feed list
          // videoItems.addAll(videos);

          // Create a new pagination batch with posts and shorts
          if (posts.isNotEmpty || shorts.isNotEmpty || videos.isNotEmpty) {
            PaginationBatch newBatch = PaginationBatch(
                posts: posts,
                shorts: shorts,
                timestamp: DateTime.now(),
                videos: videos);

            // Add the new batch to our list
            paginationBatches.add(newBatch);
          }

          // Update cursor for next pagination
          if (homeFeedResponse.feed.isNotEmpty) {
            final lastItem = homeFeedResponse.feed.last;
            if (lastItem.createdAt != null) {
              cursor.value = homeFeedResponse.metaData?.next_cursor ?? "";
            }
          }

          // Check if there's more data to load
          if (homeFeedResponse.feed.length < limit) {
            hasMoreData.value = false;
          }

          feedResponse.value = ApiResponse.complete(homeFeedResponse);
        } else {
          hasMoreData.value = false;
          feedResponse.value = ApiResponse.complete(homeFeedResponse);
        }
      } else {
        feedResponse.value = ApiResponse.error('Failed to load feed');
      }
    } catch (e) {
      feedResponse.value = ApiResponse.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void handleScrollToBottom() {
    if (!isLoading.value && hasMoreData.value) {
      getFeed();
    }
  }
}

// Class to hold items from a single pagination response
class PaginationBatch {
  final List<Post> posts;
  final List<Post> shorts;
  final List<Post> videos;
  final DateTime timestamp;

  PaginationBatch({
    required this.posts,
    required this.shorts,
    required this.videos,
    required this.timestamp,
  });
}

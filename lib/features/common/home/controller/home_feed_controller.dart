import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/home/model/home_feed_model.dart';
import 'package:BlueEra/features/common/home/repo/home_feed_repo.dart';
import 'package:get/get.dart';

class HomeFeedController extends GetxController {
  Rx<ApiResponse> feedResponse = ApiResponse.initial('Initial').obs;

  RxList<Post> mixedFeed = <Post>[].obs;
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
      mixedFeed.clear();
      hasMoreData.value = true;
    }
    if (!hasMoreData.value) return;
    isLoading.value = true;
    try {
      final timestamp = cursor.value;
      ResponseModel responseModel =
          await HomeFeedRepo().homeFeedRepo(queryParam: {
        ApiKeys.limit: "20",
        ApiKeys.refresh: refresh.toString(),
        if (cursor.value.isNotEmpty) ApiKeys.cursor: timestamp,
      });
      if (responseModel.isSuccess) {
        final homeFeedResponse =
            HomeFeedResponse.fromJson(responseModel.response?.data);

        if (homeFeedResponse.feed.isNotEmpty) {
          for (var item in homeFeedResponse.feed) {

            // Add to mixed feed for YouTube-style repeating pattern
            mixedFeed.add(item);
          }

          // Update cursor for next pagination
          if (homeFeedResponse.feed.isNotEmpty) {
            cursor.value = homeFeedResponse.metaData?.next_cursor ?? "";
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

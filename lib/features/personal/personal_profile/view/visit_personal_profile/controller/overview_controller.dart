import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/response/get_ratting_summary_response_modal.dart';
import 'package:BlueEra/core/api/model/user_testimonial_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class OverviewController extends GetxController {
  final testimonialsList = <Testimonials>[].obs;
  final postsList = <Post>[].obs;
  final shortsList = <ShortFeedItem>[].obs;
  final videosList = <ShortFeedItem>[].obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Centralized API call
  Future<void> loadOverviewData(
      String userId, String channelId, String videoType) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Run APIs in parallel
      await Future.wait([
        _getTestimonials(userId),
        getRatingSummary(userId:userId),
        _getPosts(userId),
        _getShorts(channelId, userId),
        _getVideos(videoType, userId),
      ]);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _getTestimonials(String userId) async {
    ResponseModel responseModel =
        await UserRepo().getTestimonialRepo(userId: userId);
    if (responseModel.isSuccess) {
      UserTestimonialModel data =
          UserTestimonialModel.fromJson(responseModel.response?.data);
      testimonialsList.assignAll(data.testimonials ?? []);
    }
  }

  Future<void> _getPosts(String userId) async {
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: 1,
      ApiKeys.limit: 10,
      ApiKeys.filter: "latest",
      ApiKeys.authorId: userId,

    };
    // authorId=689df0cb7e62ed576245195f
    ResponseModel responseModel =
        await FeedRepo().getAllOtherPosts(queryParams: queryParams);
    if (responseModel.isSuccess) {
      PostResponse data = PostResponse.fromJson(responseModel.response?.data);
      postsList.assignAll(data.data);
    }
  }

  Future<void> _getShorts(String channelId, String userId) async {
    final params = {
      ApiKeys.limit: 5,
      ApiKeys.page: 1,
      ApiKeys.typeFilter: 'short',
      ApiKeys.sortBy: Shorts.latest.queryValue,
      ApiKeys.status: VideoStatus.published.queryValue,
      ApiKeys.postVia: "user",
    };
    ResponseModel responseModel = await ChannelRepo().getVisitingChannelVideos(channelId: userId, queryParams: params);

    // ResponseModel responseModel = await ShortsRepo().getShortsByType("latest", channelId, userId);
    if (responseModel.isSuccess) {
      final videoResponse = VideoResponse.fromJson(responseModel.response?.data);
      final List<ShortFeedItem> newShorts = videoResponse.data?.videos ?? [];

      shortsList.addAll(newShorts);
    }
  }

  Future<void> _getVideos(String videoType, String channelId) async {
    final params = {
      ApiKeys.limit: 1,
      ApiKeys.page: 1,
      ApiKeys.typeFilter: 'long',
      ApiKeys.sortBy: Shorts.latest.queryValue,
      ApiKeys.status: VideoStatus.published.queryValue,
      ApiKeys.postVia: "user",
    };

    ResponseModel responseModel = await ChannelRepo()
        .getVisitingChannelVideos(queryParams: params,  channelId:channelId);
    if (responseModel.isSuccess) {
      final videoResponse =
          VideoResponse.fromJson(responseModel.response?.data);

      videosList.assignAll(videoResponse.data?.videos ?? []);
    }
  }

  //  ratting Summary Api
  Rx<GetRattingSummaryResponse?> getRattingSummaryResponse =
  Rxn<GetRattingSummaryResponse>();
  Future<void> getRatingSummary({required String userId}) async {
    try {
      ResponseModel response =
      await UserRepo().getRattingSummaryById(userId: userId);
      if (response.isSuccess) {
        getRattingSummaryResponse.value =
            GetRattingSummaryResponse.fromJson(response.data);
        update();
      }
    } catch (e) {}
  }

}

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HomeFeedRepo extends BaseService {
  Future<ResponseModel> homeFeedRepo({Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      homeFeed,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Merged home feed — posts + reels + follow-suggestion blocks in a single
  /// ordered, cursor-paged list (docs/HOME_FEED_INTEGRATION_GUIDE.md §1).
  ///
  /// Same envelope as [homeFeedRepo], so the caller parses it with the very
  /// same [HomeFeedResponse]. Do NOT send `lat`/`long` here — this endpoint
  /// returns no `business`/`product` items, so geolocation is meaningless.
  Future<ResponseModel> mergedHomeFeedRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      homeFeedMerged,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///REPOST MESSAGE/POLL POST.....
  Future<ResponseModel> postRepostRepo({required String postID}) async {
    final response = await ApiBaseHelper().postHTTP(
      postRepost,
      params: {ApiKeys.originalPostId: postID},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> userFeedServiceVideoRepo(
      {required int pageNo, required String feedID}) async {
    final response = await ApiBaseHelper().getHTTP(
      feedID.isNotEmpty
          ? "${userFeedServiceVideo}page=$pageNo&limit=20&id=$feedID"
          : "${userFeedServiceVideo}page=$pageNo&limit=20",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

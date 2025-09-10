import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FeedRepo extends BaseService{

  ///View Channel details...
  Future<ResponseModel> fetchAllPosts({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getAllPosts,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL Feed Videos...
  Future<ResponseModel> getAllFeedVideos({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      feedHome,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL Feed Personalized(In Shorts)...
  Future<ResponseModel> getAllFeedPersonalized({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      feedPersonalized,
      params: queryParams,
      showProgress:  false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL Feed Trending(In Shorts)...
  Future<ResponseModel> getAllFeedTrending({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      feedTrending,
      params: queryParams,
      showProgress:  false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL Feed NearBy(In Shorts)...
  Future<ResponseModel> getAllFeedNearby({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      feedNearBy,
      params: queryParams,
      showProgress:  false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Like POST...
  Future<ResponseModel> likePost({required String postId}) async {
    final response = await ApiBaseHelper().postHTTP(
      postLike,
      showProgress: false,
      params: {ApiKeys.post_id: postId},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Delete POST...
  Future<ResponseModel> deletePost({required String postId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      '$post/$postId',
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SHARE POST...
  Future<ResponseModel> postShare({required String postId}) async {
    final response = await ApiBaseHelper().postHTTP(
      sharePost,
      params: {ApiKeys.postId: postId},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///HIDE POST...
  Future<ResponseModel> postHide({required String postId}) async {
    final response = await ApiBaseHelper().postHTTP(
      hidePost,
      params: {ApiKeys.postId: postId},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///BLOCK USER...
  Future<ResponseModel> blockUser({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      blocked,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///POLL ANSWER...
  Future<ResponseModel> answerPoll({required Map<String, dynamic> params, required String postId}) async {
    final response = await ApiBaseHelper().postHTTP(
      '$post/$postId/$pollAnswer',
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Like Video ...
  Future<ResponseModel> likeVideo({required String videoId}) async {
    String videoLike = postLikeUnlike(videoId);
    final response = await ApiBaseHelper().postHTTP(
      videoLike,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UnLike Video ...
  Future<ResponseModel> unlikeVideo({required String videoId}) async {
    String videoLike = postLikeUnlike(videoId);
    final response = await ApiBaseHelper().deleteHTTP(
      videoLike,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> viewVideo({required String videoId}) async {

    String videoViews = videoView(videoId);
    final response = await ApiBaseHelper().getHTTP(
      videoViews,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL MY POSTS...
  Future<ResponseModel> getAllMyPosts({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      myPost,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL OTHER POSTS...
  Future<ResponseModel> getAllOtherPosts({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      otherPost,
      showProgress:  false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL OTHER POSTS...
  Future<ResponseModel> postsFeedSearch({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      postSearch,
      showProgress:  false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL OTHER POSTS...
  Future<ResponseModel> videosFeedSearch({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      videosSearch,
      showProgress:  false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  ///GET VIDEO BY ID...
  Future<ResponseModel> getVideoById({required String videoId}) async {
    final response = await ApiBaseHelper().getHTTP(
      videosShare(videoId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> allLikesOfPost({required String postId}) async {
    String allLikesOfPost = postAllLikes(postId);
    final response = await ApiBaseHelper().getHTTP(
      allLikesOfPost,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
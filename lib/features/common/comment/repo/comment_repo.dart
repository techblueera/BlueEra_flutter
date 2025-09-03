import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class CommentRepo extends BaseService {
  ///Get All Comments...
  Future<ResponseModel> getAllComments({required String postId}) async {
    String comments = postComments(postId);
    final response = await ApiBaseHelper().getHTTP(
      comments,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add Comment...
  Future<ResponseModel> addComment(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      postComment,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Comment Like/Dislike...
  Future<ResponseModel> addRemoveLike(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      postCommentLike,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get All Videos Comments...
  Future<ResponseModel> getAllVideoComments({required String videoId}) async {
    String comments = videoComments(videoId);
    final response = await ApiBaseHelper().getHTTP(
      comments,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add Videos Comment...
  Future<ResponseModel> addVideoComment(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      videoAddComment,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Video Comment Like/Dislike...
  Future<ResponseModel> addRemoveLikeFromVideo(
      {required Map<String, dynamic> params, required String commentId}) async {
    String videoCommentLikeUnlike = videoCommentLike(commentId);
    final response = await ApiBaseHelper().postHTTP(
      videoCommentLikeUnlike,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FEED DELETE COMMENT...

  Future<ResponseModel> deletePostComment(
      {required String commentID,}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${deletePostCommentById}$commentID",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///VIDEO DELETE COMMENT...

  Future<ResponseModel> deleteVideoPostComment(
      {required String commentID,}) async {
    final response = await ApiBaseHelper().deleteHTTP(
    "${deleteVideoServiceCommentById}$commentID"
        ,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

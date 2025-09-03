import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/comment/model/comment_model_response.dart';
import 'package:BlueEra/features/common/comment/repo/comment_repo.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentController extends GetxController {
  ApiResponse allCommentsResponse = ApiResponse.initial('Initial');
  ApiResponse addCommentsResponse = ApiResponse.initial('Initial');
  ApiResponse commentLikeUnlikeResponse = ApiResponse.initial('Initial');
  ApiResponse allVideoCommentsResponse = ApiResponse.initial('Initial');
  ApiResponse addVideoCommentsResponse = ApiResponse.initial('Initial');
  ApiResponse commentVideoLikeUnlikeResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> commentPostDeleteResponse =
      ApiResponse.initial('Initial').obs;
  TextEditingController sendMessageController = TextEditingController();
  final FocusNode replyFocusNode = FocusNode();
  RxList<CommentData> comments = <CommentData>[].obs;
  String? parentCommentId;
  Map<String, int> visibleRepliesCountMap = <String, int>{};
  RxBool isLoading = true.obs;
  RxnString replyingToUser = RxnString();
  RxInt totalCommentCount = 0.obs;

  // ValueNotifier<int> commentCount = ValueNotifier<int>(0);

  void toggleReplies(String commentId, int totalReplies) {
    final current = visibleRepliesCountMap[commentId] ?? 0;
    if (current == 0) {
      visibleRepliesCountMap[commentId] = totalReplies > 10 ? 10 : totalReplies;
    } else if (current < totalReplies) {
      final next =
          (current + 10) > totalReplies ? totalReplies : (current + 10);
      visibleRepliesCountMap[commentId] = next;
    } else {
      visibleRepliesCountMap[commentId] = 0; // collapse if all shown
    }
    update(['replies-$commentId']);
  }

  ///GET ALL Posts Comments...
  Future<void> getAllPostComments(
      {required String postId, bool isInitialized = false}) async {
    try {
      if (isInitialized) {
        isLoading.value = true;
      }

      final response = await CommentRepo().getAllComments(postId: postId);

      if (response.isSuccess) {
        allCommentsResponse = ApiResponse.complete(response);
        final commentModelResponse =
            CommentModelResponse.fromJson(response.response?.data);
        comments.value = commentModelResponse.data ?? [];
      } else {
        allCommentsResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      allCommentsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///Add Posts Comments...
  Future<void> addPostComment(
      {required Map<String, dynamic> params, required String postId}) async {
    try {
      final response = await CommentRepo().addComment(params: params);

      if (response.isSuccess) {
        addCommentsResponse = ApiResponse.complete(response);
        replyFocusNode.unfocus();
        sendMessageController.clear();
        totalCommentCount.value = totalCommentCount.value + 1;
        getAllPostComments(postId: postId);
      } else {
        addCommentsResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addCommentsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///Posts comment Like/Dislike...
  Future<void> addRemoveLike({required String commentId}) async {
    try {
      Map<String, dynamic> params = {ApiKeys.comment_id: commentId};
      final response = await CommentRepo().addRemoveLike(params: params);

      if (response.isSuccess) {
        commentLikeUnlikeResponse = ApiResponse.complete(response);
        // Try updating top-level comment
        final commentIndex = comments.indexWhere((c) => c.sId == commentId);
        if (commentIndex != -1) {
          final comment = comments[commentIndex];
          final isLiked = !(comment.isLiked ?? false);
          final updated = comment.copyWith(
            isLiked: isLiked,
            likesCount: isLiked
                ? (comment.likesCount ?? 0) + 1
                : (comment.likesCount ?? 0) - 1,
          );
          comments[commentIndex] = updated;
          return;
        }

        // If not found, search inside replies
        for (int i = 0; i < comments.length; i++) {
          final comment = comments[i];
          final replies = comment.replies ?? [];

          final replyIndex = replies.indexWhere((r) => r.sId == commentId);
          if (replyIndex != -1) {
            final reply = replies[replyIndex];
            final isLiked = !(reply.isLiked ?? false);
            final updatedReply = reply.copyWith(
              isLiked: isLiked,
              likesCount: isLiked
                  ? (reply.likesCount ?? 0) + 1
                  : (reply.likesCount ?? 0) - 1,
            );

            replies[replyIndex] = updatedReply;
            comments[i] = comment.copyWith(replies: replies);
            return;
          }
        }
      } else {
        commentLikeUnlikeResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commentLikeUnlikeResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///GET ALL Video Comments...
  Future<void> getAllVideoComments(
      {required String videoId, bool isInitialized = false}) async {
    try {
      if (isInitialized) {
        isLoading.value = true;
      }

      final response =
          await CommentRepo().getAllVideoComments(videoId: videoId);

      if (response.isSuccess) {
        allVideoCommentsResponse = ApiResponse.complete(response);
        final commentModelResponse =
            CommentModelResponse.fromJson(response.response?.data);
        comments.value = commentModelResponse.data ?? [];
      } else {
        allVideoCommentsResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      allVideoCommentsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///Add Video Comments...
  Future<void> addVideoComment(
      {required Map<String, dynamic> params, required String videoId}) async {
    try {
      final response = await CommentRepo().addVideoComment(params: params);

      if (response.isSuccess) {
        addCommentsResponse = ApiResponse.complete(response);
        replyFocusNode.unfocus();
        sendMessageController.clear();
        totalCommentCount.value = totalCommentCount.value + 1;
        getAllVideoComments(videoId: videoId);
      } else {
        addCommentsResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addCommentsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///Video comment Like/Dislike...
  Future<void> addRemoveLikeFromVideo({required String commentId}) async {
    try {
      Map<String, dynamic> params = {ApiKeys.commentId: commentId};
      final response = await CommentRepo()
          .addRemoveLikeFromVideo(params: params, commentId: commentId);

      if (response.isSuccess) {
        commentVideoLikeUnlikeResponse = ApiResponse.complete(response);
        // Try updating top-level comment
        final commentIndex = comments.indexWhere((c) => c.sId == commentId);
        if (commentIndex != -1) {
          final comment = comments[commentIndex];
          final isLiked = !(comment.isLiked ?? false);
          final updated = comment.copyWith(
            isLiked: isLiked,
            likesCount: isLiked
                ? (comment.likesCount ?? 0) + 1
                : (comment.likesCount ?? 0) - 1,
          );
          comments[commentIndex] = updated;
          return;
        }

        // If not found, search inside replies
        for (int i = 0; i < comments.length; i++) {
          final comment = comments[i];
          final replies = comment.replies ?? [];

          final replyIndex = replies.indexWhere((r) => r.sId == commentId);
          if (replyIndex != -1) {
            final reply = replies[replyIndex];
            final isLiked = !(reply.isLiked ?? false);
            final updatedReply = reply.copyWith(
              isLiked: isLiked,
              likesCount: isLiked
                  ? (reply.likesCount ?? 0) + 1
                  : (reply.likesCount ?? 0) - 1,
            );

            replies[replyIndex] = updatedReply;
            comments[i] = comment.copyWith(replies: replies);
            return;
          }
        }
      } else {
        commentVideoLikeUnlikeResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commentVideoLikeUnlikeResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///DELETE COMMENT POST CONTROLLER....
  Future<void> commentPostDeleteController(
      {required String commentId,
      required String postID,
      required CommentType commentPostType}) async {
    try {
      var response;
      if (commentPostType == CommentType.video) {
        response = await CommentRepo().deleteVideoPostComment(
          commentID: commentId,
        );
      }
      if (commentPostType == CommentType.post) {
        response = await CommentRepo().deletePostComment(
          commentID: commentId,
        );
      }

      if (response.isSuccess) {

        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        if (commentPostType == CommentType.video) {
          getAllVideoComments(videoId: postID);

        }
        if (commentPostType == CommentType.post) {
          getAllPostComments(postId: postID);

        }

        commentPostDeleteResponse.value = ApiResponse.complete(response);
        totalCommentCount.value = totalCommentCount.value - 1;

        // If not found, search inside replies
      } else {
        commentPostDeleteResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commentPostDeleteResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}

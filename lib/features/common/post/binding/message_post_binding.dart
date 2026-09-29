import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:get/get.dart';

/// Scopes a [MessagePostController] to the route that starts a message post
/// flow: the create screen, the edit preview, or the repost screen. Screens
/// pushed on top reuse it; GetX deletes it when that route closes.
class MessagePostBinding extends Bindings {
  MessagePostBinding({this.editPost, this.postVia})
      : repostOf = null,
        _isRepost = false;

  /// A repost has no tagging, so no [TagUserController] (and its user list
  /// request) is registered for it.
  MessagePostBinding.repost(this.repostOf, {this.postVia})
      : editPost = null,
        _isRepost = true;

  final Post? editPost;
  final Post? repostOf;
  final PostVia? postVia;
  final bool _isRepost;

  @override
  void dependencies() {
    if (!_isRepost) {
      Get.lazyPut(() => TagUserController(
          initialTaggedIds: [
            for (final user in editPost?.taggedUsers ?? const [])
              if (user.id != null) user.id!,
          ]));
    }
    Get.lazyPut(() => MessagePostController(
        repo: PostRepo(),
        tagUsers: _isRepost ? null : Get.find<TagUserController>(),
        editPost: editPost,
        repostOf: repostOf,
        postVia: postVia));
  }
}

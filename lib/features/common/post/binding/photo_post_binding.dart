import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:get/get.dart';

/// Scopes the photo post controllers to the PhotoPostScreen route. The
/// preview, review and tagging screens pushed on top reuse them; GetX deletes
/// them when that route closes.
class PhotoPostBinding extends Bindings {
  PhotoPostBinding({this.editPost, this.postVia});

  final Post? editPost;
  final PostVia? postVia;

  @override
  void dependencies() {
    Get.lazyPut(() => TagUserController(
        initialTaggedIds: [
          for (final user in editPost?.taggedUsers ?? const [])
            if (user.id != null) user.id!,
        ]));
    Get.lazyPut(() => PhotoPostController(
        repo: PostRepo(),
        tagUsers: Get.find<TagUserController>(),
        editPost: editPost,
        postVia: postVia));
  }
}

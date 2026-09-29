import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:get/get.dart';

/// Scopes a [PollController] to the poll input route. PollReviewScreen,
/// pushed on top, reuses it; GetX deletes it when the input route closes.
class PollBinding extends Bindings {
  PollBinding({this.editPost, this.postVia});

  final Post? editPost;
  final PostVia? postVia;

  @override
  void dependencies() {
    Get.lazyPut(() =>
        PollController(repo: PostRepo(), editPost: editPost, postVia: postVia));
  }
}

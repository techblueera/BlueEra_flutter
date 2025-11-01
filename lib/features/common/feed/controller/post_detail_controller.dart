import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/feed/controller/post_idresponse.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:get/get.dart';

class PostDetailController extends GetxController {
  String? postId;
  Post? post;

  @override
  void onInit() {
    args();
    super.onInit();
  }

  // void args() {
  //   var data = Get.arguments as Map<String, dynamic>;
  //   postId = data["postId"];
  //   postByID(id: postId!);
  // }
  void args() {
    final args = Get.arguments;

    if (args != null && args is Map<String, dynamic>) {
      postId = args["postId"];
    } else {
      // 🧭 handle deep link / external navigation
      postId = Get.parameters["postId"] ?? '';
      // or extract from your deep link handler if using it
    }

    if (postId != null && postId!.isNotEmpty) {
      postByID(id: postId!);
    } else {
      print("⚠️ No postId found in navigation arguments or parameters");
    }
  }


  Future<void> postByID({required String id}) async {
    ResponseModel response = await PostRepo().postByIDApi(id: id);
    if (response.isSuccess) {
      PostByIdResponseModalClass postByIdResponseModalClass =
      PostByIdResponseModalClass.fromJson(response.response?.data);
      post = postByIdResponseModalClass.data;
      update();
    }
  }

  /// 🔹 Toggle like/dislike
  Future<void> onLikeDislikePressed() async {
    if (post == null) return;

    // Instant UI update
    final bool oldValue = post!.isLiked ?? false;
    post?.isLiked = !oldValue;
    post!.likesCount = (post!.likesCount ?? 0) + (post!.isLiked! ? 1 : -1);
    update();

    // API call

    // final response = await PostRepo().likeDislikeApi(postId: postId!);
    final response = await FeedRepo().likePost(
      postId: postId??"",
    );
    if (!response.isSuccess) {
      // Revert on failure
      post!.isLiked = oldValue;
      post!.likesCount = (post!.likesCount ?? 0) + (oldValue ? 1 : -1);
      update();
    }
  }
}

// class PostDetailController extends GetxController {
//   String? postId;
//   Post? post;
//
//   @override
//   void onInit() {
//     args();
//     super.onInit();
//   }
//
//   void args() {
//     var data = Get.arguments as Map<String, dynamic>;
//     postId = data["postId"];
//     postByID(id: postId!);
//     update();
//   }
//
//   Future<void> postByID({required String id}) async {
//     ResponseModel response = await PostRepo().postByIDApi(id: id);
//     if (response.isSuccess) {
//       PostByIdResponseModalClass postByIdResponseModalClass = PostByIdResponseModalClass.fromJson(response.response?.data);
//       post = postByIdResponseModalClass.data;
//       update();
//     }
//   }
// }

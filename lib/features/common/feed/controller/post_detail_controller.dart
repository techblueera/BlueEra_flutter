import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/feed/controller/post_idresponse.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
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

  void args() {
    var data = Get.arguments as Map<String, dynamic>;
    postId = data["postId"];
    postByID(id: postId!);
    update();
  }

  Future<void> postByID({required String id}) async {
    ResponseModel response = await PostRepo().postByIDApi(id: id);
    if (response.isSuccess) {
      PostByIdResponseModalClass postByIdResponseModalClass = PostByIdResponseModalClass.fromJson(response.response?.data);
      post = postByIdResponseModalClass.data;
      update();
    }
  }
}

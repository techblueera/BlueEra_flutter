import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/feed/controller/post_idresponse.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:get/get.dart';

class PostDetailController extends GetxController {
  String? postId;
  PostByIdResponseModalClass? postByIdResponseModalClass;
  bool isLoading = false;

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
    try {
      isLoading = true;
      ResponseModel response = await PostRepo().postByIDApi(id: id);
      logs("response==== ${response.response}");
      logs("response==== ${response.response?.data}");
      if (response.isSuccess) {
        postByIdResponseModalClass =
            PostByIdResponseModalClass.fromJson(response.response?.data);
      }
      isLoading = false;
      update();
    } catch (e) {
      isLoading = false;
      update();
    }
  }
}

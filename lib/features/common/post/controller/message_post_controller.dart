import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagePostController extends GetxController {
  /// ADD MSG POST
  Rx<ApiResponse> addPostMessage = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> editPostMessage = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deletePostMessage = ApiResponse.initial('Initial').obs;
  RxString selectedBgImage = ''.obs, selectedFontFamily = ''.obs,uploadMsgPostUrl="".obs;
  RxBool isLoading = false.obs;

  Rx<Color> selectedColor = Colors.white.obs;
  Rx<Color> selectedBgColor = Colors.white.obs;
  RxString postText = ''.obs;
  RxString messageText = ''.obs;
  RxString messageTitle = ''.obs;
  RxBool isAddLink = false.obs;
  RxBool isAddTitle = false.obs;

  final List<Map<String, String>> fontStyles = [
    {'name': 'Style', 'family': 'OpenSans'},
    {'name': 'Style', 'family': 'Arizonia'},
    {'name': 'Style', 'family': 'Artifika'},
    {'name': 'Style', 'family': 'AsapCondensed'},
  ];
  final postTitleController = TextEditingController().obs;
  final postTextDataController = TextEditingController().obs;
  final descriptionMessage = TextEditingController().obs;
  final natureOfPostController = TextEditingController().obs;
  final referenceLinkController = TextEditingController().obs;
  bool isMsgPostEdit = false;
  RxBool isCursorHide = true.obs;
  String? postId;

  ///ADD MESSAGE POST...
  Future<void> addMsgPostController(
      {required Map<String, dynamic>? bodyReq}) async {

    try {
      ResponseModel responseModel = isMsgPostEdit
          ? await PostRepo()
              .updatePostRepo(postId: postId ,bodyReq: bodyReq, isMultiPartPost: true,)
          : await PostRepo()
              .addPostRepo(bodyReq: bodyReq, isMultiPartPost: true);
      final data = responseModel.response?.data;
      clearData();
      if (responseModel.isSuccess) {
        commonSnackBar(message: data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value = true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        addPostMessage.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      addPostMessage.value = ApiResponse.error('error');
    }
  }

  clearData() {
    postTextDataController.value.clear();
    descriptionMessage.value.clear();
    referenceLinkController.value.clear();
    messageText.value = "";
    postText.value = "";
    selectedFontFamily.value = "";
    selectedBgImage.value = "";
    selectedColor.value = Colors.white;
    selectedBgColor.value = Colors.white;
    isAddLink.value = false;
    Get.find<TagUserController>().clearAllSelections();
    Get.find<TagUserController>().selectedUsers.clear();
  }

  void changeFontFamily(String family) {
    selectedFontFamily.value = family;
  }
}

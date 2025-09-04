import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PollController extends GetxController {
  final questionController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController referenceLinkController = TextEditingController();

  final RxList<TextEditingController> optionControllers =
      <TextEditingController>[].obs;
  RxList<String> options = <String>[].obs;
  RxBool isAddLink = false.obs;
  RxBool isLoading = false.obs;
  Rx<ApiResponse> postPollResponse = ApiResponse.initial('Initial').obs;
  bool isPollPostEdit = false;
  String? postId;

  Future createPollPost(Map<String, dynamic> params) async {
    try {
      ResponseModel response = isPollPostEdit
          ? await PostRepo().updatePostRepo(
              postId: postId, bodyReq: params, isMultiPartPost: true)
          : await PostRepo()
              .addPostRepo(bodyReq: params, isMultiPartPost: false);
      if (response.isSuccess) {
        commonSnackBar(
          message:
              response.response?.data?['message'] ?? "Poll posted successfully",
        );
        postPollResponse.value = ApiResponse.complete(response);
        clearData();
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        postPollResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: response.response?.data?['message'] ??
                AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      postPollResponse.value = ApiResponse.error('error');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // addOption();
    // addOption();
  }

  /// Add a new option controller
  void addOption() {
    if (optionControllers.length < 4) {
      optionControllers.add(TextEditingController());
    }
  }

  /// Remove an option controller at index
  void removeOption(int index) {
    if (optionControllers.length > 2) {
      optionControllers[index].dispose();
      optionControllers.removeAt(index);
    }
  }

  void syncOptionsFromControllers() {
    options.value = optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  ///CLEAR ALL REQ DATA
  clearData() {
    postPollResponse = ApiResponse.initial('Initial').obs;
    questionController.clear();
    descriptionController.clear();
    referenceLinkController.clear();
    optionControllers.clear();
    options.clear();
    isAddLink.value = false;
    addOption();
    addOption();
  }
}
